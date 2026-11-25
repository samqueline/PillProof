import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../history/presentation/history_controller.dart';
import '../../medications/data/medication_repository.dart';
import '../../medications/presentation/medication_controller.dart';
import '../models/active_reminder_model.dart';

class ReminderState {
  final List<ActiveReminderModel> activeReminders;
  final ActiveReminderModel? currentAlarm;
  final String? lastConfirmedMessage;

  const ReminderState({
    this.activeReminders = const [],
    this.currentAlarm,
    this.lastConfirmedMessage,
  });

  bool get hasActiveAlarm => currentAlarm != null && currentAlarm!.isAlarming;

  ReminderState copyWith({
    List<ActiveReminderModel>? activeReminders,
    ActiveReminderModel? currentAlarm,
    bool clearCurrentAlarm = false,
    String? lastConfirmedMessage,
  }) {
    return ReminderState(
      activeReminders: activeReminders ?? this.activeReminders,
      currentAlarm: clearCurrentAlarm ? null : (currentAlarm ?? this.currentAlarm),
      lastConfirmedMessage: lastConfirmedMessage ?? this.lastConfirmedMessage,
    );
  }
}

class ReminderController extends Notifier<ReminderState> {
  Timer? _ticker;

  @override
  ReminderState build() {
    _startPeriodicCheck();
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const ReminderState();
  }

  void _startPeriodicCheck() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      checkScheduledDoses();
    });
  }

  /// Scans medications and triggers alarms for doses that are due right now
  Future<void> checkScheduledDoses() async {
    try {
      final medsAsync = ref.read(medicationsListProvider);
      final meds = medsAsync.value ?? [];
      final now = DateTime.now();

      final updatedReminders = List<ActiveReminderModel>.from(state.activeReminders);
      ActiveReminderModel? newAlarm = state.currentAlarm;

      for (final med in meds) {
        if (!med.isActive) continue;

        // Check if today is within start and end date
        if (med.startDate.isAfter(now)) continue;
        if (med.endDate != null && med.endDate!.isBefore(now)) continue;

        for (final timeStr in med.scheduleTimes) {
          final parts = timeStr.split(':');
          if (parts.length != 2) continue;
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;

          final dueToday = DateTime(now.year, now.month, now.day, hour, minute);

          // If due time is within past 2 hours and hasn't been confirmed
          final reminderId = '${med.id}_${timeStr}_${now.year}_${now.month}_${now.day}';
          final existingIdx = updatedReminders.indexWhere((r) => r.id == reminderId);

          if (now.isAfter(dueToday) && now.difference(dueToday).inHours < 2) {
            if (existingIdx == -1) {
              final newReminder = ActiveReminderModel(
                id: reminderId,
                medicationId: med.id,
                medicineName: med.medicineName,
                dosage: med.dosage,
                scheduledTime: timeStr,
                dueTime: dueToday,
              );
              updatedReminders.add(newReminder);
              newAlarm ??= newReminder;
            }
          }
        }
      }

      state = state.copyWith(
        activeReminders: updatedReminders,
        currentAlarm: newAlarm,
      );
    } catch (_) {}
  }

  /// Triggers an immediate loud test alarm (demo button)
  void triggerInstantAlarm({
    String medicineName = 'Amoxicillin 500mg',
    String dosage = '1 capsule',
    String timeStr = '09:00 AM',
    String? medicationId,
  }) {
    final demoId = 'alarm_${DateTime.now().millisecondsSinceEpoch}';
    final reminder = ActiveReminderModel(
      id: demoId,
      medicationId: medicationId ?? 'demo-med',
      medicineName: medicineName,
      dosage: dosage,
      scheduledTime: timeStr,
      dueTime: DateTime.now(),
    );

    final list = List<ActiveReminderModel>.from(state.activeReminders)..add(reminder);
    state = state.copyWith(
      activeReminders: list,
      currentAlarm: reminder,
    );
  }

  /// CONFIRMS TAKEN -> IMMEDIATELY SILENCES & STOPS ALARM, LOGS TO DB
  Future<void> confirmTaken(String reminderId) async {
    final idx = state.activeReminders.indexWhere((r) => r.id == reminderId);
    ActiveReminderModel? rem;

    if (idx != -1) {
      rem = state.activeReminders[idx];
    } else if (state.currentAlarm?.id == reminderId) {
      rem = state.currentAlarm;
    }

    if (rem == null) return;

    // 1. Instantly stop & silence alarm
    final updated = List<ActiveReminderModel>.from(state.activeReminders)
      ..removeWhere((r) => r.id == reminderId);

    state = state.copyWith(
      activeReminders: updated,
      clearCurrentAlarm: true,
      lastConfirmedMessage: 'Dose confirmed! Logged ${rem.medicineName} intake.',
    );

    // 2. Persist intake event to backend database with source 'reminder'
    try {
      final repo = ref.read(medicationRepositoryProvider);
      await repo.logIntake(
        rem.medicationId,
        scheduledTime: rem.scheduledTime.contains(':') ? rem.scheduledTime : null,
        source: 'reminder',
        takenAt: DateTime.now(),
      );

      // Refresh today's summary & intake history
      ref.read(todaySummaryProvider.notifier).fetchSummary();
      ref.read(intakeHistoryProvider.notifier).refresh();
    } catch (_) {}
  }

  /// Snoozes reminder for X minutes
  void snoozeReminder(String reminderId, {int minutes = 5}) {
    final updated = state.activeReminders.map((r) {
      if (r.id == reminderId) {
        return r.copyWith(
          isSnoozed: true,
          snoozeUntil: DateTime.now().add(Duration(minutes: minutes)),
          alertCount: r.alertCount + 1,
        );
      }
      return r;
    }).toList();

    state = state.copyWith(
      activeReminders: updated,
      clearCurrentAlarm: true,
      lastConfirmedMessage: 'Reminder snoozed for $minutes minutes.',
    );
  }

  void dismissBanner() {
    state = state.copyWith(clearCurrentAlarm: true);
  }
}

final reminderControllerProvider =
    NotifierProvider<ReminderController, ReminderState>(ReminderController.new);

