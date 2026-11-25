import { Router } from 'express';
import { VerificationController } from '../controllers/verification.controller';
import { authenticateJwt } from '../middleware/auth.middleware';

const router = Router();

// Protect verification history endpoint with JWT authentication
router.use(authenticateJwt);

router.get('/history', VerificationController.getHistory);

export default router;
