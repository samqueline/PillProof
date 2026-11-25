import { Router } from 'express';
import { IntakeController } from '../controllers/intake.controller';
import { authenticateJwt } from '../middleware/auth.middleware';

const router = Router();

// Protect all intake endpoints with JWT authentication
router.use(authenticateJwt);

router.get('/today', IntakeController.getTodaySummary);
router.get('/history', IntakeController.getHistory);

export default router;
