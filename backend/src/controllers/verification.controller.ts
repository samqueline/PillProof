import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { VerificationService } from '../services/verification.service';

export class VerificationController {
  /**
   * GET /api/verification/history
   * Retrieves verification audit logs for the authenticated user.
   */
  public static async getHistory(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;
      const history = await VerificationService.getHistory(req.userId!, limit);

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
