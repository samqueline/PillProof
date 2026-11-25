import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../medications/presentation/medication_controller.dart';
import '../../../reminders/presentation/reminder_controller.dart';
import '../../../reminders/presentation/widgets/active_alarm_banner.dart';
import '../../models/calendar_day_schedule.dart';
import '../calendar_controller.dart';

class MedicineCalendarScreen extends ConsumerWidget {
  const MedicineCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarControllerProvider);
    final selectedSchedule = calendarState.selectedDaySchedule;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monthTitle = DateFormat('MMMM yyyy').format(calendarState.displayedMonth);
    final selectedDateStr = DateFormat('EEEE, MMMM d, yyyy').format(calendarState.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => ref.read(calendarControllerProvider.notifier).jumpToToday(),
          ),
          IconButton(
            icon: const Icon(Icons.alarm_add_rounded),
            tooltip: 'Test Dose Reminder Alarm',
            onPressed: () {
              ref.read(reminderControllerProvider.notifier).triggerInstantAlarm(
                medicineName: 'Amoxicillin 500mg',
                dosage: '1 capsule',
                timeStr: 'Due Now',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Triggered test dose reminder alarm!'),
                  backgroundColor: AppColors.statusExpired,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Persistent Alarm Banner (if currently alarming)
            const ActiveAlarmBanner(),

            // Calendar Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () =>
                            ref.read(calendarControllerProvider.notifier).changeMonth(-1),
                      ),
                      Text(
                        monthTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () =>
                            ref.read(calendarControllerProvider.notifier).changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Weekday Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _WeekdayLabel('Sun'),
                      _WeekdayLabel('Mon'),
                      _WeekdayLabel('Tue'),
                      _WeekdayLabel('Wed'),
                      _WeekdayLabel('Thu'),
                      _WeekdayLabel('Fri'),
                      _WeekdayLabel('Sat'),
                    ],
                  ),
                  const Divider(height: 16),

                  // Month Days Grid
                  _buildMonthGrid(context, ref, calendarState, isDark),

                  const SizedBox(height: 12),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(AppColors.statusVerified, 'Taken'),
                      const SizedBox(width: 14),
                      _buildLegendItem(AppColors.primary, 'Scheduled'),
                      const SizedBox(width: 14),
                      _buildLegendItem(AppColors.statusExpired, 'Missed'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Selected Day Detail Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDateStr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedSchedule.isToday
                                ? 'Today • Tracking Doses'
                                : selectedSchedule.isFuture
                                    ? 'Future Schedule • Upcoming'
                                    : 'Past Day • Intake History',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      _buildDayStatusBadge(selectedSchedule.status),
                    ],
                  ),
                  const Divider(height: 24),

                  // 1. Taken Doses (Actual Database Records)
                  if (selectedSchedule.takenEvents.isNotEmpty) ...[
                    const Text(
                      'Recorded Doses Taken:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    ...selectedSchedule.takenEvents.map((e) {
                      final name = e['medicineName'] ?? 'Medication';
                      final qty = e['quantity'] ?? 1;
                      final takenStr = e['takenAt'] ?? e['createdAt'];
                      String timeFormatted = 'Logged';
                      if (takenStr != null) {
                        try {
                          final dt = DateTime.parse(takenStr.toString()).toLocal();
                          timeFormatted = DateFormat('h:mm a').format(dt);
                        } catch (_) {}
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusVerified.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.statusVerified.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.statusVerified, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$name ($qty dose)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Text(
                              timeFormatted,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // 2. Scheduled Doses (Future or Today)
                  if (selectedSchedule.scheduledDoses.isNotEmpty) ...[
                    Text(
                      selectedSchedule.isFuture ? 'Scheduled Future Doses:' : 'Daily Schedule Requirements:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    ...selectedSchedule.scheduledDoses.map((dose) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dose.isTaken
                              ? Colors.grey.withValues(alpha: 0.08)
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: dose.isTaken
                                ? Colors.grey.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              dose.isTaken ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                              color: dose.isTaken ? Colors.grey : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dose.medicineName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      decoration: dose.isTaken ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    'Dose: ${dose.dosage} • Time: ${dose.scheduledTime}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedSchedule.isToday && !dose.isTaken)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  await ref.read(todaySummaryProvider.notifier).recordIntake(dose.medicationId);
                                  ref.read(calendarControllerProvider.notifier).jumpToToday();
                                },
                                child: const Text('Take Now', style: TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],

                  if (selectedSchedule.takenEvents.isEmpty && selectedSchedule.scheduledDoses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            Icon(Icons.event_available_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No doses recorded or scheduled for this date.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    WidgetRef ref,
    CalendarState calendarState,
    bool isDark,
  ) {
    final monthStart = calendarState.displayedMonth;
    final firstWeekday = monthStart.weekday % 7; // Sunday = 0
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;

    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNumber = cellIndex - firstWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 38, height: 44);
              }

              final cellDate = DateTime(monthStart.year, monthStart.month, dayNumber);
              final isSelected = cellDate.year == calendarState.selectedDate.year &&
                  cellDate.month == calendarState.selectedDate.month &&
                  cellDate.day == calendarState.selectedDate.day;

              final now = DateTime.now();
              final isToday = cellDate.year == now.year &&
                  cellDate.month == now.month &&
                  cellDate.day == now.day;

              final key = CalendarState.dateKey(cellDate);
              final daySchedule = calendarState.daysMap[key];
              final status = daySchedule?.status ?? CalendarDayStatus.rest;

              return InkWell(
                onTap: () =>
                    ref.read(calendarControllerProvider.notifier).selectDate(cellDate),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _buildStatusIndicatorDot(status, isSelected),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildStatusIndicatorDot(CalendarDayStatus status, bool isSelected) {
    Color dotColor;
    switch (status) {
      case CalendarDayStatus.completed:
        dotColor = isSelected ? Colors.white : AppColors.statusVerified;
        break;
      case CalendarDayStatus.partiallyTaken:
      case CalendarDayStatus.scheduledFuture:
        dotColor = isSelected ? Colors.white70 : AppColors.primary;
        break;
      case CalendarDayStatus.missed:
        dotColor = isSelected ? Colors.white70 : AppColors.statusExpired;
        break;
      case CalendarDayStatus.rest:
      default:
        dotColor = Colors.transparent;
        break;
    }

    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDayStatusBadge(CalendarDayStatus status) {
    switch (status) {
      case CalendarDayStatus.completed:
        return const StatusBadge(status: VerificationStatus.verified);
      case CalendarDayStatus.scheduledFuture:
        return const StatusBadge(status: VerificationStatus.reviewRecommended);
      case CalendarDayStatus.missed:
        return const StatusBadge(status: VerificationStatus.expired);
      case CalendarDayStatus.partiallyTaken:
      case CalendarDayStatus.rest:
      default:
        return const StatusBadge(status: VerificationStatus.unverified);
    }
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

