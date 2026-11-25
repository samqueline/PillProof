import request from 'supertest';
import { createApp } from '../src/app';
import { getSqliteDb } from '../src/database';

describe('SQLite Medicines & GS1 QR Verification Tests', () => {
  const app = createApp();

  beforeAll(() => {
    // Ensure demo medicines exist in SQLite
    const db = getSqliteDb();
    db.prepare(`
      INSERT OR REPLACE INTO medicines (gtin, name, manufacturer, composition)
      VALUES ('08901234567890', 'Amoxicillin 500mg Trihydrate Capsules', 'Sun Pharmaceutical Industries Ltd', 'Amoxicillin Trihydrate IP 500mg')
    `).run();

    db.prepare(`
      INSERT OR REPLACE INTO batch_records (gtin, batch_number, expiry_date, qr_payload)
      VALUES ('08901234567890', 'B2045', '2027-12-31', '(01)08901234567890(10)B2045(17)271231')
    `).run();
  });

  it('GET /api/medicines/search should find medicine by name', async () => {
    const res = await request(app).get('/api/medicines/search?q=Amoxicillin');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.count).toBeGreaterThan(0);
    expect(res.body.medicines[0].name).toContain('Amoxicillin');
  });

  it('GET /api/medicines/search should find medicine by composition', async () => {
    const res = await request(app).get('/api/medicines/search?q=Trihydrate');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.medicines.length).toBeGreaterThan(0);
  });

  it('POST /api/verify should verify standard GS1 QR payload', async () => {
    const res = await request(app)
      .post('/api/verify')
      .send({ payload: '(01)08901234567890(10)B2045(17)271231' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.status).toBe('VERIFIED');
    expect(res.body.data.medicine.name).toBe('Amoxicillin 500mg Trihydrate Capsules');
    expect(res.body.data.batch.batchNumber).toBe('B2045');
    expect(res.body.data.batch.isGenuine).toBe(true);
  });

  it('POST /api/verify should detect expired medicine date in payload', async () => {
    const res = await request(app)
      .post('/api/verify')
      .send({ payload: '(01)08901234567890(10)B2045(17)200101' });

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('EXPIRED');
  });

  it('POST /api/verify should return 404 for unknown GTIN', async () => {
    const res = await request(app)
      .post('/api/verify')
      .send({ payload: '(01)99999999999999(10)FAKE123(17)280101' });

    expect(res.status).toBe(404);
    expect(res.body.status).toBe('NO_MATCH');
  });
});

