import mongoose from 'mongoose';
import { DEMO_MEDICINES, SeedMedicine } from '../utils/seed_data';

export interface InMemoryUser {
  _id: mongoose.Types.ObjectId;
  name: string;
  email: string;
  passwordHash: string;
  role: 'user' | 'admin' | 'caregiver';
  createdAt: Date;
  updatedAt: Date;
  comparePassword(plain: string): Promise<boolean>;
  toPublicJSON(): Record<string, unknown>;
}

export interface InMemoryMedication {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  medicineId?: mongoose.Types.ObjectId;
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

export interface InMemoryIntakeEvent {
  _id: mongoose.Types.ObjectId;
  medicationId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  medicineName: string;
  timestamp: Date;
  dosageTaken: string;
  source: 'manual' | 'reminder_confirm' | 'scanner';
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface InMemoryMedicine extends SeedMedicine {
  _id: mongoose.Types.ObjectId;
  toObject(): Record<string, unknown>;
}

class InMemoryDatabase {
  private users: InMemoryUser[] = [];
  private medications: InMemoryMedication[] = [];
  private intakeEvents: InMemoryIntakeEvent[] = [];
  private medicines: InMemoryMedicine[] = [];

  constructor() {
    this.medicines = DEMO_MEDICINES.map((m) => {
      const id = new mongoose.Types.ObjectId();
      return {
        ...m,
        _id: id,
        toObject() {
          return {
            _id: id.toString(),
            name: m.name,
            genericName: m.genericName,
            manufacturer: m.manufacturer,
            batchNumber: m.batchNumber,
            barcode: m.barcode,
            expiryDate: m.expiryDate.toISOString(),
            strength: m.strength,
            dosageForm: m.dosageForm,
            status: m.status,
            source: m.source
          };
        }
      };
    });
  }

  public getMedicines(): InMemoryMedicine[] {
    return this.medicines;
  }

  public findMedicine(predicate: (m: InMemoryMedicine) => boolean): InMemoryMedicine | null {
    return this.medicines.find(predicate) || null;
  }

  public searchMedicines(q: string): InMemoryMedicine[] {
    const term = q.toLowerCase();
    return this.medicines.filter(
      (m) =>
        m.name.toLowerCase().includes(term) ||
        m.genericName.toLowerCase().includes(term) ||
        m.barcode.toLowerCase().includes(term) ||
        m.batchNumber.toLowerCase().includes(term) ||
        m.manufacturer.toLowerCase().includes(term)
    );
  }

  public findUserByEmail(email: string): InMemoryUser | null {
    return this.users.find((u) => u.email.toLowerCase() === email.toLowerCase()) || null;
  }

  public findUserById(id: string): InMemoryUser | null {
    return this.users.find((u) => u._id.toString() === id) || null;
  }

  public addUser(user: InMemoryUser): void {
    this.users.push(user);
  }

  public getMedications(userId: string, includeInactive = false): InMemoryMedication[] {
    return this.medications.filter(
      (m) => m.userId.toString() === userId && (includeInactive ? true : m.active)
    );
  }

  public findMedicationById(medicationId: string, userId: string): InMemoryMedication | null {
    return (
      this.medications.find(
        (m) => m._id.toString() === medicationId && m.userId.toString() === userId
      ) || null
    );
  }

  public addMedication(med: InMemoryMedication): InMemoryMedication {
    this.medications.push(med);
    return med;
  }

  public updateMedication(
    medicationId: string,
    userId: string,
    updates: Partial<InMemoryMedication>
  ): InMemoryMedication | null {
    const med = this.findMedicationById(medicationId, userId);
    if (!med) return null;
    Object.assign(med, updates, { updatedAt: new Date() });
    return med;
  }

  public addIntakeEvent(event: InMemoryIntakeEvent): InMemoryIntakeEvent {
    this.intakeEvents.push(event);
    return event;
  }

  public getIntakeEventsForMedication(
    medicationId: string,
    from?: Date,
    to?: Date
  ): InMemoryIntakeEvent[] {
    return this.intakeEvents.filter((e) => {
      if (e.medicationId.toString() !== medicationId) return false;
      if (from && e.timestamp < from) return false;
      if (to && e.timestamp > to) return false;
      return true;
    });
  }

  public getIntakeEventsForUser(userId: string, limit = 50): InMemoryIntakeEvent[] {
    return this.intakeEvents
      .filter((e) => e.userId.toString() === userId)
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .slice(0, limit);
  }
}

export const inMemoryStore = new InMemoryDatabase();
