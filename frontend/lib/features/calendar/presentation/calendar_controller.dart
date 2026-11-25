import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../history/presentation/history_controller.dart';
import '../../medications/presentation/medication_controller.dart';
import '../models/calendar_day_schedule.dart';

class CalendarState {
  final DateTime selectedDate;
  final DateTime displayedMonth;
  final Map<String, CalendarDaySchedule> daysMap;

  const CalendarState({
    required this.selectedDate,
    required this.displayedMonth,
    this.daysMap = const {},
  });

  CalendarDaySchedule get selectedDaySchedule {
    final key = dateKey(selectedDate);
    return daysMap[key] ?? CalendarDaySchedule(date: selectedDate);
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _dateKey(DateTime d) => dateKey(d);

  CalendarState copyWith({
    DateTime? selectedDate,
    DateTime? displayedMonth,
    Map<String, CalendarDaySchedule>? daysMap,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      displayedMonth: displayedMonth ?? this.displayedMonth,
      daysMap: daysMap ?? this.daysMap,
    );
  }
}

class CalendarController extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final state = CalendarState(
      selectedDate: today,
      displayedMonth: DateTime(now.year, now.month, 1),
    );

    // Initial build of calendar data
    return _computeCalendarData(state);
  }

  void refresh() {
    state = _computeCalendarData(state);
  }

  void selectDate(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    state = state.copyWith(selectedDate: cleanDate);
  }

  void changeMonth(int monthDelta) {
    final current = state.displayedMonth;
    final nextMonth = DateTime(current.year, current.month + monthDelta, 1);
    final updated = state.copyWith(displayedMonth: nextMonth);
    state = _computeCalendarData(updated);
  }

  void jumpToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final updated = state.copyWith(
      selectedDate: today,
      displayedMonth: DateTime(now.year, now.month, 1),
    );
    state = _computeCalendarData(updated);
  }

  CalendarState _computeCalendarData(CalendarState currentState) {
    // Listen to changes so calendar automatically refreshes when medications or intake history change
    final historyAsync = ref.watch(intakeHistoryProvider);
    final medsAsync = ref.watch(medicationsListProvider);

    final intakeList = historyAsync.value ?? [];
    final medsList = medsAsync.value ?? [];

    final map = <String, CalendarDaySchedule>{};

    // 1. Group past intake events by date
    final intakesByDate = <String, List<Map<String, dynamic>>>{};
    for (final item in intakeList) {
      final dateStr = item['takenAt'] ?? item['createdAt'];
      if (dateStr != null) {
        try {
          final dt = DateTime.parse(dateStr.toString()).toLocal();
          final key = CalendarState._dateKey(dt);
          intakesByDate.putIfAbsent(key, () => []).add(item);
        } catch (_) {}
      }
    }

    // 2. Compute schedules for the displayed month (-7 to +38 days for calendar padding)
    final monthStart = currentState.displayedMonth;
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDay = DateTime(monthStart.year, monthStart.month, day);
      final key = CalendarState._dateKey(currentDay);

      final dayIntakes = intakesByDate[key] ?? [];
      final scheduledDoses = <ScheduledDoseItem>[];

      // Check which medications are scheduled for this date
      for (final med in medsList) {
        if (!med.isActive) continue;

        final medStart = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
        final medEnd = med.endDate != null
            ? DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day)
            : null;

        // Is currentDay within medication treatment window?
        final isStarted = !currentDay.isBefore(medStart);
        final isNotEnded = medEnd == null || !currentDay.isAfter(medEnd);

        if (isStarted && isNotEnded) {
          final times = med.scheduleTimes.isNotEmpty ? med.scheduleTimes : ['09:00', '21:00'];
          for (final t in times) {
            // Check if intake was already logged for this medication & day
            final isTaken = dayIntakes.any((intake) =>
                (intake['medicationId']?.toString() == med.id) ||
                (intake['medicineName']?.toString().toLowerCase() == med.medicineName.toLowerCase()));

            scheduledDoses.add(
              ScheduledDoseItem(
                medicationId: med.id,
                medicineName: med.medicineName,
                dosage: med.dosage,
                scheduledTime: t,
                isTaken: isTaken,
              ),
            );
          }
        }
      }

      map[key] = CalendarDaySchedule(
        date: currentDay,
        takenEvents: dayIntakes,
        scheduledDoses: scheduledDoses,
      );
    }

    return currentState.copyWith(daysMap: map);
  }
}

final calendarControllerProvider =
    NotifierProvider<CalendarController, CalendarState>(CalendarController.new);

