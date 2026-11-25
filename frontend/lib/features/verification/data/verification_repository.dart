import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/medicine_model.dart';

class VerificationResultModel {
  final String status; // 'VERIFIED' | 'REVIEW' | 'NO_MATCH' | 'EXPIRED'
  final String message;
  final MedicineModel? matchedMedicine;
  final String? logId;

  VerificationResultModel({
    required this.status,
    required this.message,
    this.matchedMedicine,
    this.logId,
  });

  factory VerificationResultModel.fromJson(Map<String, dynamic> json) {
    final medRaw = json['matchedMedicine'] ?? json['medicine'];
    return VerificationResultModel(
      status: json['status'] ?? 'NO_MATCH',
      message: json['message'] ?? '',
      matchedMedicine: medRaw != null
          ? MedicineModel.fromJson(medRaw as Map<String, dynamic>)
          : null,
      logId: json['logId'],
    );
  }
}

class VerificationRepository {
  final ApiClient _apiClient;

  VerificationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<VerificationResultModel> verifyMedicine({
    String? payload,
    String? barcode,
    String? name,
    String? batchNumber,
    String? manufacturer,
    String? expiryDate,
  }) async {
    final body = <String, dynamic>{};
    if (payload != null && payload.isNotEmpty) body['payload'] = payload;
    if (barcode != null && barcode.isNotEmpty) body['barcode'] = barcode;
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (batchNumber != null && batchNumber.isNotEmpty) {
      body['batchNumber'] = batchNumber;
    }
    if (manufacturer != null && manufacturer.isNotEmpty) {
      body['manufacturer'] = manufacturer;
    }
    if (expiryDate != null && expiryDate.isNotEmpty) {
      body['expiryDate'] = expiryDate;
    }

    final response = await _apiClient.post(
      ApiConstants.verifyMedicine,
      data: body,
    );

    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>?;

    final resolvedStatus = data['status']?.toString() ??
        inner?['status']?.toString() ??
        'NO_MATCH';
    final resolvedMessage = data['message']?.toString() ??
        inner?['message']?.toString() ??
        '';
    final medRaw = inner?['matchedMedicine'] ??
        inner?['medicine'] ??
        data['matchedMedicine'] ??
        data['medicine'];

    return VerificationResultModel(
      status: resolvedStatus,
      message: resolvedMessage,
      matchedMedicine: medRaw != null
          ? MedicineModel.fromJson(medRaw as Map<String, dynamic>)
          : null,
      logId: (data['logId'] ?? inner?['logId'])?.toString(),
    );
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    final response = await _apiClient.get(
      '${ApiConstants.medicines}/search',
      queryParameters: {'q': query},
    );

    final data = response.data as Map<String, dynamic>;
    final list = data['medicines'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicineModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getVerificationHistory() async {
    final response = await _apiClient.get(ApiConstants.verificationHistory);
    final data = response.data as Map<String, dynamic>;
    final list = data['history'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
