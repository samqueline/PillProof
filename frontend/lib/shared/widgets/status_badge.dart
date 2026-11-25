import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum VerificationStatus {
  verified,
  reviewRecommended,
  unverified,
  expired,
  warning,
}

class StatusBadge extends StatelessWidget {
  final VerificationStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _getStatusConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            customLabel ?? label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _getStatusConfig() {
    switch (status) {
      case VerificationStatus.verified:
        return ('VERIFIED', AppColors.statusVerified, Icons.verified_rounded);
      case VerificationStatus.reviewRecommended:
        return ('REVIEW RECOMMENDED', AppColors.statusReview, Icons.warning_amber_rounded);
      case VerificationStatus.unverified:
        return ('UNVERIFIED', AppColors.statusExpired, Icons.help_outline_rounded);
      case VerificationStatus.expired:
        return ('EXPIRED', AppColors.statusExpired, Icons.error_outline_rounded);
      case VerificationStatus.warning:
        return ('LIMIT WARNING', AppColors.statusWarning, Icons.notification_important_rounded);
    }
  }
}
