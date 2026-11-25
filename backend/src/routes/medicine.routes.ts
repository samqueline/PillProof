import { Router } from 'express';
import { MedicineController } from '../controllers/medicine.controller';
import { SqliteVerifyController } from '../controllers/sqlite_verify.controller';
import { optionalAuthenticateJwt } from '../middleware/auth.middleware';

const router = Router();

router.post('/verify', optionalAuthenticateJwt, SqliteVerifyController.verify);
router.get('/search', SqliteVerifyController.search);
router.get('/', MedicineController.getAll);
router.get('/:id', MedicineController.getById);
router.post('/seed', MedicineController.seed);

export default router;
