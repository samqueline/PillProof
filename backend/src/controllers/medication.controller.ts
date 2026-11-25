import { Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { MedicationService } from '../services/medication.service';
import {
  createMedicationSchema,
  updateMedicationSchema,
  logIntakeSchema
} from '../validators/medication.validator';

export class MedicationController {
  public static async create(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const input = createMedicationSchema.parse(req.body);
      const medication = await MedicationService.createMedication(req.userId, input);

      res.status(201).json({
        success: true,
        message: 'Medication scheduled successfully',
        medication
      });
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: error.errors.map((e) => ({ field: e.path.join('.'), message: e.message }))
        });
        return;
      }
      next(error);
    }
  }

  public static async getAll(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const includeInactive = req.query.includeInactive === 'true';
      const medications = await MedicationService.getUserMedications(req.userId, includeInactive);

      res.status(200).json({
        success: true,
        count: medications.length,
        medications
      });
    } catch (error) {
      next(error);
    }
  }

  public static async getById(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const medication = await MedicationService.getMedicationById(req.userId, req.params.id);

      res.status(200).json({
        success: true,
        medication
      });
    } catch (error) {
      next(error);
    }
  }

  public static async update(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const input = updateMedicationSchema.parse(req.body);
      const medication = await MedicationService.updateMedication(
        req.userId,
        req.params.id,
        input
      );

      res.status(200).json({
        success: true,
        message: 'Medication updated successfully',
        medication
      });
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: error.errors.map((e) => ({ field: e.path.join('.'), message: e.message }))
        });
        return;
      }
      next(error);
    }
  }

  public static async delete(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const result = await MedicationService.deleteMedication(req.userId, req.params.id);
      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      next(error);
    }
  }

  public static async logIntake(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const input = logIntakeSchema.parse(req.body);
      const result = await MedicationService.logIntake(
        req.userId,
        req.params.id,
        input
      );

      res.status(201).json({
        success: true,
        data: result
      });
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: error.errors.map((e) => ({ field: e.path.join('.'), message: e.message }))
        });
        return;
      }
      next(error);
    }
  }

  public static async getMedicationIntake(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const history = await MedicationService.getIntakeHistory(req.userId, req.params.id);

      res.status(200).json({
        success: true,
        count: history.length,
        history
      });
    } catch (error) {
      next(error);
    }
  }
}
