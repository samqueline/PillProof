import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/verification_repository.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository();
});

class VerificationState {
  final bool isLoading;
  final VerificationResultModel? result;
  final String? errorMessage;

  const VerificationState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  VerificationState copyWith({
    bool? isLoading,
    VerificationResultModel? result,
    String? errorMessage,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

class VerificationNotifier extends Notifier<VerificationState> {
  @override
  VerificationState build() {
    return const VerificationState();
  }

  Future<void> verify({
    String? payload,
    String? barcode,
    String? name,
    String? batchNumber,
    String? manufacturer,
    String? expiryDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(verificationRepositoryProvider);
      final result = await repo.verifyMedicine(
        payload: payload,
        barcode: barcode,
        name: name,
        batchNumber: batchNumber,
        manufacturer: manufacturer,
        expiryDate: expiryDate,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clear() {
    state = const VerificationState();
  }
}

final verificationProvider =
    NotifierProvider<VerificationNotifier, VerificationState>(VerificationNotifier.new);
