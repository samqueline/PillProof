import { Router, Request, Response } from 'express';
import mongoose from 'mongoose';

const router = Router();

router.get('/', (_req: Request, res: Response) => {
  const dbStatusMap: Record<number, string> = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting'
  };

  res.status(200).json({
    success: true,
    message: 'Pill Proof API is operational',
    timestamp: new Date().toISOString(),
    service: 'pill-proof-backend',
    database: dbStatusMap[mongoose.connection.readyState] || 'unknown'
  });
});

export default router;
