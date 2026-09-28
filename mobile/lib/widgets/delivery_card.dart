import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/delivery_model.dart';
import 'assign_delivery_dialog.dart';
import 'status_badge.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final List<Widget>? actions;
  final bool showAssignButton;

  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
    this.onAssign,
    this.actions,
    this.showAssignButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasExecutive = delivery.assignedExecutive != null ||
        (delivery.assignedTo != null && delivery.assignedTo!.isNotEmpty);
    final execName = delivery.assignedExecutive?.fullName ??
        (hasExecutive ? 'Assigned' : 'Unassigned');
    final canAssign = delivery.status == 'PENDING' || delivery.status == 'ASSIGNED';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.trackingNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        delivery.customer?.fullName ?? delivery.recipientName ?? 'Customer',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: delivery.status),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),

            // Address row
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${delivery.deliveryAddress}, ${delivery.city}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Bottom row with Assigned To
            Row(
              children: [
                Icon(
                  hasExecutive ? Icons.person_outline : Icons.warning_amber_rounded,
                  size: 14,
                  color: hasExecutive ? AppColors.textMuted : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, fontFamily: 'sans-serif'),
                      children: [
                        const TextSpan(
                          text: 'Assigned To: ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: execName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: hasExecutive
                                ? AppColors.textPrimary
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (delivery.eta != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        delivery.eta!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Direct Assign / Reassign Button Row if enabled
            if (showAssignButton && canAssign) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (onAssign != null) {
                        onAssign!();
                      } else {
                        AssignDeliveryDialog.show(context, delivery);
                      }
                    },
                    icon: Icon(
                      hasExecutive
                          ? Icons.swap_horiz_rounded
                          : Icons.assignment_ind_rounded,
                      size: 14,
                      color: hasExecutive ? AppColors.warning : AppColors.primaryBlue,
                    ),
                    label: Text(
                      hasExecutive ? 'Reassign' : 'Assign Delivery',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasExecutive ? AppColors.warning : AppColors.primaryBlue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      side: BorderSide(
                        color: hasExecutive
                            ? AppColors.warning.withValues(alpha: 0.5)
                            : AppColors.primaryBlue.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Details →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),
              Row(children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}
