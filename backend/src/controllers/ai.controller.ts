import { Request, Response, NextFunction } from 'express';
import { AiChatService } from '../services/ai_chat.service';
import { z } from 'zod';

const chatRequestSchema = z.object({
  message: z.string().trim().min(1, 'Message query cannot be empty'),
  history: z
    .array(
      z.object({
        role: z.enum(['user', 'model', 'assistant']),
        content: z.string()
      })
    )
    .optional()
    .default([])
});

export class AiController {
  /**
   * POST /api/ai/chat
   * Responds to user queries regarding medicine uses, dosages, and interactions.
   */
  public static async chat(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const parsed = chatRequestSchema.parse(req.body);
      const result = await AiChatService.answerQuery(parsed.message, parsed.history);

      res.status(200).json({
        success: true,
        ...result
      });
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          message: 'Invalid chat request',
          errors: error.errors.map((e) => e.message)
        });
        return;
      }
      next(error);
    }
  }
}

