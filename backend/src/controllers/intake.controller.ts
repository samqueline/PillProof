import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { MedicationService } from '../services/medication.service';

export class IntakeController {
  public static async getTodaySummary(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const summary = await MedicationService.getTodaySummary(req.userId);

      res.status(200).json({
        success: true,
        count: summary.length,
        summary
      });
    } catch (error) {
      next(error);
    }
  }

  public static async getHistory(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ success: false, message: 'Authentication required' });
        return;
      }

      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;
      const history = await MedicationService.getIntakeHistory(req.userId, undefined, limit);

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
