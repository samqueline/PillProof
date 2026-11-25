import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IMedicine extends Document {
  name: string;
  genericName: string;
  manufacturer: string;
  batchNumber: string;
  barcode: string;
  expiryDate: Date;
  strength: string;
  dosageForm: string;
  status: 'verified' | 'review' | 'inactive';
  source: string;
  createdAt: Date;
  updatedAt: Date;
}

const MedicineSchema = new Schema<IMedicine>(
  {
    name: {
      type: String,
      required: [true, 'Medicine name is required'],
      trim: true
    },
    genericName: {
      type: String,
      required: [true, 'Generic name is required'],
      trim: true
    },
    manufacturer: {
      type: String,
      required: [true, 'Manufacturer is required'],
      trim: true
    },
    batchNumber: {
      type: String,
      required: [true, 'Batch number is required'],
      trim: true,
      uppercase: true,
      index: true
    },
    barcode: {
      type: String,
      required: [true, 'Barcode is required'],
      trim: true,
      index: true
    },
    expiryDate: {
      type: Date,
      required: [true, 'Expiry date is required']
    },
    strength: {
      type: String,
      required: [true, 'Dosage strength is required'],
      trim: true
    },
    dosageForm: {
      type: String,
      required: [true, 'Dosage form is required'],
      trim: true
    },
    status: {
      type: String,
      enum: {
        values: ['verified', 'review', 'inactive'],
        message: '{VALUE} is not a valid medicine status'
      },
      default: 'verified'
    },
    source: {
      type: String,
      default: 'Pill Proof Verified Dataset',
      trim: true
    }
  },
  {
    timestamps: true,
    collection: 'medicines'
  }
);

// Compound index for fast verification search by name and batch
MedicineSchema.index({ name: 1, batchNumber: 1 });

export const Medicine: Model<IMedicine> =
  mongoose.models.Medicine || mongoose.model<IMedicine>('Medicine', MedicineSchema);
