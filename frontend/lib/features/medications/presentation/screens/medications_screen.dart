import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/medical_mesh_background.dart';
import '../../../history/presentation/history_controller.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(intakeHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications (History)', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'View Calendar',
            onPressed: () => context.go('/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded),
            tooltip: 'Schedule New Intake',
            onPressed: () => context.go('/schedule'),
          ),
        ],
      ),
      body: MedicalMeshBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(intakeHistoryProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Info Banner explaining this screen is for already intaken medicine history
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusVerified.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, color: AppColors.statusVerified, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Intake History Log',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Records of all medicines already intaken. To schedule upcoming doses, use "Schedule your medicine".',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              historyAsync.when(
                data: (historyList) {
                  if (historyList.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return Column(
                    children: historyList.map((item) => _buildIntakeCard(context, item)).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => _buildEmptyState(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/schedule'),
        icon: const Icon(Icons.schedule_rounded),
        label: const Text('Schedule Medicine'),
        backgroundColor: const Color(0xFF00B0FF),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildIntakeCard(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = item['medicineName']?.toString() ?? 'Medication';
    final dosage = item['dosage']?.toString() ?? item['dosageTaken']?.toString() ?? '1 dose';
    final quantity = item['quantity'] ?? 1;
    final dateStr = item['takenAt'] ?? item['timestamp'] ?? item['createdAt'];
    
    DateTime dt = DateTime.now();
    if (dateStr != null) {
      dt = DateTime.tryParse(dateStr.toString())?.toLocal() ?? DateTime.now();
    }
    final formattedDate = DateFormat('MMM d, yyyy • hh:mm a').format(dt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dosage: $dosage • Qty: $quantity',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0288D1),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'INTAKEN',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10B981),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 54, color: Colors.blueGrey.shade300),
            const SizedBox(height: 14),
            const Text(
              'No Medicine Intake History Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'When you confirm intake from "Schedule your medicine" or the calendar, it will appear here as your completed medical history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B0FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Schedule Medicine Intake', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => context.go('/schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
