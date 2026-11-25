import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_proof/app/app.dart';
import 'package:pill_proof/features/medications/data/medication_repository.dart';
import 'package:pill_proof/features/medications/presentation/medication_controller.dart';

void main() {
  testWidgets('Pill Proof app renders dashboard and quick actions smoke test',
      (WidgetTester tester) async {
    // Build app wrapped in ProviderScope with mock data override
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todaySummaryProvider.overrideWith(
            () => _MockTodaySummaryNotifier(),
          ),
        ],
        child: const PillProofApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app brand text is rendered
    expect(find.text('Pill Proof'), findsWidgets);

    // Verify quick action cards exist
    expect(find.text('Verify Medicine'), findsWidgets);
    expect(find.text('My Medications'), findsWidgets);

    // Verify mock schedule item rendered
    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
  });
}

class _MockTodaySummaryNotifier extends TodaySummaryNotifier {
  @override
  Future<List<TodayIntakeItem>> build() async {
    return [
      TodayIntakeItem(
        medicationId: 'demo-1',
        medicineName: 'Amoxicillin 500mg',
        dosage: '1 capsule',
        prescribedLimit: 3,
        dailyIntake: 1,
        status: 'WITHIN_LIMIT',
      ),
    ];
  }
}
