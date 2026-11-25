import mongoose from 'mongoose';
import { Medicine, IMedicine } from '../models/medicine.model';
import { VerificationLog, IVerificationLog } from '../models/verification_log.model';
import { VerifyMedicineInput } from '../validators/medicine.validator';
import { DEMO_MEDICINES } from '../utils/seed_data';
import { inMemoryStore } from './in_memory_store';

export type VerificationStatusType = 'VERIFIED' | 'REVIEW' | 'NO_MATCH' | 'EXPIRED';

export interface VerificationResult {
  status: VerificationStatusType;
  message: string;
  matchedMedicine?: Record<string, unknown>;
  logId?: string;
}

export class VerificationService {
  /**
   * Deterministic medicine verification engine implementing Level 1, 2, 3 and expiry checks.
   */
  public static async verifyMedicine(
    input: VerifyMedicineInput,
    userId?: string
  ): Promise<VerificationResult> {
    const currentDate = new Date();
    let matchedMedicine: IMedicine | null = null;
    let matchType: 'barcode' | 'exact_combination' | 'partial' | null = null;

    // Check user-submitted expiry date upfront if provided
    if (input.expiryDate) {
      const parsedInputExpiry = new Date(input.expiryDate);
      if (!isNaN(parsedInputExpiry.getTime()) && parsedInputExpiry < currentDate) {
        return await this.createVerificationResponse(
          'EXPIRED',
          `The entered expiration date (${input.expiryDate}) has passed. Do not consume expired medicine.`,
          null,
          input,
          userId
        );
      }
    }

    // LEVEL 1: Exact Barcode Match
    if (input.barcode && input.barcode.trim()) {
      if (mongoose.connection.readyState === 1 || process.env.NODE_ENV === 'test') {
        matchedMedicine = await Medicine.findOne({
          barcode: input.barcode.trim()
        });
      } else {
        matchedMedicine = inMemoryStore.findMedicine(
          (m) => m.barcode.trim().toLowerCase() === input.barcode!.trim().toLowerCase()
        ) as any;
      }
      if (matchedMedicine) {
        matchType = 'barcode';
      }
    }

    // LEVEL 2: Exact Combination (Name + Batch Number + optional Manufacturer)
    if (!matchedMedicine && input.batchNumber && input.batchNumber.trim()) {
      if (mongoose.connection.readyState === 1 || process.env.NODE_ENV === 'test') {
        const query: Record<string, unknown> = {
          batchNumber: input.batchNumber.trim().toUpperCase()
        };

        if (input.name && input.name.trim()) {
          query.name = { $regex: new RegExp(`^${this.escapeRegex(input.name.trim())}$`, 'i') };
        }

        if (input.manufacturer && input.manufacturer.trim()) {
          query.manufacturer = {
            $regex: new RegExp(this.escapeRegex(input.manufacturer.trim()), 'i')
          };
        }

        matchedMedicine = await Medicine.findOne(query);
      } else {
        const batch = input.batchNumber.trim().toUpperCase();
        const name = input.name?.trim().toLowerCase();
        const manufacturer = input.manufacturer?.trim().toLowerCase();

        matchedMedicine = inMemoryStore.findMedicine((m) => {
          if (m.batchNumber.toUpperCase() !== batch) return false;
          if (name && m.name.toLowerCase() !== name) return false;
          if (manufacturer && !m.manufacturer.toLowerCase().includes(manufacturer)) return false;
          return true;
        }) as any;
      }

      if (matchedMedicine) {
        matchType = 'exact_combination';
      }
    }

    // LEVEL 3: Partial Search (Flagged as REVIEW rather than false VERIFIED)
    if (!matchedMedicine && input.name && input.name.trim().length >= 3) {
      if (mongoose.connection.readyState === 1 || process.env.NODE_ENV === 'test') {
        const partialQuery = {
          $or: [
            { name: { $regex: new RegExp(this.escapeRegex(input.name.trim()), 'i') } },
            { genericName: { $regex: new RegExp(this.escapeRegex(input.name.trim()), 'i') } }
          ]
        };

        const partialMatch = await Medicine.findOne(partialQuery);
        if (partialMatch) {
          matchedMedicine = partialMatch;
          matchType = 'partial';
        }
      } else {
        const term = input.name.trim().toLowerCase();
        const partialMatch = inMemoryStore.findMedicine(
          (m) =>
            m.name.toLowerCase().includes(term) || m.genericName.toLowerCase().includes(term)
        );
        if (partialMatch) {
          matchedMedicine = partialMatch as any;
          matchType = 'partial';
        }
      }
    }

    // If still no match found
    if (!matchedMedicine) {
      return await this.createVerificationResponse(
        'NO_MATCH',
        'No matching verified record was found.',
        null,
        input,
        userId
      );
    }

    // EXPIRY CHECK on matched medicine
    if (matchedMedicine.expiryDate && matchedMedicine.expiryDate < currentDate) {
      const formattedDate = matchedMedicine.expiryDate.toISOString().split('T')[0];
      return await this.createVerificationResponse(
        'EXPIRED',
        `Medicine expired on ${formattedDate}. Do not consume expired medication.`,
        matchedMedicine,
        input,
        userId
      );
    }

    // Determine Status based on matchType and medicine status
    if (matchType === 'partial' || matchedMedicine.status === 'review') {
      return await this.createVerificationResponse(
        'REVIEW',
        'Partial match found. Verification inconclusive; please check batch and packaging details with a healthcare provider.',
        matchedMedicine,
        input,
        userId
      );
    }

    // Exact Level 1 or Level 2 verified match
    return await this.createVerificationResponse(
      'VERIFIED',
      'Medicine details match a verified Pill Proof record.',
      matchedMedicine,
      input,
      userId
    );
  }

  /**
   * Search verified medicines catalog by query string.
   */
  public static async searchMedicines(query: string, limit = 20): Promise<IMedicine[]> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      return inMemoryStore.searchMedicines(query) as any;
    }
    const escaped = this.escapeRegex(query.trim());
    return await Medicine.find({
      $or: [
        { name: { $regex: new RegExp(escaped, 'i') } },
        { genericName: { $regex: new RegExp(escaped, 'i') } },
        { barcode: escaped },
        { batchNumber: escaped.toUpperCase() }
      ]
    })
      .limit(limit)
      .exec();
  }

  /**
   * Seed demo medicines into database if collection is empty.
   */
  public static async seedDemoMedicines(): Promise<{ count: number; seeded: boolean }> {
    if (mongoose.connection.readyState !== 1 && process.env.NODE_ENV !== 'test') {
      return { count: inMemoryStore.getMedicines().length, seeded: true };
    }
    const count = await Medicine.countDocuments();
    if (count === 0) {
      await Medicine.insertMany(DEMO_MEDICINES);
      return { count: DEMO_MEDICINES.length, seeded: true };
    }
    return { count, seeded: false };
  }

  /**
   * Retrieve verification audit logs for a user.
   */
  public static async getHistory(userId: string, limit = 50): Promise<IVerificationLog[]> {
    if (mongoose.connection.readyState === 1 || process.env.NODE_ENV === 'test') {
      return await VerificationLog.find({ userId: new mongoose.Types.ObjectId(userId) })
        .populate('matchedMedicineId')
        .sort({ createdAt: -1 })
        .limit(limit)
        .exec();
    }
    return [];
  }

  /**
   * Helper to format response and persist audit log.
   */
  private static async createVerificationResponse(
    status: VerificationStatusType,
    message: string,
    medicine: IMedicine | null,
    input: VerifyMedicineInput,
    userId?: string
  ): Promise<VerificationResult> {
    let logId: string | undefined;

    try {
      if (mongoose.connection.readyState === 1 || process.env.NODE_ENV === 'test') {
        const log = new VerificationLog({
          userId: userId ? new mongoose.Types.ObjectId(userId) : undefined,
          medicineInput: {
            name: input.name,
            batchNumber: input.batchNumber,
            barcode: input.barcode,
            manufacturer: input.manufacturer,
            expiryDate: input.expiryDate
          },
          result: status === 'NO_MATCH' ? 'unverified' : status === 'REVIEW' ? 'review_recommended' : status === 'EXPIRED' ? 'expired' : 'verified',
          matchedMedicineId: medicine?._id
        });
        await log.save();
        logId = log._id.toString();
      } else {
        logId = new mongoose.Types.ObjectId().toString();
      }
    } catch (err) {
      // Non-fatal logging error
      console.warn('[VerificationService] Failed to write verification log:', err);
    }

    return {
      status,
      message,
      matchedMedicine: medicine ? medicine.toObject() : undefined,
      logId
    };
  }

  private static escapeRegex(text: string): string {
    return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
  }
}
