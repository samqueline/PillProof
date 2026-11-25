class ActiveReminderModel {
  final String id;
  final String medicationId;
  final String medicineName;
  final String dosage;
  final String scheduledTime;
  final DateTime dueTime;
  final bool isConfirmedTaken;
  final bool isSnoozed;
  final DateTime? snoozeUntil;
  final int alertCount;

  const ActiveReminderModel({
    required this.id,
    required this.medicationId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    required this.dueTime,
    this.isConfirmedTaken = false,
    this.isSnoozed = false,
    this.snoozeUntil,
    this.alertCount = 1,
  });

  bool get isAlarming {
    if (isConfirmedTaken) return false;
    if (isSnoozed && snoozeUntil != null && DateTime.now().isBefore(snoozeUntil!)) {
      return false;
    }
    return true;
  }

  ActiveReminderModel copyWith({
    bool? isConfirmedTaken,
    bool? isSnoozed,
    DateTime? snoozeUntil,
    int? alertCount,
  }) {
    return ActiveReminderModel(
      id: id,
      medicationId: medicationId,
      medicineName: medicineName,
      dosage: dosage,
      scheduledTime: scheduledTime,
      dueTime: dueTime,
      isConfirmedTaken: isConfirmedTaken ?? this.isConfirmedTaken,
      isSnoozed: isSnoozed ?? this.isSnoozed,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      alertCount: alertCount ?? this.alertCount,
    );
  }
}

