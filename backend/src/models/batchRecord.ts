import { Schema, model, Document } from 'mongoose';

export interface BatchRecordDocument extends Document {
  gtin: string;            // 14‑digit GTIN
  batchNumber: string;
  expiryDate: string;      // YYYY‑MM‑DD
  qrPayload: string;       // full GS1 QR payload string
}

const BatchRecordSchema = new Schema<BatchRecordDocument>({
  gtin: { type: String, required: true, index: true },
  batchNumber: { type: String, required: true },
  expiryDate: { type: String, required: true },
  qrPayload: { type: String, required: true },
});

export const BatchRecord = model<BatchRecordDocument>('BatchRecord', BatchRecordSchema);

