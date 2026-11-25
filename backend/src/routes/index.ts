import { Router } from 'express';
import healthRoutes from './health.routes';
import authRoutes from './auth.routes';
import medicineRoutes from './medicine.routes';
import medicationRoutes from './medication.routes';
import intakeRoutes from './intake.routes';
import verificationRoutes from './verification.routes';
import aiRoutes from './ai.routes';
import { SqliteVerifyController } from '../controllers/sqlite_verify.controller';

const router = Router();

// Dedicated QR verification & search endpoints
router.post('/verify', SqliteVerifyController.verify);
router.post('/medicines/verify', SqliteVerifyController.verify);
router.get('/medicines/search', SqliteVerifyController.search);

// Mount sub-routes
router.use('/health', healthRoutes);
router.use('/auth', authRoutes);
router.use('/medicines', medicineRoutes);
router.use('/medications', medicationRoutes);
router.use('/intake', intakeRoutes);
router.use('/verification', verificationRoutes);
router.use('/ai', aiRoutes);

// v1 compatibility aliases
router.use('/v1/health', healthRoutes);
router.use('/v1/auth', authRoutes);
router.use('/v1/medicines', medicineRoutes);
router.use('/v1/medications', medicationRoutes);
router.use('/v1/intake', intakeRoutes);
router.use('/v1/verification', verificationRoutes);
router.use('/v1/ai', aiRoutes);

export default router;
