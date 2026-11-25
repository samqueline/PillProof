import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/medical_mesh_background.dart';
import '../../../../shared/widgets/pillwise_floating_button.dart';
import '../../../calendar/presentation/calendar_controller.dart';
import '../../../history/presentation/history_controller.dart';
import '../../../medications/data/medication_repository.dart';
import '../../../medications/presentation/medication_controller.dart';
import '../../../ocr/models/medicine_ocr_result.dart';
import '../../../ocr/presentation/screens/tablet_cover_ocr_screen.dart';
import '../../../reminders/presentation/widgets/active_alarm_banner.dart';
import '../../../scanner/models/scan_result.dart';
import '../../../scanner/presentation/screens/qr_camera_scanner_screen.dart';

class DailyScheduleScreen extends ConsumerWidget {
  const DailyScheduleScreen({super.key});

  void _showAddScheduleDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController(text: 'Daily');
    final limitController = TextEditingController(text: '2');
    final timesController = TextEditingController(text: '09:00, 21:00');
    final durationController = TextEditingController(text: '7');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Schedule Your Medicine',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set up your intake timing and course duration. This will appear on your Calendar and Daily Schedule.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Quick Camera Assistant
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00B0FF),
                              side: const BorderSide(color: Color(0xFF00B0FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Read Cover (OCR)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final result = await Navigator.of(context).push<MedicineOcrResult>(
                                MaterialPageRoute(
                                  builder: (_) => const TabletCoverOcrScreen(title: 'Read Tablet Packaging'),
                                ),
                              );
                              if (result != null) {
                                nameController.text = result.formattedDisplayName;
                                if (result.detectedDosage != null && result.detectedDosage!.isNotEmpty) {
                                  dosageController.text = result.detectedDosage!;
                                }
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0288D1),
                              side: const BorderSide(color: Color(0xFF0288D1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                            label: const Text('Scan QR / Barcode', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final result = await Navigator.of(context).push<ScanResult>(
                                MaterialPageRoute(
                                  builder: (_) => const QrCameraScannerScreen(
                                    title: 'Scan QR Code',
                                    hintText: 'Align medicine packaging QR code',
                                  ),
                                ),
                              );
                              if (result != null) {
                                nameController.text = result.medicineName ?? result.barcode;
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Medicine Name *',
                        hintText: 'e.g., Amoxicillin 500mg',
                        prefixIcon: const Icon(Icons.medication_rounded, color: Color(0xFF0288D1)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dosageController,
                      decoration: InputDecoration(
                        labelText: 'Dosage Amount *',
                        hintText: 'e.g., 1 Capsule or 500mg',
                        prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF0288D1)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: frequencyController,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        hintText: 'e.g., Twice daily',
                        prefixIcon: const Icon(Icons.repeat_rounded, color: Color(0xFF0288D1)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timesController,
                      decoration: InputDecoration(
                        labelText: 'Intake Times (comma separated)',
                        hintText: 'e.g., 09:00, 21:00',
                        prefixIcon: const Icon(Icons.access_time_rounded, color: Color(0xFF0288D1)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: limitController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Daily Ceiling',
                              hintText: 'e.g., 2',
                              prefixIcon: const Icon(Icons.speed_rounded, color: Color(0xFF0288D1)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Days Duration',
                              hintText: 'e.g., 7',
                              prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0288D1)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B0FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Save to Schedule & Calendar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final dosage = dosageController.text.trim();
                        final freq = frequencyController.text.trim();
                        final limit = int.tryParse(limitController.text.trim()) ?? 1;
                        final durationDays = int.tryParse(durationController.text.trim());
                        final startDate = DateTime.now();
                        final endDate = durationDays != null && durationDays > 0
                            ? startDate.add(Duration(days: durationDays))
                            : null;

                        final times = timesController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        if (name.isEmpty || dosage.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter Medicine Name and Dosage')),
                          );
                          return;
                        }

                        await ref.read(medicationsListProvider.notifier).addMedication(
                              name: name,
                              dosage: dosage,
                              frequency: freq,
                              limit: limit,
                              times: times.isNotEmpty ? times : ['09:00', '21:00'],
                              startDate: startDate,
                              endDate: endDate,
                            );

                        await ref.read(todaySummaryProvider.notifier).fetchSummary();
                        ref.read(calendarControllerProvider.notifier).refresh();

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Scheduled "$name" for $durationDays days on your Calendar!'),
                              backgroundColor: AppColors.statusVerified,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySummaryAsync = ref.watch(todaySummaryProvider);

    return Scaffold(
      body: MedicalMeshBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header with Top-Left Profile Icon & Back Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.go('/dashboard'),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00B0FF), Color(0xFF0288D1)],
                                  ),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0288D1).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF01579B), size: 20),
                              tooltip: 'Back to Dashboard',
                              onPressed: () => context.go('/dashboard'),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF01579B)),
                              icon: const Icon(Icons.calendar_month_rounded, size: 20),
                              label: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => context.go('/calendar'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Persistent Alarm Reminder Banner
                    const ActiveAlarmBanner(),

                    const SizedBox(height: 12),

                    // 2. Title Row with Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today’s medication:',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D47A1),
                            letterSpacing: 0.2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF00B0FF), size: 34),
                          tooltip: 'Schedule New Medicine',
                          onPressed: () => _showAddScheduleDialog(context, ref),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 3. Vertical list stack of wide, rounded pill-shaped containers
                    Expanded(
                      child: todaySummaryAsync.when(
                        data: (summaryList) {
                          if (summaryList.isEmpty) {
                            return _buildEmptySchedule(context, ref);
                          }

                          return ListView.builder(
                            itemCount: summaryList.length,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemBuilder: (context, index) {
                              final item = summaryList[index];
                              return _DailyMedicationPillCard(
                                item: item,
                                index: index,
                                onTakePressed: () async {
                                  await ref.read(todaySummaryProvider.notifier).recordIntake(item.medicationId);
                                  ref.read(todaySummaryProvider.notifier).fetchSummary();
                                  ref.read(intakeHistoryProvider.notifier).refresh();
                                  ref.read(calendarControllerProvider.notifier).refresh();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Dose intaken for ${item.medicineName}! Logged to history and calendar.'),
                                        backgroundColor: AppColors.statusVerified,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => _buildEmptySchedule(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-right floating PILLWISE button
            const PillwiseFloatingButton(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule Medicine'),
        backgroundColor: const Color(0xFF00B0FF),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptySchedule(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 52, color: Colors.blueGrey.shade300),
            const SizedBox(height: 14),
            const Text(
              'No Scheduled Medications for Today',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to schedule your medicines. They will immediately appear on your calendar and daily schedule!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B0FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Schedule Your Medicine Now', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showAddScheduleDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide, rounded pill-shaped container with semi-transparent light sky-blue background
class _DailyMedicationPillCard extends StatelessWidget {
  final dynamic item;
  final int index;
  final VoidCallback onTakePressed;

  const _DailyMedicationPillCard({
    required this.item,
    required this.index,
    required this.onTakePressed,
  });

  @override
  Widget build(BuildContext context) {
    String name = 'Medication #${index + 1}';
    String dosage = '1 dose';
    String time = '${8 + index * 4}:00 ${index < 2 ? 'AM' : 'PM'}';
    bool isTaken = false;

    if (item is TodayIntakeItem) {
      final TodayIntakeItem todayItem = item as TodayIntakeItem;
      name = todayItem.medicineName;
      dosage = todayItem.dosage;
      isTaken = todayItem.dailyIntake > 0;
    } else if (item is Map) {
      final Map mapItem = item as Map;
      name = (mapItem['medicineName'] ?? name).toString();
      dosage = (mapItem['dosage'] ?? dosage).toString();
      time = (mapItem['scheduledTime'] ?? time).toString();
      isTaken = mapItem['isTaken'] == true || (mapItem['takenToday'] != null && (mapItem['takenToday'] as int) > 0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF90CAF9).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Indicator icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isTaken
                  ? const Color(0xFF10B981)
                  : const Color(0xFF0288D1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTaken ? Icons.check_rounded : Icons.schedule_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),

          // Medicine Name & Dosage Info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dose: $dosage • ${isTaken ? 'Intaken' : 'Due today'}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Action: Take button or Taken check
          if (!isTaken)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B0FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: onTakePressed,
              child: const Text(
                'Take',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 26,
            ),
        ],
      ),
    );
  }
}
