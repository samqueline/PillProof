import 'package:flutter_test/flutter_test.dart';
import 'package:pill_proof/features/scanner/models/scan_result.dart';
import 'package:pill_proof/features/ocr/services/medicine_text_parser.dart';

void main() {
  group('ScanResult Parser Unit Tests', () {
    test('parses plain barcode correctly', () {
      final result = ScanResult.fromRaw('8901234567890', format: 'EAN_13');
      expect(result.barcode, '8901234567890');
      expect(result.batchNumber, isNull);
      expect(result.expiryDate, isNull);
    });

    test('parses GS1 parenthesized format correctly', () {
      const gs1String = '(01)08901234567890(17)271231(10)AMX-2026-X1';
      final result = ScanResult.fromRaw(gs1String, format: 'DATA_MATRIX');

      expect(result.barcode, '8901234567890');
      expect(result.expiryDate, '2027-12-31');
      expect(result.batchNumber, 'AMX-2026-X1');
    });

    test('parses JSON formatted QR codes correctly', () {
      const jsonQr = '{"barcode":"8901234567890","name":"Amoxicillin 500mg","batch":"AMX-2026-X1","expiry":"2027-12-31"}';
      final result = ScanResult.fromRaw(jsonQr, format: 'QR_CODE');

      expect(result.barcode, '8901234567890');
      expect(result.medicineName, 'Amoxicillin 500mg');
      expect(result.batchNumber, 'AMX-2026-X1');
      expect(result.expiryDate, '2027-12-31');
    });
  });

  group('MedicineTextParser Tablet Cover OCR Unit Tests', () {
    test('extracts drug name, dosage, batch, and expiry from packaging text', () {
      final samplePackagingLines = [
        'Schedule H Prescription Drug - Caution',
        'Amoxicillin Capsules IP',
        '500 mg',
        'Each capsule contains: Amoxicillin Trihydrate IP equivalent to Amoxicillin 500mg',
        'B.No. AMX-2026-X1',
        'EXP. 12/2027',
        'Mfg. Lic. No. 25/UA/2018',
        'GlaxoSmithKline Pharmaceuticals Ltd',
        'Keep out of reach of children',
        'Store protected from light and moisture at a temperature not exceeding 30°C',
      ];

      final ocrResult = MedicineTextParser.parse(samplePackagingLines);

      // Verify the drug name was accurately recognized
      expect(ocrResult.suggestedDrugName.toLowerCase(), contains('amoxicillin'));
      expect(ocrResult.detectedDosage, contains('500'));
      expect(ocrResult.dosageForm, 'Capsule');
      expect(ocrResult.detectedBatch, 'AMX-2026-X1');
      expect(ocrResult.detectedExpiry, '2027-12-01');
      expect(ocrResult.detectedManufacturer, 'GlaxoSmithKline');

      // Verify noise phrases were filtered out of suggestions
      expect(ocrResult.candidateNames, isNotEmpty);
      for (final cand in ocrResult.candidateNames) {
        expect(cand.toLowerCase(), isNot(contains('schedule h')));
        expect(cand.toLowerCase(), isNot(contains('keep out of reach')));
      }
    });

    test('extracts Paracetamol tablet packaging with high accuracy', () {
      final doloLines = [
        'Dolo 650',
        'Paracetamol Tablets IP',
        '650 mg',
        'B.No. DL-9923',
        'EXP 08/28',
        'Micro Labs Limited',
      ];

      final ocrResult = MedicineTextParser.parse(doloLines);

      expect(
        ocrResult.suggestedDrugName.toLowerCase(),
        anyOf([contains('dolo'), contains('paracetamol')]),
      );
      expect(ocrResult.detectedDosage, contains('650'));
      expect(ocrResult.dosageForm, 'Tablet');
      expect(ocrResult.detectedBatch, 'DL-9923');
    });

    test('extracts drug with pharmacological suffix like -statin or -zole', () {
      final atorvaLines = [
        'Atorvastatin Tablets IP',
        '20 mg',
        'B.No. ATO-441',
        'Pfizer',
      ];

      final ocrResult = MedicineTextParser.parse(atorvaLines);
      expect(ocrResult.suggestedDrugName.toLowerCase(), contains('atorvastatin'));
      expect(ocrResult.detectedDosage, contains('20'));
    });
  });
}
