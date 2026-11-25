import request from 'supertest';
import mongoose from 'mongoose';
import { createApp } from '../src/app';
import { Medication } from '../src/models/medication.model';
import { IntakeEvent } from '../src/models/intake_event.model';
import { MedicationService } from '../src/services/medication.service';
import { AuthService } from '../src/services/auth.service';

describe('Medication & Intake Limit Engine Tests', () => {
  const app = createApp();
  const userId = new mongoose.Types.ObjectId().toString();
  const token = AuthService.generateToken({
    userId,
    role: 'user',
    email: 'patient@example.com'
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Intake Limit Calculation Logic (Sections 17 & 18)', () => {
    const medId = new mongoose.Types.ObjectId();
    const mockMedication = new Medication({
      _id: medId,
      userId: new mongoose.Types.ObjectId(userId),
      medicineName: 'Amoxicillin 500mg',
      dosage: '1 capsule',
      frequency: 'twice_daily',
      prescribedLimit: 2, // Ceiling is 2 per day
      startDate: new Date(),
      active: true
    });

    it('should return WITHIN_LIMIT when today intake is below prescribed limit', async () => {
      jest.spyOn(Medication, 'findOne').mockResolvedValueOnce(mockMedication as any);
      jest.spyOn(IntakeEvent.prototype, 'save').mockResolvedValueOnce({} as any);

      // Only 1 event today
      jest.spyOn(IntakeEvent, 'find').mockResolvedValueOnce([
        { quantity: 1, takenAt: new Date() }
      ] as any);

      const result = await MedicationService.logIntake(userId, medId.toString(), {
        quantity: 1,
        source: 'manual'
      });

      expect(result.status).toBe('WITHIN_LIMIT');
      expect(result.dailyIntake).toBe(1);
      expect(result.prescribedLimit).toBe(2);
      expect(result.message).not.toContain('safely take another'); // Safety rule 18
    });

    it('should return LIMIT_REACHED when today intake equals prescribed limit', async () => {
      jest.spyOn(Medication, 'findOne').mockResolvedValueOnce(mockMedication as any);
      jest.spyOn(IntakeEvent.prototype, 'save').mockResolvedValueOnce({} as any);

      // 2 events today (1 + 1 = 2)
      jest.spyOn(IntakeEvent, 'find').mockResolvedValueOnce([
        { quantity: 1, takenAt: new Date() },
        { quantity: 1, takenAt: new Date() }
      ] as any);

      const result = await MedicationService.logIntake(userId, medId.toString(), {
        quantity: 1,
        source: 'manual'
      });

      expect(result.status).toBe('LIMIT_REACHED');
      expect(result.dailyIntake).toBe(2);
      expect(result.prescribedLimit).toBe(2);
      expect(result.message).toContain('reached your configured prescribed limit');
    });

    it('should return LIMIT_EXCEEDED when today intake exceeds prescribed limit', async () => {
      jest.spyOn(Medication, 'findOne').mockResolvedValueOnce(mockMedication as any);
      jest.spyOn(IntakeEvent.prototype, 'save').mockResolvedValueOnce({} as any);

      // 3 events today (exceeds limit of 2)
      jest.spyOn(IntakeEvent, 'find').mockResolvedValueOnce([
        { quantity: 1, takenAt: new Date() },
        { quantity: 1, takenAt: new Date() },
        { quantity: 1, takenAt: new Date() }
      ] as any);

      const result = await MedicationService.logIntake(userId, medId.toString(), {
        quantity: 1,
        source: 'manual'
      });

      expect(result.status).toBe('LIMIT_EXCEEDED');
      expect(result.dailyIntake).toBe(3);
      expect(result.prescribedLimit).toBe(2);
      expect(result.message).toContain('exceeds your configured prescribed limit');
    });
  });

  describe('API Endpoints (Supertest)', () => {
    it('POST /api/medications should require authentication (401 without token)', async () => {
      const res = await request(app)
        .post('/api/medications')
        .send({
          medicineName: 'Paracetamol',
          dosage: '1 tablet',
          frequency: 'daily',
          prescribedLimit: 3
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('POST /api/medications should reject prescribedLimit < 1 with 400', async () => {
      const res = await request(app)
        .post('/api/medications')
        .set('Authorization', `Bearer ${token}`)
        .send({
          medicineName: 'Paracetamol',
          dosage: '1 tablet',
          frequency: 'daily',
          prescribedLimit: 0 // Invalid ceiling
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Validation failed');
    });

    it('POST /api/medications should create medication successfully with 201', async () => {
      const mockSaved = new Medication({
        _id: new mongoose.Types.ObjectId(),
        userId: new mongoose.Types.ObjectId(userId),
        medicineName: 'Metformin 850mg',
        dosage: '1 tablet',
        frequency: 'twice_daily',
        prescribedLimit: 2,
        startDate: new Date(),
        active: true
      });

      jest.spyOn(Medication.prototype, 'save').mockResolvedValueOnce(mockSaved as any);

      const res = await request(app)
        .post('/api/medications')
        .set('Authorization', `Bearer ${token}`)
        .send({
          medicineName: 'Metformin 850mg',
          dosage: '1 tablet',
          frequency: 'twice_daily',
          prescribedLimit: 2,
          times: ['09:00', '21:00']
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.medication).toBeDefined();
      expect(res.body.medication.medicineName).toBe('Metformin 850mg');
    });

    it('GET /api/medications should return list of user medications', async () => {
      const mockList = [
        new Medication({
          _id: new mongoose.Types.ObjectId(),
          userId: new mongoose.Types.ObjectId(userId),
          medicineName: 'Amoxicillin',
          dosage: '1 capsule',
          frequency: 'daily',
          prescribedLimit: 3
        })
      ];

      jest.spyOn(Medication, 'find').mockReturnValue({
        sort: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(mockList)
        })
      } as any);

      const res = await request(app)
        .get('/api/medications')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.count).toBe(1);
    });

    it('POST /api/medications/:id/intake should log intake and evaluate limit', async () => {
      const medId = new mongoose.Types.ObjectId();
      const mockMedication = new Medication({
        _id: medId,
        userId: new mongoose.Types.ObjectId(userId),
        medicineName: 'Cetirizine',
        dosage: '1 tablet',
        frequency: 'daily',
        prescribedLimit: 1
      });

      jest.spyOn(Medication, 'findOne').mockResolvedValueOnce(mockMedication as any);
      jest.spyOn(IntakeEvent.prototype, 'save').mockResolvedValueOnce({} as any);

      // First dose today -> LIMIT_REACHED because limit is 1
      jest.spyOn(IntakeEvent, 'find').mockResolvedValueOnce([
        { quantity: 1, takenAt: new Date() }
      ] as any);

      const res = await request(app)
        .post(`/api/medications/${medId.toString()}/intake`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          quantity: 1,
          source: 'manual'
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('LIMIT_REACHED');
      expect(res.body.data.dailyIntake).toBe(1);
    });

    it('GET /api/intake/today should return summary of daily intake for user', async () => {
      const medId = new mongoose.Types.ObjectId();
      const mockMedication = new Medication({
        _id: medId,
        userId: new mongoose.Types.ObjectId(userId),
        medicineName: 'Amoxicillin',
        dosage: '1 capsule',
        prescribedLimit: 3
      });

      jest.spyOn(Medication, 'find').mockReturnValue({
        sort: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue([mockMedication])
        })
      } as any);

      jest.spyOn(IntakeEvent, 'find').mockResolvedValueOnce([
        {
          medicationId: medId,
          quantity: 2,
          takenAt: new Date()
        }
      ] as any);

      const res = await request(app)
        .get('/api/intake/today')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.summary).toBeDefined();
      expect(res.body.summary[0].dailyIntake).toBe(2);
      expect(res.body.summary[0].status).toBe('WITHIN_LIMIT');
    });
  });
});
