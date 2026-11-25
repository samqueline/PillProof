import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/medication_model.dart';

class IntakeResponseModel {
  final String status; // 'WITHIN_LIMIT' | 'LIMIT_REACHED' | 'LIMIT_EXCEEDED'
  final int dailyIntake;
  final int prescribedLimit;
  final String message;

  IntakeResponseModel({
    required this.status,
    required this.dailyIntake,
    required this.prescribedLimit,
    required this.message,
  });

  factory IntakeResponseModel.fromJson(Map<String, dynamic> json) {
    return IntakeResponseModel(
      status: json['status'] ?? 'WITHIN_LIMIT',
      dailyIntake: json['dailyIntake'] ?? 0,
      prescribedLimit: json['prescribedLimit'] ?? 1,
      message: json['message'] ?? '',
    );
  }
}

class TodayIntakeItem {
  final String medicationId;
  final String medicineName;
  final String dosage;
  final int prescribedLimit;
  final int dailyIntake;
  final String status;

  TodayIntakeItem({
    required this.medicationId,
    required this.medicineName,
    required this.dosage,
    required this.prescribedLimit,
    required this.dailyIntake,
    required this.status,
  });

  factory TodayIntakeItem.fromJson(Map<String, dynamic> json) {
    return TodayIntakeItem(
      medicationId: json['medicationId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'] ?? '',
      prescribedLimit: json['prescribedLimit'] ?? 1,
      dailyIntake: json['dailyIntake'] ?? 0,
      status: json['status'] ?? 'WITHIN_LIMIT',
    );
  }

  Map<String, dynamic> toJson() => {
        'medicationId': medicationId,
        'medicineName': medicineName,
        'dosage': dosage,
        'prescribedLimit': prescribedLimit,
        'dailyIntake': dailyIntake,
        'status': status,
      };
}

class MedicationRepository {
  final ApiClient _apiClient;
  static const String _localMedsKey = 'local_medications_v1';
  static const String _localIntakesKey = 'local_intakes_v1';

  MedicationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<MedicationModel>> getMedications() async {
    try {
      final response = await _apiClient.get(ApiConstants.medications);
      final data = response.data as Map<String, dynamic>;
      final list = data['medications'] as List<dynamic>? ?? [];
      final serverMeds = list
          .map((e) => MedicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Also cache server meds into local storage
      if (serverMeds.isNotEmpty) {
        await _saveLocalMedications(serverMeds);
        return serverMeds;
      }
    } catch (_) {}

    // Fallback: Read from local persistent storage
    final localMeds = await _getLocalMedications();
    return localMeds;
  }

  Future<MedicationModel> createMedication({
    required String medicineName,
    required String dosage,
    required String frequency,
    required int prescribedLimit,
    List<String> times = const [],
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    final start = startDate ?? DateTime.now();
    MedicationModel? createdMed;

    try {
      final response = await _apiClient.post(
        ApiConstants.medications,
        data: {
          'medicineName': medicineName,
          'dosage': dosage,
          'frequency': frequency,
          'prescribedLimit': prescribedLimit,
          'times': times,
          'startDate': start.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          'notes': notes ?? '',
        },
      );
      final data = response.data as Map<String, dynamic>;
      createdMed = MedicationModel.fromJson(data['medication'] as Map<String, dynamic>);
    } catch (_) {
      // Local fallback ID
      createdMed = MedicationModel(
        id: 'med_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        medicineName: medicineName,
        prescribedDosage: dosage,
        maxPrescribedIntake: prescribedLimit,
        frequency: frequency,
        scheduleTimes: times.isNotEmpty ? times : ['09:00', '21:00'],
        startDate: start,
        endDate: endDate,
        notes: notes ?? '',
        isActive: true,
      );
    }

    // Save to local storage for instant offline & persistent calendar visibility
    final list = await _getLocalMedications();
    list.removeWhere((m) => m.id == createdMed!.id);
    list.insert(0, createdMed);
    await _saveLocalMedications(list);

    return createdMed;
  }

  Future<IntakeResponseModel> logIntake(
    String medicationId, {
    int quantity = 1,
    String? scheduledTime,
    String source = 'manual',
    DateTime? takenAt,
  }) async {
    final now = takenAt ?? DateTime.now();

    try {
      final response = await _apiClient.post(
        '${ApiConstants.medications}/$medicationId/intake',
        data: {
          'quantity': quantity,
          'scheduledTime': scheduledTime,
          'source': source,
          'takenAt': now.toIso8601String(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final model = IntakeResponseModel.fromJson(data['data'] as Map<String, dynamic>);
      
      await _recordLocalIntake(medicationId, quantity, now, scheduledTime, source);
      return model;
    } catch (_) {}

    // Offline / direct local intake handling
    await _recordLocalIntake(medicationId, quantity, now, scheduledTime, source);

    final meds = await _getLocalMedications();
    final med = meds.firstWhere(
      (m) => m.id == medicationId,
      orElse: () => MedicationModel(
        id: medicationId,
        userId: 'user',
        medicineName: 'Medicine',
        prescribedDosage: '1 dose',
        maxPrescribedIntake: 2,
        frequency: 'Daily',
        scheduleTimes: ['09:00'],
        startDate: DateTime.now(),
      ),
    );

    final history = await getIntakeHistory();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayIntakes = history.where((e) {
      if (e['medicationId'] != medicationId) return false;
      final t = DateTime.tryParse(e['takenAt']?.toString() ?? '');
      if (t == null) return false;
      return t.isAfter(todayStart) && t.isBefore(todayEnd);
    }).fold<int>(0, (sum, e) => sum + ((e['quantity'] as int?) ?? 1));

    String status = 'WITHIN_LIMIT';
    String message = 'Intake confirmed and recorded in history!';
    if (todayIntakes >= med.maxPrescribedIntake) {
      status = 'LIMIT_REACHED';
      message = 'Prescribed daily limit reached for ${med.medicineName}.';
    }

    return IntakeResponseModel(
      status: status,
      dailyIntake: todayIntakes,
      prescribedLimit: med.maxPrescribedIntake,
      message: message,
    );
  }

  Future<List<TodayIntakeItem>> getTodaySummary() async {
    try {
      final response = await _apiClient.get('${ApiConstants.intake}/today');
      final data = response.data as Map<String, dynamic>;
      final list = data['summary'] as List<dynamic>? ?? [];
      final serverSummary = list
          .map((e) => TodayIntakeItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (serverSummary.isNotEmpty) {
        return serverSummary;
      }
    } catch (_) {}

    // Compute from local medications & intake history
    final meds = await _getLocalMedications();
    if (meds.isEmpty) return [];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final history = await getIntakeHistory();

    final summary = <TodayIntakeItem>[];
    for (final med in meds) {
      final medStart = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      final medEnd = med.endDate != null
          ? DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day)
          : null;

      final isStarted = !todayStart.isBefore(medStart);
      final isNotEnded = medEnd == null || !todayStart.isAfter(medEnd);

      if (isStarted && isNotEnded) {
        final dailyCount = history.where((e) {
          if (e['medicationId'] != med.id) return false;
          final t = DateTime.tryParse(e['takenAt']?.toString() ?? '');
          if (t == null) return false;
          return t.isAfter(todayStart) && t.isBefore(todayEnd);
        }).fold<int>(0, (sum, e) => sum + ((e['quantity'] as int?) ?? 1));

        String status = 'WITHIN_LIMIT';
        if (dailyCount >= med.maxPrescribedIntake) {
          status = 'LIMIT_REACHED';
        }

        summary.add(
          TodayIntakeItem(
            medicationId: med.id,
            medicineName: med.medicineName,
            dosage: med.dosage,
            prescribedLimit: med.maxPrescribedIntake,
            dailyIntake: dailyCount,
            status: status,
          ),
        );
      }
    }

    return summary;
  }

  Future<List<Map<String, dynamic>>> getIntakeHistory() async {
    List<Map<String, dynamic>> combined = [];

    try {
      final response = await _apiClient.get(ApiConstants.intakeHistory);
      final data = response.data as Map<String, dynamic>;
      final list = data['history'] as List<dynamic>? ?? [];
      combined = list.cast<Map<String, dynamic>>();
    } catch (_) {}

    final localIntakes = await _getLocalIntakes();
    for (final l in localIntakes) {
      final exists = combined.any((c) =>
          c['medicationId'] == l['medicationId'] &&
          c['takenAt'] == l['takenAt']);
      if (!exists) {
        combined.add(l);
      }
    }

    combined.sort((a, b) {
      final tA = DateTime.tryParse(a['takenAt']?.toString() ?? '') ?? DateTime(2000);
      final tB = DateTime.tryParse(b['takenAt']?.toString() ?? '') ?? DateTime(2000);
      return tB.compareTo(tA);
    });

    return combined;
  }

  // --- Helpers for persistent local storage ---

  Future<List<MedicationModel>> _getLocalMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_localMedsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => MedicationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalMedications(List<MedicationModel> meds) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(meds.map((m) => m.toJson()).toList());
    await prefs.setString(_localMedsKey, jsonStr);
  }

  Future<List<Map<String, dynamic>>> _getLocalIntakes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_localIntakesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _recordLocalIntake(
    String medicationId,
    int quantity,
    DateTime takenAt,
    String? scheduledTime,
    String source,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getLocalIntakes();
    
    final meds = await _getLocalMedications();
    final med = meds.where((m) => m.id == medicationId).firstOrNull;

    list.insert(0, {
      'id': 'intake_${DateTime.now().millisecondsSinceEpoch}',
      'medicationId': medicationId,
      'medicineName': med?.medicineName ?? 'Medicine',
      'dosage': med?.dosage ?? '1 dose',
      'quantity': quantity,
      'takenAt': takenAt.toIso8601String(),
      'scheduledTime': scheduledTime ?? '${takenAt.hour.toString().padLeft(2, '0')}:${takenAt.minute.toString().padLeft(2, '0')}',
      'source': source,
    });

    await prefs.setString(_localIntakesKey, jsonEncode(list));
  }
}
