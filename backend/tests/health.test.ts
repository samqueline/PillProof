import request from 'supertest';
import { createApp } from '../src/app';

describe('Health API Endpoint', () => {
  const app = createApp();

  it('GET /api/health should return 200 with operational status', async () => {
    const res = await request(app).get('/api/health');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe('Pill Proof API is operational');
    expect(res.body.service).toBe('pill-proof-backend');
    expect(res.body.timestamp).toBeDefined();
    expect(res.body.database).toBeDefined();
  });

  it('GET /api/nonexistent should return 404', async () => {
    const res = await request(app).get('/api/nonexistent');

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });
});
