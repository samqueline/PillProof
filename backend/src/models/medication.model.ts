import mongoose, { Document, Schema, Model, Types } from 'mongoose';

export interface IMedication extends Document {
  userId: Types.ObjectId;
  medicineId?: Types.ObjectId;
  medicineName: string;
  dosage: string;
  frequency: string;
  times: string[];
  prescribedLimit: number;
  startDate: Date;
  endDate?: Date;
  notes: string;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const MedicationSchema = new Schema<IMedication>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true
    },
    medicineId: {
      type: Schema.Types.ObjectId,
      ref: 'Medicine',
      required: false
    },
    medicineName: {
      type: String,
      required: [true, 'Medicine name is required'],
      trim: true
    },
    dosage: {
      type: String,
      required: [true, 'Prescribed dosage is required'],
      trim: true
    },
    frequency: {
      type: String,
      required: [true, 'Intake frequency is required'],
      trim: true
    },
    times: {
      type: [String],
      default: []
    },
    prescribedLimit: {
      type: Number,
      required: [true, 'Prescribed limit is required'],
      min: [1, 'Prescribed limit must be at least 1']
    },
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
      default: Date.now
    },
    endDate: {
      type: Date,
      required: false
    },
    notes: {
      type: String,
      default: '',
      trim: true
    },
    active: {
      type: Boolean,
      default: true
    }
  },
  {
    timestamps: true,
    collection: 'medications'
  }
);

MedicationSchema.index({ userId: 1, active: 1 });

export const Medication: Model<IMedication> =
  mongoose.models.Medication || mongoose.model<IMedication>('Medication', MedicationSchema);
