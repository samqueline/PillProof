import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../calendar/presentation/screens/medicine_calendar_screen.dart';
import '../history_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Calendar'),
            Tab(icon: Icon(Icons.medication_rounded), text: 'Intake Logs'),
            Tab(icon: Icon(Icons.verified_outlined), text: 'Verification'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const MedicineCalendarScreen(),
          _IntakeHistoryTab(),
          _VerificationHistoryTab(),
        ],
      ),
    );
  }
}

class _IntakeHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakeAsync = ref.watch(intakeHistoryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(intakeHistoryProvider.notifier).refresh(),
      child: intakeAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No intake records yet.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Record doses on the dashboard or medications screen to see your history here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final item = items[idx];
              final medName = item['medicineName'] ?? 'Medication';
              final quantity = item['quantity'] ?? 1;
              final takenAtStr = item['takenAt'] ?? item['createdAt'];
              String formattedDate = 'Recently';
              if (takenAtStr != null) {
                try {
                  final dt = DateTime.parse(takenAtStr.toString()).toLocal();
                  formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(dt);
                } catch (_) {}
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withAlpha(51)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dose: $quantity unit(s) • $formattedDate',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const StatusBadge(status: VerificationStatus.verified),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.statusExpired, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load history: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(intakeHistoryProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifAsync = ref.watch(verificationHistoryProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(verificationHistoryProvider.notifier).refresh(),
      child: verifAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No verification records yet.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Scan or enter medicine details to verify them and view past logs here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final item = items[idx];
              final input = item['medicineInput'] as Map<String, dynamic>? ?? {};
              final name = input['name'] ?? input['barcode'] ?? 'Medicine Search';
              final batch = input['batchNumber'] ?? '';
              final result = (item['result'] ?? 'unverified').toString();

              final createdAtStr = item['createdAt'];
              String formattedDate = 'Recently';
              if (createdAtStr != null) {
                try {
                  final dt = DateTime.parse(createdAtStr.toString()).toLocal();
                  formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(dt);
                } catch (_) {}
              }

              VerificationStatus badgeStatus;
              if (result == 'verified') {
                badgeStatus = VerificationStatus.verified;
              } else if (result == 'expired') {
                badgeStatus = VerificationStatus.expired;
              } else if (result == 'review_recommended') {
                badgeStatus = VerificationStatus.warning;
              } else {
                badgeStatus = VerificationStatus.unverified;
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withAlpha(51)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_rounded,
                            color: Colors.grey, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${batch.isNotEmpty ? "Batch: $batch • " : ""}$formattedDate',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: badgeStatus),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.statusExpired, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load logs: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(verificationHistoryProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
