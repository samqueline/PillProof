import request from 'supertest';
import { createApp } from '../src/app';

describe('AI Medicine Advisor Chatbot Tests', () => {
  const app = createApp();

  it('should reject empty message with 400', async () => {
    const res = await request(app).post('/api/ai/chat').send({ message: '' });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should answer queries about Amoxicillin uses and dosage', async () => {
    const res = await request(app)
      .post('/api/ai/chat')
      .send({ message: 'What is Amoxicillin used for and typical dosage?' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.reply).toBeDefined();
    expect(res.body.reply.toLowerCase()).toContain('amoxicillin');
    expect(res.body.reply.toLowerCase()).toContain('dosage');
    expect(res.body.disclaimer).toBeDefined();
  });

  it('should answer queries about Paracetamol and liver safety', async () => {
    const res = await request(app)
      .post('/api/ai/chat')
      .send({ message: 'What is Paracetamol 650mg used for and max daily limit?' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.reply.toLowerCase()).toContain('paracetamol');
    expect(res.body.reply).toContain('4,000 mg');
  });

  it('should provide general dosage guidance when asking generic questions', async () => {
    const res = await request(app)
      .post('/api/ai/chat')
      .send({ message: 'How do I know my recommended dosage?' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.reply).toContain('Medication Dosage Guidance');
  });
});
