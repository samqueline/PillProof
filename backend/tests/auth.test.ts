import request from 'supertest';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import { createApp } from '../src/app';
import { AuthService } from '../src/services/auth.service';
import { registerSchema, loginSchema } from '../src/validators/auth.validator';
import { User } from '../src/models/user.model';

describe('Authentication & Security Tests', () => {
  const app = createApp();

  describe('Password Hashing & JWT Unit Tests', () => {
    it('should securely hash passwords with bcrypt salt', async () => {
      const password = 'StrongPassword123!';
      const hash = await AuthService.hashPassword(password);

      expect(hash).not.toBe(password);
      expect(hash.startsWith('$2')).toBe(true);

      const isValid = await AuthService.verifyPassword(password, hash);
      const isInvalid = await AuthService.verifyPassword('WrongPassword123', hash);

      expect(isValid).toBe(true);
      expect(isInvalid).toBe(false);
    });

    it('should generate and verify valid JWT tokens', () => {
      const payload = {
        userId: new mongoose.Types.ObjectId().toString(),
        role: 'user',
        email: 'test@pillproof.com'
      };

      const token = AuthService.generateToken(payload);
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3); // Header.Payload.Signature

      const decoded = AuthService.verifyToken(token);
      expect(decoded.userId).toBe(payload.userId);
      expect(decoded.role).toBe(payload.role);
      expect(decoded.email).toBe(payload.email);
    });

    it('should reject tampered or invalid tokens', () => {
      expect(() => {
        AuthService.verifyToken('invalid.token.structure');
      }).toThrow();
    });
  });

  describe('Validation Schemas', () => {
    it('should reject passwords shorter than 8 characters', () => {
      const result = registerSchema.safeParse({
        name: 'John',
        email: 'john@example.com',
        password: 'pass1'
      });
      expect(result.success).toBe(false);
    });

    it('should reject passwords without numbers', () => {
      const result = registerSchema.safeParse({
        name: 'John',
        email: 'john@example.com',
        password: 'PasswordOnly'
      });
      expect(result.success).toBe(false);
    });

    it('should accept strong passwords and format emails', () => {
      const result = registerSchema.safeParse({
        name: 'John Doe',
        email: '  JOHN@EXAMPLE.COM ',
        password: 'StrongPassword123'
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.email).toBe('john@example.com');
      }
    });

    it('should reject empty login passwords', () => {
      const result = loginSchema.safeParse({
        email: 'john@example.com',
        password: ''
      });
      expect(result.success).toBe(false);
    });
  });

  describe('API Endpoints (Supertest)', () => {
    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('POST /api/auth/register should fail with 400 for invalid inputs', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'J',
          email: 'not-an-email',
          password: '123'
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.errors).toBeDefined();
    });

    it('POST /api/auth/register should return 409 if email already exists', async () => {
      jest.spyOn(User, 'findOne').mockResolvedValueOnce({
        _id: new mongoose.Types.ObjectId(),
        email: 'existing@example.com'
      } as any);

      const res = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Jane Doe',
          email: 'existing@example.com',
          password: 'Password123'
        });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('already exists');
    });

    it('POST /api/auth/register should register user, hash password, and return token', async () => {
      jest.spyOn(User, 'findOne').mockResolvedValueOnce(null);
      const fakeId = new mongoose.Types.ObjectId();

      jest.spyOn(User.prototype, 'save').mockImplementationOnce(async function (this: any) {
        this._id = fakeId;
        return this;
      });

      const res = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'New User',
          email: 'newuser@example.com',
          password: 'Password123'
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
      expect(res.body.user).toBeDefined();
      expect(res.body.user.passwordHash).toBeUndefined(); // Never expose password hash!
      expect(res.body.user.email).toBe('newuser@example.com');
    });

    it('POST /api/auth/login should return 401 for wrong credentials', async () => {
      jest.spyOn(User, 'findOne').mockResolvedValueOnce(null);

      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'Password123'
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid email or password.');
    });

    it('POST /api/auth/login should return 200 and token for valid credentials', async () => {
      const mockPasswordHash = await bcrypt.hash('CorrectPassword123', 10);
      const fakeId = new mongoose.Types.ObjectId();

      const mockUser = new User({
        name: 'Login User',
        email: 'login@example.com',
        passwordHash: mockPasswordHash,
        role: 'user'
      });
      (mockUser as any)._id = fakeId;

      jest.spyOn(User, 'findOne').mockResolvedValueOnce(mockUser as any);

      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'login@example.com',
          password: 'CorrectPassword123'
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
      expect(res.body.user.passwordHash).toBeUndefined();
    });

    it('GET /api/auth/me should reject unauthenticated requests with 401', async () => {
      const res = await request(app).get('/api/auth/me');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('GET /api/auth/me should return user profile with valid Bearer token', async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const token = AuthService.generateToken({
        userId: fakeId.toString(),
        role: 'user',
        email: 'profile@example.com'
      });

      const mockUser = new User({
        name: 'Profile User',
        email: 'profile@example.com',
        passwordHash: 'hashed',
        role: 'user'
      });
      (mockUser as any)._id = fakeId;

      jest.spyOn(User, 'findById').mockResolvedValueOnce(mockUser as any);

      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.user.email).toBe('profile@example.com');
      expect(res.body.user.passwordHash).toBeUndefined();
    });
  });
});
