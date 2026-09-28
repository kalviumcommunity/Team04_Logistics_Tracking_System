import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cfg.fg),
          ),
          SizedBox(width: large ? 6 : 4),
          Text(
            cfg.label,
            style: TextStyle(
              color: cfg.fg,
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _config(String status) {
    switch (status) {
      case 'PENDING':
        return _StatusConfig(
          bg: AppColors.warning.withValues(alpha: 0.12),
          fg: AppColors.warning,
          label: 'Pending',
        );
      case 'ASSIGNED':
        return _StatusConfig(
          bg: AppColors.primaryBlue.withValues(alpha: 0.1),
          fg: AppColors.primaryBlue,
          label: 'Assigned',
        );
      case 'IN_TRANSIT':
        return _StatusConfig(
          bg: AppColors.cyanTeal.withValues(alpha: 0.12),
          fg: const Color(0xFF0D9488),
          label: 'In Transit',
        );
      case 'DELIVERED':
        return _StatusConfig(
          bg: AppColors.success.withValues(alpha: 0.1),
          fg: AppColors.success,
          label: 'Delivered',
        );
      case 'FAILED':
        return _StatusConfig(
          bg: AppColors.error.withValues(alpha: 0.1),
          fg: AppColors.error,
          label: 'Failed',
        );
      case 'CANCELLED':
        return _StatusConfig(
          bg: const Color(0xFFF1F5F9),
          fg: AppColors.textSecondary,
          label: 'Cancelled',
        );
      case 'OPEN':
        return _StatusConfig(
          bg: AppColors.error.withValues(alpha: 0.1),
          fg: AppColors.error,
          label: 'Open',
        );
      case 'IN_PROGRESS':
        return _StatusConfig(
          bg: AppColors.warning.withValues(alpha: 0.12),
          fg: AppColors.warning,
          label: 'In Progress',
        );
      case 'RESOLVED':
        return _StatusConfig(
          bg: AppColors.success.withValues(alpha: 0.1),
          fg: AppColors.success,
          label: 'Resolved',
        );
      case 'ON_DUTY':
        return _StatusConfig(
          bg: AppColors.cyanTeal.withValues(alpha: 0.1),
          fg: AppColors.cyanTeal,
          label: 'On Duty',
        );
      case 'AVAILABLE':
        return _StatusConfig(
          bg: AppColors.success.withValues(alpha: 0.1),
          fg: AppColors.success,
          label: 'Available',
        );
      default:
        return _StatusConfig(
          bg: const Color(0xFFF1F5F9),
          fg: AppColors.textSecondary,
          label: status,
        );
    }
  }
}

class _StatusConfig {
  final Color bg;
  final Color fg;
  final String label;
  _StatusConfig({required this.bg, required this.fg, required this.label});
}
