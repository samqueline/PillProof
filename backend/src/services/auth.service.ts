import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { User, IUser } from '../models/user.model';
import { config } from '../config/env';
import { RegisterInput, LoginInput } from '../validators/auth.validator';
import { inMemoryStore } from './in_memory_store';

export interface AuthResponse {
  token: string;
  user: Record<string, unknown>;
}

export class AuthService {
  private static readonly SALT_ROUNDS = 10;

  /**
   * Hashes a plain-text password using bcrypt.
   */
  public static async hashPassword(password: string): Promise<string> {
    return await bcrypt.hash(password, this.SALT_ROUNDS);
  }

  /**
   * Compares a plain password against a bcrypt hash.
   */
  public static async verifyPassword(
    plain: string,
    hashed: string
  ): Promise<boolean> {
    return await bcrypt.compare(plain, hashed);
  }

  /**
   * Generates a signed JWT authentication token.
   */
  public static generateToken(payload: {
    userId: string;
    role: string;
    email: string;
  }): string {
    return jwt.sign(payload, config.jwtSecret, {
      expiresIn: config.jwtExpiresIn as jwt.SignOptions['expiresIn']
    });
  }

  /**
   * Verifies and decodes a JWT token.
   */
  public static verifyToken(token: string): { userId: string; role: string; email: string } {
    return jwt.verify(token, config.jwtSecret) as {
      userId: string;
      role: string;
      email: string;
    };
  }

  /**
   * Registers a new user, hashes password, saves to DB, returns JWT + public user profile.
   */
  public static async register(input: RegisterInput): Promise<AuthResponse> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      const existingUser = inMemoryStore.findUserByEmail(input.email);
      if (existingUser) {
        const error = new Error('An account with this email address already exists.');
        (error as any).statusCode = 409;
        throw error;
      }

      const passwordHash = await this.hashPassword(input.password);
      const id = new mongoose.Types.ObjectId();
      const user = {
        _id: id,
        name: input.name,
        email: input.email,
        passwordHash,
        role: (input.role || 'user') as any,
        createdAt: new Date(),
        updatedAt: new Date(),
        async comparePassword(candidate: string) {
          return await bcrypt.compare(candidate, passwordHash);
        },
        toPublicJSON() {
          return {
            id: id.toString(),
            name: input.name,
            email: input.email,
            role: input.role || 'user',
            createdAt: new Date().toISOString()
          };
        }
      };

      inMemoryStore.addUser(user);

      const token = this.generateToken({
        userId: id.toString(),
        role: user.role,
        email: user.email
      });

      return {
        token,
        user: user.toPublicJSON()
      };
    }

    const existingUser = await User.findOne({ email: input.email });
    if (existingUser) {
      const error = new Error('An account with this email address already exists.');
      (error as any).statusCode = 409;
      throw error;
    }

    const passwordHash = await this.hashPassword(input.password);

    const newUser = new User({
      name: input.name,
      email: input.email,
      passwordHash,
      role: input.role || 'user'
    });

    await newUser.save();

    const token = this.generateToken({
      userId: newUser._id.toString(),
      role: newUser.role,
      email: newUser.email
    });

    return {
      token,
      user: newUser.toPublicJSON()
    };
  }

  /**
   * Validates user credentials, returns JWT + public user profile.
   */
  public static async login(input: LoginInput): Promise<AuthResponse> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      const user = inMemoryStore.findUserByEmail(input.email);
      if (!user) {
        const error = new Error('Invalid email or password.');
        (error as any).statusCode = 401;
        throw error;
      }

      const isMatch = await user.comparePassword(input.password);
      if (!isMatch) {
        const error = new Error('Invalid email or password.');
        (error as any).statusCode = 401;
        throw error;
      }

      const token = this.generateToken({
        userId: user._id.toString(),
        role: user.role,
        email: user.email
      });

      return {
        token,
        user: user.toPublicJSON()
      };
    }

    const user = await User.findOne({ email: input.email });
    if (!user) {
      const error = new Error('Invalid email or password.');
      (error as any).statusCode = 401;
      throw error;
    }

    const isMatch = await user.comparePassword(input.password);
    if (!isMatch) {
      const error = new Error('Invalid email or password.');
      (error as any).statusCode = 401;
      throw error;
    }

    const token = this.generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email
    });

    return {
      token,
      user: user.toPublicJSON()
    };
  }

  /**
   * Retrieves user profile by userId without passwordHash.
   */
  public static async getProfile(userId: string): Promise<Record<string, unknown>> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      const user = inMemoryStore.findUserById(userId);
      if (!user) {
        const error = new Error('User account not found.');
        (error as any).statusCode = 404;
        throw error;
      }
      return user.toPublicJSON();
    }

    const user = await User.findById(userId);
    if (!user) {
      const error = new Error('User account not found.');
      (error as any).statusCode = 404;
      throw error;
    }

    return user.toPublicJSON();
  }
}
