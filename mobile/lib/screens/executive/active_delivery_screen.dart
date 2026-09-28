import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import 'failure_report_screen.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? deliveryId;

  const ActiveDeliveryScreen({
    super.key,
    this.isEmbedded = false,
    this.deliveryId,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  String? _selectedDeliveryId;

  @override
  void initState() {
    super.initState();
    _selectedDeliveryId = widget.deliveryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
      }
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    await PhoneCaller.makePhoneCall(context, phoneNumber, roleLabel: 'Customer');
  }

  Future<void> _sendSms(String phoneNumber) async {
    await PhoneCaller.sendSms(context, phoneNumber, roleLabel: 'Customer');
  }

  Future<void> _launchMaps(String address, String city) async {
    final query = Uri.encodeComponent('$address, $city');
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showMarkDeliveredDialog(DeliveryModel delivery) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text('Confirm Handover',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that the recipient has received the shipment successfully.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                labelText: 'Proof of Delivery Note',
                hintText: 'e.g. Handed to customer at door',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final provider =
                  Provider.of<DeliveryProvider>(context, listen: false);
              final success = await provider.updateStatus(
                delivery.id,
                'DELIVERED',
                remarks: remarksController.text.trim().isNotEmpty
                    ? remarksController.text.trim()
                    : 'Delivered in-person by executive',
              );
              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Delivery marked as DELIVERED! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.actionError ??
                          'Failed to update delivery status.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Order',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final currentUserId = auth.user?.id;
    final allDeliveries = currentUserId != null
        ? deliveryProvider.deliveries
            .where((d) => d.assignedExecutive?.id == currentUserId)
            .toList()
        : deliveryProvider.deliveries;

    // Find active delivery
    DeliveryModel? activeDelivery;
    if (_selectedDeliveryId != null) {
      try {
        activeDelivery =
            allDeliveries.firstWhere((d) => d.id == _selectedDeliveryId);
      } catch (_) {
        activeDelivery = null;
      }
    }

    if (activeDelivery == null) {
      try {
        activeDelivery =
            allDeliveries.firstWhere((d) => d.status == 'IN_TRANSIT');
      } catch (_) {
        try {
          activeDelivery =
              allDeliveries.firstWhere((d) => d.status == 'ASSIGNED');
        } catch (_) {
          activeDelivery = null;
        }
      }
    }

    final assignedDeliveries =
        allDeliveries.where((d) => d.status == 'ASSIGNED').toList();

    final content = RefreshIndicator(
      onRefresh: () => deliveryProvider.fetchDeliveries(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeDelivery != null) ...[
              // ── Active Delivery Cockpit View ─────────────────────
              _buildLiveCockpit(activeDelivery, deliveryProvider),
            ] else ...[
              // ── No Active Delivery View ─────────────────────────
              _buildNoActiveView(assignedDeliveries, deliveryProvider),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Active Delivery Terminal',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Delivery Status',
            onPressed: () => deliveryProvider.fetchDeliveries(),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildLiveCockpit(DeliveryModel del, DeliveryProvider provider) {
    final isInTransit = del.status == 'IN_TRANSIT';
    final isAssigned = del.status == 'ASSIGNED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live GPS Banner
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.map_rounded,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isInTransit
                                    ? AppColors.cyanTeal.withValues(alpha: 0.2)
                                    : AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isInTransit
                                    ? Icons.navigation_rounded
                                    : Icons.schedule_rounded,
                                color: isInTransit
                                    ? AppColors.cyanTeal
                                    : AppColors.warning,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isInTransit
                                      ? 'LIVE IN TRANSIT'
                                      : 'ASSIGNED - AWAITING START',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isInTransit
                                        ? AppColors.cyanTeal
                                        : AppColors.warning,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  del.trackingNumber,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        StatusBadge(status: del.status),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DESTINATION',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white54),
                            ),
                            Text(
                              '${del.deliveryAddress}, ${del.city}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ETA: ${del.eta ?? "25m"}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Quick Navigation & Call Action Bar ─────────────────────
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _launchMaps(del.deliveryAddress, del.city),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Open Maps Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: () => _makePhoneCall(del.customer?.phone ?? ''),
              icon: const Icon(Icons.phone_rounded,
                  color: AppColors.primaryBlue),
              tooltip: 'Call Customer',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _sendSms(del.customer?.phone ?? ''),
              icon: const Icon(Icons.sms_rounded,
                  color: AppColors.darkNavy),
              tooltip: 'Send SMS',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Delivery Milestones Stepper ────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Route Progression',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 16),
              _buildProgressStep(
                title: 'Order Assigned to Executive',
                subtitle: 'Assigned to your queue',
                isCompleted: true,
                isCurrent: isAssigned,
              ),
              _buildProgressStep(
                title: 'In Transit / On Route',
                subtitle: 'Package in courier possession',
                isCompleted: isInTransit || del.status == 'DELIVERED',
                isCurrent: isInTransit,
              ),
              _buildProgressStep(
                title: 'Delivered & Handed Over',
                subtitle: 'Final recipient confirmation',
                isCompleted: del.status == 'DELIVERED',
                isCurrent: false,
                isLast: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Customer & Order Card ────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.person,
                        color: AppColors.primaryBlue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          del.customer?.fullName ?? 'Recipient Name',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        Text(
                          (del.customer?.phone.isNotEmpty == true)
                              ? del.customer!.phone
                              : 'Phone not available',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              _infoRow('Pickup Hub', del.pickupAddress),
              const SizedBox(height: 6),
              _infoRow('Dropoff Address',
                  '${del.deliveryAddress}, ${del.city}'),
              if (del.remarks != null && del.remarks!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow('Dispatcher Note', del.remarks!),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Action Buttons Bar ────────────────────────────────────
        if (isAssigned)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final success = await provider.updateStatus(
                  del.id,
                  'IN_TRANSIT',
                  remarks: 'Delivery started by field executive',
                );
                if (mounted) {
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Delivery route active! Now in transit.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(provider.actionError ??
                            'Failed to start delivery.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Start Delivery Route (Go In Transit)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          )
        else if (isInTransit)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FailureReportScreen(delivery: del),
                      ),
                    ).then((_) => provider.fetchDeliveries());
                  },
                  icon: const Icon(Icons.report_problem_rounded, size: 16),
                  label: const Text('Report Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _showMarkDeliveredDialog(del),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Mark Delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProgressStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    Color dotColor = AppColors.border;
    if (isCompleted) dotColor = AppColors.success;
    if (isCurrent) dotColor = AppColors.primaryBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 11)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted
                    ? AppColors.success
                    : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent || isCompleted
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isCurrent
                        ? AppColors.primaryBlue
                        : isCompleted
                            ? AppColors.darkNavy
                            : AppColors.textSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveView(
      List<DeliveryModel> assigned, DeliveryProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.done_all_rounded,
                size: 40, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Delivery In-Transit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are not currently delivering an active shipment. Pick an assigned shipment below to begin your route.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (assigned.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Assigned Shipments Ready for Route:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy),
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assigned.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, idx) {
                final del = assigned[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              del.trackingNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.primaryBlue),
                            ),
                            Text(
                              del.customer?.fullName ?? 'Customer',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkNavy),
                            ),
                            Text(
                              '📍 ${del.deliveryAddress}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await provider.updateStatus(
                            del.id,
                            'IN_TRANSIT',
                            remarks: 'Executive started delivery route',
                          );
                          if (mounted) {
                            if (success) {
                              setState(() {
                                _selectedDeliveryId = del.id;
                              });
                              messenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Delivery started! Now in transit.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Start',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => provider.fetchDeliveries(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Check for New Assignments'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
