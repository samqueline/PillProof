class MedicationModel {
  final String id;
  final String userId;
  final String medicineName;
  final String prescribedDosage;
  final int maxPrescribedIntake;
  final String frequency;
  final List<String> scheduleTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;

  String get dosage => prescribedDosage;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.prescribedDosage,
    required this.maxPrescribedIntake,
    required this.frequency,
    required this.scheduleTimes,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      prescribedDosage: json['prescribedDosage'] ?? '',
      maxPrescribedIntake: json['maxPrescribedIntake'] is int
          ? json['maxPrescribedIntake']
          : int.tryParse(json['maxPrescribedIntake']?.toString() ?? '1') ?? 1,
      frequency: json['frequency'] ?? 'daily',
      scheduleTimes: (json['scheduleTimes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'medicineName': medicineName,
      'prescribedDosage': prescribedDosage,
      'maxPrescribedIntake': maxPrescribedIntake,
      'frequency': frequency,
      'scheduleTimes': scheduleTimes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
    };
  }
}
