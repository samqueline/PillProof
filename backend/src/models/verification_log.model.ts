import mongoose, { Document, Schema, Model, Types } from 'mongoose';

export interface IVerificationLog extends Document {
  userId?: Types.ObjectId;
  medicineInput: {
    name?: string;
    batchNumber?: string;
    barcode?: string;
    manufacturer?: string;
    expiryDate?: string;
  };
  result: 'verified' | 'review_recommended' | 'unverified' | 'expired';
  matchedMedicineId?: Types.ObjectId;
  createdAt: Date;
}

const VerificationLogSchema = new Schema<IVerificationLog>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: false,
      index: true
    },
    medicineInput: {
      name: { type: String, trim: true },
      batchNumber: { type: String, trim: true },
      barcode: { type: String, trim: true },
      manufacturer: { type: String, trim: true },
      expiryDate: { type: String, trim: true }
    },
    result: {
      type: String,
      enum: {
        values: ['verified', 'review_recommended', 'unverified', 'expired'],
        message: '{VALUE} is not a valid verification result'
      },
      required: [true, 'Verification result is required']
    },
    matchedMedicineId: {
      type: Schema.Types.ObjectId,
      ref: 'Medicine',
      required: false
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  },
  {
    timestamps: false,
    collection: 'verification_logs'
  }
);

VerificationLogSchema.index({ userId: 1, createdAt: -1 });

export const VerificationLog: Model<IVerificationLog> =
  mongoose.models.VerificationLog ||
  mongoose.model<IVerificationLog>('VerificationLog', VerificationLogSchema);
