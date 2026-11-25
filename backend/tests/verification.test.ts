import request from 'supertest';
import mongoose from 'mongoose';
import { createApp } from '../src/app';
import { VerificationService } from '../src/services/verification.service';
import { Medicine } from '../src/models/medicine.model';
import { VerificationLog } from '../src/models/verification_log.model';

describe('Medicine Verification Engine Tests', () => {
  const app = createApp();

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Verification Algorithm (Levels 1, 2, 3 & Expiry)', () => {
    const validFutureDate = new Date();
    validFutureDate.setFullYear(validFutureDate.getFullYear() + 2);

    const expiredPastDate = new Date();
    expiredPastDate.setFullYear(expiredPastDate.getFullYear() - 1);

    it('Level 1: should return VERIFIED on exact barcode match', async () => {
      const mockMedicine = new Medicine({
        name: 'Amoxicillin 500mg',
        genericName: 'Amoxicillin',
        manufacturer: 'GSK',
        batchNumber: 'AMX-2026-X1',
        barcode: '8901234567890',
        expiryDate: validFutureDate,
        strength: '500 mg',
        dosageForm: 'Capsule',
        status: 'verified'
      });

      jest.spyOn(Medicine, 'findOne').mockResolvedValueOnce(mockMedicine as any);
      jest.spyOn(VerificationLog.prototype, 'save').mockResolvedValueOnce({} as any);

      const result = await VerificationService.verifyMedicine({
        barcode: '8901234567890'
      });

      expect(result.status).toBe('VERIFIED');
      expect(result.message).toContain('match a verified Pill Proof record');
      expect(result.matchedMedicine).toBeDefined();
    });

    it('Level 2: should return VERIFIED on exact name + batch number combination', async () => {
      const mockMedicine = new Medicine({
        name: 'Metformin 850mg',
        genericName: 'Metformin',
        manufacturer: 'Merck',
        batchNumber: 'MET-850-B2',
        barcode: '8901234567891',
        expiryDate: validFutureDate,
        strength: '850 mg',
        dosageForm: 'Tablet',
        status: 'verified'
      });

      // Barcode lookup fails, Level 2 query succeeds
      jest.spyOn(Medicine, 'findOne').mockResolvedValueOnce(mockMedicine as any);
      jest.spyOn(VerificationLog.prototype, 'save').mockResolvedValueOnce({} as any);

      const result = await VerificationService.verifyMedicine({
        name: 'Metformin 850mg',
        batchNumber: 'MET-850-B2',
        manufacturer: 'Merck'
      });

      expect(result.status).toBe('VERIFIED');
      expect(result.matchedMedicine?.['batchNumber']).toBe('MET-850-B2');
    });

    it('Level 3: should return REVIEW for partial matches to prevent false positives', async () => {
      const mockMedicine = new Medicine({
        name: 'Paracetamol 650mg Extra',
        genericName: 'Paracetamol',
        manufacturer: 'Micro Labs',
        batchNumber: 'DOLO-999',
        barcode: '8901234567899',
        expiryDate: validFutureDate,
        strength: '650 mg',
        dosageForm: 'Tablet',
        status: 'verified'
      });

      // Barcode & exact combination fail, partial search succeeds
      jest.spyOn(Medicine, 'findOne')
        .mockResolvedValueOnce(null) // Exact combination
        .mockResolvedValueOnce(mockMedicine as any); // Partial search
      jest.spyOn(VerificationLog.prototype, 'save').mockResolvedValueOnce({} as any);

      const result = await VerificationService.verifyMedicine({
        name: 'Paracetamol',
        batchNumber: 'UNKNOWN-BATCH'
      });

      expect(result.status).toBe('REVIEW');
      expect(result.message).toContain('Partial match found');
    });

    it('Expiry Check: should return EXPIRED if matched medicine has past expiry date', async () => {
      const mockMedicine = new Medicine({
        name: 'Ibuprofen 400mg',
        genericName: 'Ibuprofen',
        manufacturer: 'Abbott',
        batchNumber: 'IBU-OLD-99',
        barcode: '8901234567895',
        expiryDate: expiredPastDate,
        strength: '400 mg',
        dosageForm: 'Tablet',
        status: 'verified'
      });

      jest.spyOn(Medicine, 'findOne').mockResolvedValueOnce(mockMedicine as any);
      jest.spyOn(VerificationLog.prototype, 'save').mockResolvedValueOnce({} as any);

      const result = await VerificationService.verifyMedicine({
        barcode: '8901234567895'
      });

      expect(result.status).toBe('EXPIRED');
      expect(result.message).toContain('Medicine expired');
      expect(result.message).toContain('Do not consume expired medication');
    });

    it('Expiry Check: should return EXPIRED if user input expiry date is in the past', async () => {
      jest.spyOn(VerificationLog.prototype, 'save').mockResolvedValueOnce({} as any);

      const result = await VerificationService.verifyMedicine({
        name: 'Some Medicine',
        batchNumber: 'BATCH-123',
        expiryDate: '2023-01-01'
      });

      expect(result.status).toBe('EXPIRED');
      expect(result.message).toContain('The entered expiration date (2023-01-01) has passed');
    });

    it('No Match: should return NO_MATCH with exact required message', async () => {
      jest.spyOn(Medicine, 'findOne').mockResolvedValue(null);
      jest.spyOn(VerificationLog.prototype, 'save').mockResolvedValueOnce({} as any);

      const result = await VerificationService.verifyMedicine({
        barcode: '0000000000000'
      });

      expect(result.status).toBe('NO_MATCH');
      expect(result.message).toBe('No matching verified record was found.');
    });
  });

  describe('API Endpoints (Supertest)', () => {
    it('POST /api/medicines/verify should reject empty request body with 400', async () => {
      const res = await request(app)
        .post('/api/medicines/verify')
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('POST /api/medicines/verify should return 200 and verification result for valid barcode', async () => {
      const validFutureDate = new Date();
      validFutureDate.setFullYear(validFutureDate.getFullYear() + 2);

      const mockMedicine = new Medicine({
        name: 'Amoxicillin 500mg',
        genericName: 'Amoxicillin',
        manufacturer: 'GSK',
        batchNumber: 'AMX-2026-X1',
        barcode: '8901234567890',
        expiryDate: validFutureDate,
        strength: '500 mg',
        dosageForm: 'Capsule',
        status: 'verified'
      });

      jest.spyOn(Medicine, 'findOne').mockResolvedValueOnce(mockMedicine as any);
      jest.spyOn(VerificationLog.prototype, 'save').mockResolvedValueOnce({} as any);

      const res = await request(app)
        .post('/api/medicines/verify')
        .send({ barcode: '8901234567890' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('VERIFIED');
    });

    it('GET /api/medicines/search should validate query and return search results', async () => {
      const mockList = [
        new Medicine({
          name: 'Amoxicillin 500mg',
          genericName: 'Amoxicillin',
          manufacturer: 'GSK',
          batchNumber: 'AMX-2026-X1',
          barcode: '8901234567890',
          expiryDate: new Date(),
          strength: '500 mg',
          dosageForm: 'Capsule'
        })
      ];

      jest.spyOn(Medicine, 'find').mockReturnValue({
        limit: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(mockList)
        })
      } as any);

      const res = await request(app).get('/api/medicines/search?q=Amoxicillin');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.count).toBe(1);
    });

    it('GET /api/verification/history should require authentication (401 without token)', async () => {
      const res = await request(app).get('/api/verification/history');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('GET /api/verification/history should return 200 with logs for authenticated user', async () => {
      const { AuthService } = await import('../src/services/auth.service');
      const token = AuthService.generateToken({
        userId: new mongoose.Types.ObjectId().toString(),
        role: 'user',
        email: 'user@pillproof.com'
      });

      jest.spyOn(VerificationLog, 'find').mockReturnValue({
        populate: jest.fn().mockReturnValue({
          sort: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              exec: jest.fn().mockResolvedValue([
                {
                  _id: new mongoose.Types.ObjectId(),
                  medicineInput: { name: 'Amoxicillin 500mg', barcode: '8901234567890' },
                  result: 'verified',
                  createdAt: new Date()
                }
              ])
            })
          })
        })
      } as any);

      const res = await request(app)
        .get('/api/verification/history')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.count).toBe(1);
      expect(res.body.history).toBeDefined();
    });
  });
});
