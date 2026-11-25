import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../medications/presentation/medication_controller.dart';
import '../../verification/presentation/verification_controller.dart';

final intakeHistoryProvider =
    AsyncNotifierProvider<IntakeHistoryNotifier, List<Map<String, dynamic>>>(
  () => IntakeHistoryNotifier(),
);

class IntakeHistoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final repo = ref.read(medicationRepositoryProvider);
    return await repo.getIntakeHistory();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final verificationHistoryProvider =
    AsyncNotifierProvider<VerificationHistoryNotifier, List<Map<String, dynamic>>>(
  () => VerificationHistoryNotifier(),
);

class VerificationHistoryNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final repo = ref.read(verificationRepositoryProvider);
    return await repo.getVerificationHistory();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}
