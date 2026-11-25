import mongoose, { Document, Schema, Model, Types } from 'mongoose';

export interface IIntakeEvent extends Document {
  userId: Types.ObjectId;
  medicationId: Types.ObjectId;
  quantity: number;
  takenAt: Date;
  scheduledTime?: string;
  source: 'manual' | 'reminder';
  createdAt: Date;
}

const IntakeEventSchema = new Schema<IIntakeEvent>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true
    },
    medicationId: {
      type: Schema.Types.ObjectId,
      ref: 'Medication',
      required: [true, 'Medication ID is required'],
      index: true
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      default: 1,
      min: [1, 'Quantity must be at least 1']
    },
    takenAt: {
      type: Date,
      default: Date.now,
      required: true,
      index: true
    },
    scheduledTime: {
      type: String,
      trim: true
    },
    source: {
      type: String,
      enum: {
        values: ['manual', 'reminder'],
        message: '{VALUE} is not a valid intake source'
      },
      default: 'manual'
    }
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'intake_events'
  }
);

IntakeEventSchema.index({ userId: 1, medicationId: 1, takenAt: -1 });

export const IntakeEvent: Model<IIntakeEvent> =
  mongoose.models.IntakeEvent ||
  mongoose.model<IIntakeEvent>('IntakeEvent', IntakeEventSchema);
