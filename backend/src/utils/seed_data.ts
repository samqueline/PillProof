export interface SeedMedicine {
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
}

export const DEMO_MEDICINES: SeedMedicine[] = [
  {
    name: 'Amoxicillin 500mg',
    genericName: 'Amoxicillin Trihydrate',
    manufacturer: 'GSK Pharmaceuticals',
    batchNumber: 'AMX-2026-X1',
    barcode: '8901234567890',
    expiryDate: new Date('2027-12-31'),
    strength: '500 mg',
    dosageForm: 'Capsule',
    status: 'verified',
    source: 'Pill Proof Verified Dataset'
  },
  {
    name: 'Metformin 850mg',
    genericName: 'Metformin Hydrochloride',
    manufacturer: 'Merck Healthcare',
    batchNumber: 'MET-850-B2',
    barcode: '8901234567891',
    expiryDate: new Date('2028-06-30'),
    strength: '850 mg',
    dosageForm: 'Tablet',
    status: 'verified',
    source: 'Pill Proof Verified Dataset'
  },
  {
    name: 'Paracetamol 650mg',
    genericName: 'Acetaminophen / Paracetamol',
    manufacturer: 'Micro Labs Limited',
    batchNumber: 'DOLO-650-C3',
    barcode: '8901234567892',
    expiryDate: new Date('2027-10-15'),
    strength: '650 mg',
    dosageForm: 'Tablet',
    status: 'verified',
    source: 'Pill Proof Verified Dataset'
  },
  {
    name: 'Cetirizine 10mg',
    genericName: 'Cetirizine Dihydrochloride',
    manufacturer: 'Cipla Ltd',
    batchNumber: 'CET-10-D4',
    barcode: '8901234567893',
    expiryDate: new Date('2028-01-31'),
    strength: '10 mg',
    dosageForm: 'Tablet',
    status: 'verified',
    source: 'Pill Proof Verified Dataset'
  },
  {
    name: 'Azithromycin 500mg',
    genericName: 'Azithromycin Dihydrate',
    manufacturer: 'Sun Pharmaceutical',
    batchNumber: 'AZI-500-E5',
    barcode: '8901234567894',
    expiryDate: new Date('2027-08-31'),
    strength: '500 mg',
    dosageForm: 'Tablet',
    status: 'verified',
    source: 'Pill Proof Verified Dataset'
  },
  // Expired demo batch for safety testing
  {
    name: 'Ibuprofen 400mg',
    genericName: 'Ibuprofen',
    manufacturer: 'Abbott Laboratories',
    batchNumber: 'IBU-OLD-99',
    barcode: '8901234567895',
    expiryDate: new Date('2024-01-01'), // Intentionally expired
    strength: '400 mg',
    dosageForm: 'Tablet',
    status: 'verified',
    source: 'Pill Proof Verified Dataset'
  },
  // Review recommended batch
  {
    name: 'Atorvastatin 20mg',
    genericName: 'Atorvastatin Calcium',
    manufacturer: 'Pfizer Inc',
    batchNumber: 'ATO-REV-77',
    barcode: '8901234567896',
    expiryDate: new Date('2027-05-31'),
    strength: '20 mg',
    dosageForm: 'Tablet',
    status: 'review',
    source: 'Pill Proof Verified Dataset'
  }
];
