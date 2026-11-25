import { z } from 'zod';

export const createMedicationSchema = z.object({
  medicineId: z.string().optional(),
  medicineName: z.string().min(2, 'Medicine name must be at least 2 characters').trim(),
  dosage: z.string().min(1, 'Dosage is required').trim(),
  frequency: z.string().min(1, 'Frequency is required').trim(),
  times: z.array(z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Times must be in HH:MM format')).optional().default([]),
  prescribedLimit: z.number().int().min(1, 'Prescribed limit must be at least 1 dose per day'),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  notes: z.string().trim().optional().default('')
});

export const updateMedicationSchema = z.object({
  medicineName: z.string().min(2).trim().optional(),
  dosage: z.string().min(1).trim().optional(),
  frequency: z.string().min(1).trim().optional(),
  times: z.array(z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/)).optional(),
  prescribedLimit: z.number().int().min(1).optional(),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  notes: z.string().trim().optional(),
  active: z.boolean().optional()
});

export const logIntakeSchema = z.object({
  quantity: z.number().int().min(1, 'Quantity must be at least 1').default(1),
  scheduledTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).optional(),
  source: z.enum(['manual', 'reminder']).default('manual'),
  takenAt: z.string().optional()
});

export type CreateMedicationInput = z.infer<typeof createMedicationSchema>;
export type UpdateMedicationInput = z.infer<typeof updateMedicationSchema>;
export type LogIntakeInput = z.infer<typeof logIntakeSchema>;
