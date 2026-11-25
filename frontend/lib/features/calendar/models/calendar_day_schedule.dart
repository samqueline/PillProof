enum CalendarDayStatus {
  completed,
  partiallyTaken,
  missed,
  scheduledFuture,
  rest,
}

class ScheduledDoseItem {
  final String medicationId;
  final String medicineName;
  final String dosage;
  final String scheduledTime;
  final bool isTaken;
  final DateTime? takenAt;

  const ScheduledDoseItem({
    required this.medicationId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.isTaken = false,
    this.takenAt,
  });

  ScheduledDoseItem copyWith({
    bool? isTaken,
    DateTime? takenAt,
  }) {
    return ScheduledDoseItem(
      medicationId: medicationId,
      medicineName: medicineName,
      dosage: dosage,
      scheduledTime: scheduledTime,
      isTaken: isTaken ?? this.isTaken,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}

class CalendarDaySchedule {
  final DateTime date;
  final List<Map<String, dynamic>> takenEvents;
  final List<ScheduledDoseItem> scheduledDoses;

  const CalendarDaySchedule({
    required this.date,
    this.takenEvents = const [],
    this.scheduledDoses = const [],
  });

  int get totalTakenDoses =>
      takenEvents.fold(0, (sum, e) => sum + ((e['quantity'] as int?) ?? 1));

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  CalendarDayStatus get status {
    if (takenEvents.isNotEmpty) {
      if (scheduledDoses.isNotEmpty &&
          takenEvents.length < scheduledDoses.length &&
          !isToday) {
        return CalendarDayStatus.partiallyTaken;
      }
      return CalendarDayStatus.completed;
    }

    if (isPast && scheduledDoses.isNotEmpty) {
      return CalendarDayStatus.missed;
    }

    if ((isFuture || isToday) && scheduledDoses.isNotEmpty) {
      return CalendarDayStatus.scheduledFuture;
    }

    return CalendarDayStatus.rest;
  }
}

