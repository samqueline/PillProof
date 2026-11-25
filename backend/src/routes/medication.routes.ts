import { Router } from 'express';
import { MedicationController } from '../controllers/medication.controller';
import { authenticateJwt } from '../middleware/auth.middleware';

const router = Router();

// Protect all medication endpoints with JWT authentication
router.use(authenticateJwt);

router.post('/', MedicationController.create);
router.get('/', MedicationController.getAll);
router.get('/:id', MedicationController.getById);
router.patch('/:id', MedicationController.update);
router.delete('/:id', MedicationController.delete);

// Intake sub-routes for specific medication
router.post('/:id/intake', MedicationController.logIntake);
router.get('/:id/intake', MedicationController.getMedicationIntake);

export default router;
