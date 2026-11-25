import { z } from 'zod';

export const verifyMedicineSchema = z.object({
  name: z.string().trim().optional(),
  batchNumber: z.string().trim().optional(),
  barcode: z.string().trim().optional(),
  manufacturer: z.string().trim().optional(),
  expiryDate: z.string().trim().optional()
}).refine(
  (data) => Boolean(data.barcode || (data.name && data.batchNumber) || data.name),
  {
    message: 'Please provide either a barcode, or a medicine name and batch number.'
  }
);

export const searchMedicineSchema = z.object({
  q: z.string().min(1, 'Search query cannot be empty').trim()
});

export type VerifyMedicineInput = z.infer<typeof verifyMedicineSchema>;
export type SearchMedicineInput = z.infer<typeof searchMedicineSchema>;
