import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/medication_model.dart';
import '../data/medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

class TodaySummaryNotifier extends AsyncNotifier<List<TodayIntakeItem>> {
  @override
  FutureOr<List<TodayIntakeItem>> build() {
    return ref.read(medicationRepositoryProvider).getTodaySummary();
  }

  Future<void> fetchSummary() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(medicationRepositoryProvider).getTodaySummary());
  }

  Future<IntakeResponseModel> recordIntake(String medicationId, {int quantity = 1}) async {
    final result = await ref.read(medicationRepositoryProvider).logIntake(medicationId, quantity: quantity);
    await fetchSummary();
    return result;
  }
}

final todaySummaryProvider =
    AsyncNotifierProvider<TodaySummaryNotifier, List<TodayIntakeItem>>(TodaySummaryNotifier.new);

class MedicationsNotifier extends AsyncNotifier<List<MedicationModel>> {
  @override
  FutureOr<List<MedicationModel>> build() {
    return ref.read(medicationRepositoryProvider).getMedications();
  }

  Future<void> fetchMedications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(medicationRepositoryProvider).getMedications());
  }

  Future<void> addMedication({
    required String name,
    required String dosage,
    required String frequency,
    required int limit,
    List<String> times = const [],
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    await ref.read(medicationRepositoryProvider).createMedication(
      medicineName: name,
      dosage: dosage,
      frequency: frequency,
      prescribedLimit: limit,
      times: times,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    );
    await fetchMedications();
    ref.invalidate(todaySummaryProvider);
  }
}

final medicationsListProvider =
    AsyncNotifierProvider<MedicationsNotifier, List<MedicationModel>>(MedicationsNotifier.new);
