import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import {
  User,
  Medicine,
  Medication,
  IntakeEvent,
  VerificationLog
} from '../src/models';

describe('MongoDB Models Validation Tests', () => {
  describe('User Model', () => {
    it('should validate a valid user model', async () => {
      const user = new User({
        name: 'Jane Doe',
        email: 'jane@example.com',
        passwordHash: await bcrypt.hash('SecurePass123!', 10),
        role: 'user'
      });

      const err = user.validateSync();
      expect(err).toBeUndefined();
      expect(user.role).toBe('user');
    });

    it('should fail validation if email is missing or invalid', () => {
      const userWithoutEmail = new User({
        name: 'Jane Doe',
        passwordHash: 'hashed_password'
      });
      const errMissing = userWithoutEmail.validateSync();
      expect(errMissing?.errors['email']).toBeDefined();

      const userWithBadEmail = new User({
        name: 'Jane Doe',
        email: 'invalid-email-format',
        passwordHash: 'hashed_password'
      });
      const errBadEmail = userWithBadEmail.validateSync();
      expect(errBadEmail?.errors['email']).toBeDefined();
    });

    it('should verify password hash and exclude passwordHash in toPublicJSON', async () => {
      const plainPassword = 'MySecretPassword123';
      const passwordHash = await bcrypt.hash(plainPassword, 10);

      const user = new User({
        name: 'Alice',
        email: 'alice@example.com',
        passwordHash
      });

      const isMatch = await user.comparePassword(plainPassword);
      const isMismatch = await user.comparePassword('WrongPassword');

      expect(isMatch).toBe(true);
      expect(isMismatch).toBe(false);

      const publicJson = user.toPublicJSON();
      expect(publicJson.passwordHash).toBeUndefined();
      expect(publicJson.email).toBe('alice@example.com');
    });
  });

  describe('Medicine Model', () => {
    it('should validate a valid medicine record', () => {
      const medicine = new Medicine({
        name: 'Amoxicillin 500mg',
        genericName: 'Amoxicillin',
        manufacturer: 'PharmaCorp',
        batchNumber: 'amx-2026-01',
        barcode: '8901234567890',
        expiryDate: new Date('2027-12-31'),
        strength: '500 mg',
        dosageForm: 'Capsule',
        status: 'verified'
      });

      const err = medicine.validateSync();
      expect(err).toBeUndefined();
      expect(medicine.batchNumber).toBe('AMX-2026-01'); // Uppercased automatically
      expect(medicine.status).toBe('verified');
      expect(medicine.source).toBe('Pill Proof Verified Dataset');
    });

    it('should require batchNumber and barcode', () => {
      const medicine = new Medicine({
        name: 'Metformin',
        genericName: 'Metformin HCl',
        manufacturer: 'PharmaCorp',
        expiryDate: new Date('2027-01-01'),
        strength: '850 mg',
        dosageForm: 'Tablet'
      });

      const err = medicine.validateSync();
      expect(err?.errors['batchNumber']).toBeDefined();
      expect(err?.errors['barcode']).toBeDefined();
    });
  });

  describe('Medication Model', () => {
    it('should validate a user-tracked medication with prescribed limit', () => {
      const medication = new Medication({
        userId: new mongoose.Types.ObjectId(),
        medicineName: 'Amoxicillin',
        dosage: '1 capsule',
        frequency: 'three_times_daily',
        times: ['08:00', '14:00', '20:00'],
        prescribedLimit: 3,
        startDate: new Date('2026-10-14')
      });

      const err = medication.validateSync();
      expect(err).toBeUndefined();
      expect(medication.active).toBe(true);
      expect(medication.prescribedLimit).toBe(3);
    });

    it('should reject prescribed limit less than 1', () => {
      const medication = new Medication({
        userId: new mongoose.Types.ObjectId(),
        medicineName: 'Amoxicillin',
        dosage: '1 capsule',
        frequency: 'daily',
        prescribedLimit: 0,
        startDate: new Date()
      });

      const err = medication.validateSync();
      expect(err?.errors['prescribedLimit']).toBeDefined();
    });
  });

  describe('IntakeEvent Model', () => {
    it('should validate an intake event with valid parameters', () => {
      const intake = new IntakeEvent({
        userId: new mongoose.Types.ObjectId(),
        medicationId: new mongoose.Types.ObjectId(),
        quantity: 1,
        scheduledTime: '08:00',
        source: 'manual'
      });

      const err = intake.validateSync();
      expect(err).toBeUndefined();
      expect(intake.quantity).toBe(1);
      expect(intake.source).toBe('manual');
      expect(intake.takenAt).toBeDefined();
    });

    it('should reject invalid intake source', () => {
      const intake = new IntakeEvent({
        userId: new mongoose.Types.ObjectId(),
        medicationId: new mongoose.Types.ObjectId(),
        quantity: 1,
        source: 'unknown_source' as any
      });

      const err = intake.validateSync();
      expect(err?.errors['source']).toBeDefined();
    });
  });

  describe('VerificationLog Model', () => {
    it('should validate a verification audit log entry', () => {
      const log = new VerificationLog({
        userId: new mongoose.Types.ObjectId(),
        medicineInput: {
          name: 'Amoxicillin',
          batchNumber: 'AMX-2026-01',
          barcode: '8901234567890'
        },
        result: 'verified',
        matchedMedicineId: new mongoose.Types.ObjectId()
      });

      const err = log.validateSync();
      expect(err).toBeUndefined();
      expect(log.result).toBe('verified');
      expect(log.createdAt).toBeDefined();
    });
  });
});
