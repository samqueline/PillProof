import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { VerificationService } from '../services/verification.service';
import { verifyMedicineSchema, searchMedicineSchema } from '../validators/medicine.validator';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Medicine } from '../models/medicine.model';
import mongoose from 'mongoose';
import { inMemoryStore } from '../services/in_memory_store';

export class MedicineController {
  /**
   * POST /api/medicines/verify
   */
  public static async verify(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const validatedInput = verifyMedicineSchema.parse(req.body);
      const result = await VerificationService.verifyMedicine(validatedInput, req.userId);

      res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: error.errors.map((e) => ({
            field: e.path.join('.'),
            message: e.message
          }))
        });
        return;
      }
      next(error);
    }
  }

  /**
   * GET /api/medicines/search?q=...
   */
  public static async search(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { q } = searchMedicineSchema.parse(req.query);
      const medicines = await VerificationService.searchMedicines(q);

      res.status(200).json({
        success: true,
        count: medicines.length,
        medicines
      });
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          message: error.errors[0]?.message || 'Invalid search query'
        });
        return;
      }
      next(error);
    }
  }

  /**
   * GET /api/medicines
   */
  public static async getAll(
    _req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
        const medicines = inMemoryStore.getMedicines().map((m) => m.toObject());
        res.status(200).json({
          success: true,
          count: medicines.length,
          medicines
        });
        return;
      }
      const medicines = await Medicine.find().sort({ name: 1 }).limit(100);
      res.status(200).json({
        success: true,
        count: medicines.length,
        medicines
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/medicines/:id
   */
  public static async getById(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
        const medicine = inMemoryStore.findMedicine((m) => m._id.toString() === req.params.id);
        if (!medicine) {
          res.status(404).json({
            success: false,
            message: 'Medicine not found'
          });
          return;
        }
        res.status(200).json({
          success: true,
          medicine: medicine.toObject()
        });
        return;
      }
      const medicine = await Medicine.findById(req.params.id);
      if (!medicine) {
        res.status(404).json({
          success: false,
          message: 'Medicine not found'
        });
        return;
      }

      res.status(200).json({
        success: true,
        medicine
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/medicines/seed
   */
  public static async seed(
    _req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const result = await VerificationService.seedDemoMedicines();
      res.status(200).json({
        success: true,
        message: result.seeded
          ? `Successfully seeded ${result.count} demo medicines.`
          : `Database already contains ${result.count} medicines. Seed skipped.`
      });
    } catch (error) {
      next(error);
    }
  }
}
