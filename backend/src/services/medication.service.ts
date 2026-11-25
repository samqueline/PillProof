import mongoose from 'mongoose';
import { Medication, IMedication } from '../models/medication.model';
import { IntakeEvent, IIntakeEvent } from '../models/intake_event.model';
import {
  CreateMedicationInput,
  UpdateMedicationInput,
  LogIntakeInput
} from '../validators/medication.validator';
import { inMemoryStore } from './in_memory_store';

export type IntakeLimitStatus = 'WITHIN_LIMIT' | 'LIMIT_REACHED' | 'LIMIT_EXCEEDED';

export interface IntakeResult {
  status: IntakeLimitStatus;
  dailyIntake: number;
  prescribedLimit: number;
  message: string;
  intakeEvent: IIntakeEvent;
}

export class MedicationService {
  /**
   * Create a new medication schedule with user-defined prescribed limit.
   */
  public static async createMedication(
    userId: string,
    input: CreateMedicationInput
  ): Promise<IMedication> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      const id = new mongoose.Types.ObjectId();
      const med = {
        _id: id,
        userId: new mongoose.Types.ObjectId(userId),
        medicineId: input.medicineId ? new mongoose.Types.ObjectId(input.medicineId) : undefined,
        medicineName: input.medicineName,
        dosage: input.dosage,
        frequency: input.frequency,
        times: input.times || [],
        prescribedLimit: input.prescribedLimit,
        startDate: input.startDate ? new Date(input.startDate) : new Date(),
        endDate: input.endDate ? new Date(input.endDate) : undefined,
        notes: input.notes || '',
        active: true,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      return inMemoryStore.addMedication(med as any) as any;
    }

    const medication = new Medication({
      userId: new mongoose.Types.ObjectId(userId),
      medicineId: input.medicineId ? new mongoose.Types.ObjectId(input.medicineId) : undefined,
      medicineName: input.medicineName,
      dosage: input.dosage,
      frequency: input.frequency,
      times: input.times || [],
      prescribedLimit: input.prescribedLimit,
      startDate: input.startDate ? new Date(input.startDate) : new Date(),
      endDate: input.endDate ? new Date(input.endDate) : undefined,
      notes: input.notes || '',
      active: true
    });

    return await medication.save();
  }

  /**
   * Get all medications for a user.
   */
  public static async getUserMedications(
    userId: string,
    includeInactive = false
  ): Promise<IMedication[]> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      return inMemoryStore.getMedications(userId, includeInactive) as any;
    }

    const filter: Record<string, unknown> = {
      userId: new mongoose.Types.ObjectId(userId)
    };

    if (!includeInactive) {
      filter.active = true;
    }

    return await Medication.find(filter).sort({ createdAt: -1 }).exec();
  }

  /**
   * Get specific medication by ID, validating ownership.
   */
  public static async getMedicationById(
    userId: string,
    medicationId: string
  ): Promise<IMedication> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      const med = inMemoryStore.findMedicationById(medicationId, userId);
      if (!med) {
        const error = new Error('Medication record not found.');
        (error as any).statusCode = 404;
        throw error;
      }
      return med as any;
    }

    const medication = await Medication.findOne({
      _id: new mongoose.Types.ObjectId(medicationId),
      userId: new mongoose.Types.ObjectId(userId)
    });

    if (!medication) {
      const error = new Error('Medication record not found.');
      (error as any).statusCode = 404;
      throw error;
    }

    return medication;
  }

  /**
   * Update a medication record.
   */
  public static async updateMedication(
    userId: string,
    medicationId: string,
    input: UpdateMedicationInput
  ): Promise<IMedication> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      const updated = inMemoryStore.updateMedication(medicationId, userId, input as any);
      if (!updated) {
        const error = new Error('Medication record not found.');
        (error as any).statusCode = 404;
        throw error;
      }
      return updated as any;
    }

    const medication = await this.getMedicationById(userId, medicationId);

    if (input.medicineName !== undefined) medication.medicineName = input.medicineName;
    if (input.dosage !== undefined) medication.dosage = input.dosage;
    if (input.frequency !== undefined) medication.frequency = input.frequency;
    if (input.times !== undefined) medication.times = input.times;
    if (input.prescribedLimit !== undefined) medication.prescribedLimit = input.prescribedLimit;
    if (input.startDate !== undefined) medication.startDate = new Date(input.startDate);
    if (input.endDate !== undefined) medication.endDate = input.endDate ? new Date(input.endDate) : undefined;
    if (input.notes !== undefined) medication.notes = input.notes;
    if (input.active !== undefined) medication.active = input.active;

    return await medication.save();
  }

  /**
   * Delete / deactivate a medication record.
   */
  public static async deleteMedication(
    userId: string,
    medicationId: string
  ): Promise<{ message: string }> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      inMemoryStore.updateMedication(medicationId, userId, { active: false });
      return { message: 'Medication deactivated successfully.' };
    }

    const medication = await this.getMedicationById(userId, medicationId);
    medication.active = false;
    await medication.save();

    return { message: 'Medication deactivated successfully.' };
  }

  /**
   * INTAKE LIMIT ENGINE (Sections 17 & 18):
   * Logs an intake event and calculates daily consumption against user's prescribed limit.
   */
  public static async logIntake(
    userId: string,
    medicationId: string,
    input: LogIntakeInput
  ): Promise<IntakeResult> {
    const medication = await this.getMedicationById(userId, medicationId);

    const takenAt = input.takenAt ? new Date(input.takenAt) : new Date();

    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      const eventId = new mongoose.Types.ObjectId();
      const intakeEvent = {
        _id: eventId,
        userId: new mongoose.Types.ObjectId(userId),
        medicationId: medication._id,
        medicineName: medication.medicineName,
        quantity: input.quantity || 1,
        takenAt,
        scheduledTime: input.scheduledTime,
        source: input.source || 'manual',
        createdAt: new Date(),
        updatedAt: new Date()
      };

      inMemoryStore.addIntakeEvent(intakeEvent as any);

      const startOfDay = new Date(takenAt);
      startOfDay.setHours(0, 0, 0, 0);

      const endOfDay = new Date(takenAt);
      endOfDay.setHours(23, 59, 59, 999);

      const dailyEvents = inMemoryStore.getIntakeEventsForMedication(
        medication._id.toString(),
        startOfDay,
        endOfDay
      );

      const dailyIntake = dailyEvents.reduce((sum, e) => sum + ((e as any).quantity || 1), 0);

      let status: IntakeLimitStatus = 'WITHIN_LIMIT';
      let message = 'Intake recorded within your prescribed limit.';

      if (dailyIntake > medication.prescribedLimit) {
        status = 'LIMIT_EXCEEDED';
        message = 'Awareness Alert: Daily recorded intake exceeds your configured prescribed limit.';
      } else if (dailyIntake === medication.prescribedLimit) {
        status = 'LIMIT_REACHED';
        message = 'Awareness Notice: Daily recorded intake has reached your configured prescribed limit.';
      }

      return {
        status,
        dailyIntake,
        prescribedLimit: medication.prescribedLimit,
        message,
        intakeEvent: intakeEvent as any
      };
    }

    const intakeEvent = new IntakeEvent({
      userId: new mongoose.Types.ObjectId(userId),
      medicationId: medication._id,
      quantity: input.quantity || 1,
      takenAt,
      scheduledTime: input.scheduledTime,
      source: input.source || 'manual'
    });

    await intakeEvent.save();

    // Calculate sum of doses taken on the same calendar day
    const startOfDay = new Date(takenAt);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(takenAt);
    endOfDay.setHours(23, 59, 59, 999);

    const dailyEvents = await IntakeEvent.find({
      userId: new mongoose.Types.ObjectId(userId),
      medicationId: medication._id,
      takenAt: { $gte: startOfDay, $lte: endOfDay }
    });

    const dailyIntake = dailyEvents.reduce((sum, e) => sum + e.quantity, 0);

    let status: IntakeLimitStatus = 'WITHIN_LIMIT';
    let message = 'Intake recorded within your prescribed limit.';

    if (dailyIntake > medication.prescribedLimit) {
      status = 'LIMIT_EXCEEDED';
      message = 'Awareness Alert: Daily recorded intake exceeds your configured prescribed limit.';
    } else if (dailyIntake === medication.prescribedLimit) {
      status = 'LIMIT_REACHED';
      message = 'Awareness Notice: Daily recorded intake has reached your configured prescribed limit.';
    }

    return {
      status,
      dailyIntake,
      prescribedLimit: medication.prescribedLimit,
      message,
      intakeEvent
    };
  }

  /**
   * Get intake history for user (optionally filtered by medication).
   */
  public static async getIntakeHistory(
    userId: string,
    medicationId?: string,
    limit = 50
  ): Promise<IIntakeEvent[]> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      let events = inMemoryStore.getIntakeEventsForUser(userId, limit);
      if (medicationId) {
        events = events.filter((e) => e.medicationId.toString() === medicationId);
      }
      return events as any;
    }

    const filter: Record<string, unknown> = {
      userId: new mongoose.Types.ObjectId(userId)
    };

    if (medicationId) {
      filter.medicationId = new mongoose.Types.ObjectId(medicationId);
    }

    return await IntakeEvent.find(filter)
      .sort({ takenAt: -1 })
      .limit(limit)
      .exec();
  }

  /**
   * Get today's intake summary across all active medications for current user.
   */
  public static async getTodaySummary(userId: string): Promise<Array<{
    medicationId: string;
    medicineName: string;
    dosage: string;
    prescribedLimit: number;
    dailyIntake: number;
    status: IntakeLimitStatus;
  }>> {
    const medications = await this.getUserMedications(userId);

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      return medications.map((med) => {
        const events = inMemoryStore.getIntakeEventsForMedication(
          med._id.toString(),
          startOfDay,
          endOfDay
        );
        const dailyIntake = events.reduce((sum, e) => sum + ((e as any).quantity || 1), 0);

        let status: IntakeLimitStatus = 'WITHIN_LIMIT';
        if (dailyIntake > med.prescribedLimit) {
          status = 'LIMIT_EXCEEDED';
        } else if (dailyIntake === med.prescribedLimit) {
          status = 'LIMIT_REACHED';
        }

        return {
          medicationId: med._id.toString(),
          medicineName: med.medicineName,
          dosage: med.dosage,
          prescribedLimit: med.prescribedLimit,
          dailyIntake,
          status
        };
      });
    }

    const todayEvents = await IntakeEvent.find({
      userId: new mongoose.Types.ObjectId(userId),
      takenAt: { $gte: startOfDay, $lte: endOfDay }
    });

    return medications.map((med) => {
      const events = todayEvents.filter(
        (e) => e.medicationId.toString() === med._id.toString()
      );
      const dailyIntake = events.reduce((sum, e) => sum + e.quantity, 0);

      let status: IntakeLimitStatus = 'WITHIN_LIMIT';
      if (dailyIntake > med.prescribedLimit) {
        status = 'LIMIT_EXCEEDED';
      } else if (dailyIntake === med.prescribedLimit) {
        status = 'LIMIT_REACHED';
      }

      return {
        medicationId: med._id.toString(),
        medicineName: med.medicineName,
        dosage: med.dosage,
        prescribedLimit: med.prescribedLimit,
        dailyIntake,
        status
      };
    });
  }
}
