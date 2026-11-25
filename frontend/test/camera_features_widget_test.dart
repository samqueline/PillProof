import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_proof/features/medications/presentation/medication_controller.dart';
import 'package:pill_proof/features/medications/presentation/screens/medications_screen.dart';
import 'package:pill_proof/features/verification/presentation/screens/verification_screen.dart';
import 'package:pill_proof/shared/models/medication_model.dart';

class _MockMedicationsListNotifier extends MedicationsNotifier {
  @override
  Future<List<MedicationModel>> build() async {
    return [
      MedicationModel(
        id: 'test-1',
        userId: 'user-1',
        medicineName: 'Amoxicillin 500mg',
        prescribedDosage: '1 capsule',
        maxPrescribedIntake: 2,
        frequency: 'Daily',
        scheduleTimes: ['09:00', '21:00'],
        startDate: DateTime.now(),
      ),
    ];
  }
}

void main() {
  testWidgets('VerificationScreen renders QR scanner and Tablet Cover OCR camera buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: VerificationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Verify Medicine'), findsOneWidget);

    // Verify Camera QR / Barcode button exists
    expect(find.text('Scan QR / Barcode'), findsOneWidget);

    // Verify Tablet Cover OCR button exists
    expect(find.text('Read Cover (OCR)'), findsOneWidget);

    // Verify text fields
    expect(find.text('Package Barcode / QR (Level 1 Match)'), findsOneWidget);
    expect(find.text('Medicine Name'), findsOneWidget);
  });

  testWidgets('MedicationsScreen renders camera OCR and QR scanning actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationsListProvider.overrideWith(() => _MockMedicationsListNotifier()),
        ],
        child: const MaterialApp(
          home: MedicationsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify My Medications header
    expect(find.text('My Medications'), findsOneWidget);

    // Verify OCR awareness banner
    expect(find.text('Tablet Packaging OCR Active'), findsOneWidget);

    // Tap Add Medication FAB to open modal
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify modal has Camera OCR & QR scan options
    expect(find.text('Auto-Fill with Camera'), findsOneWidget);
    expect(find.text('Read Tablet Cover (OCR)'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
  });
}
