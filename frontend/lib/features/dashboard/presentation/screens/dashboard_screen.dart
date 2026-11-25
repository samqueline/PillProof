import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/medical_mesh_background.dart';
import '../../../../shared/widgets/pillwise_floating_button.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../reminders/presentation/widgets/active_alarm_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user?.name ?? 'User';

    return Scaffold(
      body: MedicalMeshBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Header with Cyan Circular Profile Avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showProfileDialog(context, ref, userName);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00B0FF), Color(0xFF0288D1)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0288D1).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        // Quick actions
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF01579B), size: 26),
                              tooltip: 'Calendar & Monthly Log',
                              onPressed: () => context.go('/calendar'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.history_rounded, color: Color(0xFF01579B), size: 26),
                              tooltip: 'Verification History',
                              onPressed: () => context.go('/history'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Persistent Alarm Reminder Banner (silences only after confirming dose)
                    const ActiveAlarmBanner(),

                    const Spacer(flex: 1),

                    // 2. Central Layout Grid containing the 3 Feature Cards (Image 3)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top Row: 2 Cards (Verify Medicine & My Medications)
                            Row(
                              children: [
                                // Top-Left: Verify Medicine
                                Expanded(
                                  child: _DashboardMenuCard(
                                    title: 'Verify\nMedicine',
                                    iconWidget: _buildVerifyMedicineIcon(),
                                    onTap: () => context.go('/verify'),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                // Top-Right: My Medications
                                Expanded(
                                  child: _DashboardMenuCard(
                                    title: 'My\nMedications',
                                    iconWidget: _buildMyMedicationsIcon(),
                                    onTap: () => context.go('/medications'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // Bottom Center: Schedule your medicine
                            SizedBox(
                              width: 175,
                              child: _DashboardMenuCard(
                                title: 'Schedule\nyour\nmedicine',
                                iconWidget: _buildScheduleMedicineIcon(),
                                onTap: () => context.go('/schedule'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),

            // Bottom-right floating PILLWISE button (Image 3)
            const PillwiseFloatingButton(),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.account_circle, color: Color(0xFF0288D1), size: 30),
            const SizedBox(width: 10),
            Text(userName),
          ],
        ),
        content: const Text('Logged in to Pill Proof. All verification logs and schedules are synced.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Log Out'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  // Vector graphics matching the exact icons from Image 3:
  static Widget _buildVerifyMedicineIcon() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 44, color: Colors.black87),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.medication_rounded, size: 20, color: Color(0xFF00B0FF)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMyMedicationsIcon() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            bottom: 4,
            child: Icon(Icons.vaccines_rounded, size: 36, color: Colors.orange.shade700),
          ),
          Positioned(
            right: 4,
            bottom: 8,
            child: Icon(Icons.medication_liquid_rounded, size: 32, color: Colors.amber.shade600),
          ),
        ],
      ),
    );
  }

  static Widget _buildScheduleMedicineIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.calendar_month_rounded,
        size: 38,
        color: Color(0xFF00B0FF), // Bright Cyan/Blue Calendar
      ),
    );
  }
}

/// Semi-transparent Light Blue Menu Card as styled in Image 3
class _DashboardMenuCard extends StatelessWidget {
  final String title;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _DashboardMenuCard({
    required this.title,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 148,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF90CAF9).withValues(alpha: 0.45), // Light blue semi-transparent
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  color: Color(0xFF0D47A1), // Bold dark blue text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
