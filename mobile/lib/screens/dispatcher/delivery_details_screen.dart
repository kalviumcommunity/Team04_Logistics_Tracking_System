import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/assign_delivery_dialog.dart';
import 'edit_delivery_screen.dart';
import 'delivery_tracking_screen.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final String deliveryId;
  final DeliveryModel? initialDelivery;

  const DeliveryDetailsScreen({
    super.key,
    required this.deliveryId,
    this.initialDelivery,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  DeliveryModel? _delivery;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _delivery = widget.initialDelivery;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    final del = await provider.getDeliveryDetails(widget.deliveryId);

    if (!mounted) return;

    if (del != null) {
      setState(() {
        _delivery = del;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = provider.actionError ?? 'Delivery details not found.';
      });
    }
  }

  void _copyTrackingNumber(String tracking) {
    Clipboard.setData(ClipboardData(text: tracking));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Tracking number $tracking copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.darkNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStatusUpdateDialog() {
    if (_delivery == null) return;
    final currentStatus = _delivery!.status;

    // Available transitions based on backend state machine
    List<String> nextStatuses = [];
    if (currentStatus == 'PENDING') {
      nextStatuses = ['ASSIGNED', 'CANCELLED'];
    } else if (currentStatus == 'ASSIGNED') {
      nextStatuses = ['IN_TRANSIT', 'CANCELLED'];
    } else if (currentStatus == 'IN_TRANSIT') {
      nextStatuses = ['DELIVERED', 'FAILED'];
    } else if (currentStatus == 'FAILED') {
      nextStatuses = ['IN_TRANSIT', 'CANCELLED'];
    }

    if (nextStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No further status transitions allowed for "$currentStatus".'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String selectedNext = nextStatuses.first;
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_road_rounded,
                  color: AppColors.primaryBlue, size: 22),
              SizedBox(width: 8),
              Text('Update Delivery Status',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.darkNavy)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Next Status Transition:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedNext,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: nextStatuses.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedNext = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(
                  labelText: 'Remarks / Milestone Note',
                  hintText: 'e.g. Package arrived at distribution hub',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
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
                  _delivery!.id,
                  selectedNext,
                  remarks: remarksController.text.trim().isNotEmpty
                      ? remarksController.text.trim()
                      : null,
                );
                if (mounted) {
                  if (success) {
                    _loadDetails();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            'Status updated to ${selectedNext.replaceAll('_', ' ')}'),
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
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm Update',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel() {
    if (_delivery == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Cancellation',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.darkNavy)),
        content: Text(
          'Are you sure you want to cancel delivery order ${_delivery!.trackingNumber}?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider =
                  Provider.of<DeliveryProvider>(context, listen: false);
              final ok = await provider.cancelDelivery(_delivery!.id);
              if (mounted) {
                if (ok) {
                  _loadDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery order cancelled successfully.'),
                      backgroundColor: AppColors.darkNavy,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.actionError ??
                          'Cannot cancel delivery in current state.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Order',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _delivery != null ? _delivery!.trackingNumber : 'Delivery Details',
          style: const TextStyle(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
        actions: [
          if (_delivery != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy Tracking #',
              onPressed: () => _copyTrackingNumber(_delivery!.trackingNumber),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_errorMessage!,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : _delivery == null
                  ? const Center(child: Text('No delivery details available.'))
                  : RefreshIndicator(
                      onRefresh: _loadDetails,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 850;

                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1100),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Header Overview Banner
                                    _buildHeaderCard(_delivery!),
                                    const SizedBox(height: 16),

                                    // 2. Quick Action Buttons Bar
                                    _buildActionButtonsBar(_delivery!),
                                    const SizedBox(height: 16),

                                    // 3. Main Content Cards (2-Column if Wide, 1-Column if Narrow)
                                    if (isWide)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Column(
                                              children: [
                                                _buildCustomerCard(_delivery!),
                                                const SizedBox(height: 16),
                                                _buildRouteCard(_delivery!),
                                                const SizedBox(height: 16),
                                                _buildExecutiveCard(_delivery!),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 6,
                                            child: _buildTimelineCard(
                                                _delivery!),
                                          ),
                                        ],
                                      )
                                    else ...[
                                      _buildCustomerCard(_delivery!),
                                      const SizedBox(height: 16),
                                      _buildRouteCard(_delivery!),
                                      const SizedBox(height: 16),
                                      _buildExecutiveCard(_delivery!),
                                      const SizedBox(height: 16),
                                      _buildTimelineCard(_delivery!),
                                    ],
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard(DeliveryModel delivery) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: AppColors.primaryBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            delivery.trackingNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkNavy,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ETA: ${delivery.eta ?? "Standard (45 mins)"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: delivery.status, large: true),
            ],
          ),
          if (delivery.remarks != null && delivery.remarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      delivery.remarks!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtonsBar(DeliveryModel delivery) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionBtn(
              icon: Icons.edit_road_rounded,
              label: 'Update Status',
              color: AppColors.primaryBlue,
              onTap: _showStatusUpdateDialog,
            ),
            _buildActionBtn(
              icon: Icons.location_searching_rounded,
              label: 'Live Track',
              color: AppColors.cyanTeal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryTrackingScreen(
                        initialTrackingNumber: delivery.trackingNumber),
                  ),
                );
              },
            ),
            if (delivery.status == 'PENDING' ||
                delivery.status == 'ASSIGNED') ...[
              _buildActionBtn(
                icon: Icons.assignment_ind_outlined,
                label: delivery.assignedExecutive == null
                    ? 'Assign Executive'
                    : 'Reassign',
                color: AppColors.warning,
                onTap: () async {
                  final assigned =
                      await AssignDeliveryDialog.show(context, delivery);
                  if (assigned == true) {
                    _loadDetails();
                  }
                },
              ),
              _buildActionBtn(
                icon: Icons.edit_outlined,
                label: 'Edit Info',
                color: AppColors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditDeliveryScreen(delivery: delivery),
                    ),
                  ).then((_) => _loadDetails());
                },
              ),
              _buildActionBtn(
                icon: Icons.cancel_outlined,
                label: 'Cancel Order',
                color: AppColors.error,
                onTap: _confirmCancel,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildCustomerCard(DeliveryModel delivery) {
    return _cardContainer(
      title: 'Customer Details',
      icon: Icons.person_pin_rounded,
      child: Column(
        children: [
          _infoRow(
              'Customer Name', delivery.customer?.fullName ?? 'N/A', true),
          const Divider(height: 16, color: AppColors.divider),
          _infoRow('Phone Number', delivery.customer?.phone ?? 'N/A'),
          if (delivery.customer?.email != null &&
              delivery.customer!.email!.isNotEmpty) ...[
            const Divider(height: 16, color: AppColors.divider),
            _infoRow('Email Address', delivery.customer!.email!),
          ],
          const Divider(height: 16, color: AppColors.divider),
          _infoRow('City / Territory', delivery.city),
        ],
      ),
    );
  }

  Widget _buildRouteCard(DeliveryModel delivery) {
    return _cardContainer(
      title: 'Route & Schedule',
      icon: Icons.route_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded,
                    size: 14, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Location',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700)),
                    Text(delivery.pickupAddress,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10, top: 4, bottom: 4),
            child: SizedBox(
              height: 14,
              child: VerticalDivider(color: AppColors.border, thickness: 1.5),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cyanTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded,
                    size: 14, color: AppColors.cyanTeal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Destination',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700)),
                    Text(
                      '${delivery.deliveryAddress}, ${delivery.city}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: AppColors.divider),
          Row(
            children: [
              Expanded(
                  child: _infoRow('Date', delivery.deliveryDate, false)),
              Expanded(
                  child: _infoRow('Time Slot', delivery.deliveryTime, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveCard(DeliveryModel delivery) {
    final exec = delivery.assignedExecutive;
    return _cardContainer(
      title: 'Assigned Courier / Executive',
      icon: Icons.badge_outlined,
      trailing: (delivery.status == 'PENDING' ||
              delivery.status == 'ASSIGNED')
          ? TextButton(
              onPressed: () async {
                final assigned =
                    await AssignDeliveryDialog.show(context, delivery);
                if (assigned == true) {
                  _loadDetails();
                }
              },
              child: Text(
                exec == null ? '+ Assign' : 'Reassign',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue),
              ),
            )
          : null,
      child: exec != null
          ? Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                  child: Text(
                    exec.initials,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exec.fullName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy),
                      ),
                      Text(
                        exec.phone.isNotEmpty ? exec.phone : exec.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Active Driver',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success),
                  ),
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No delivery executive assigned yet. Click "Assign" above to select a driver.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkNavy,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimelineCard(DeliveryModel delivery) {
    final history = List.of(delivery.statusHistory ?? []);
    // Sort chronologically by parsed DateTime so entries always appear in order
    history.sort((a, b) {
      try {
        return DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt));
      } catch (_) {
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    return _cardContainer(
      title: 'Status Milestones & Tracking History',
      icon: Icons.history_rounded,
      child: history.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No tracking milestones logged yet.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = history[index];
                final isLast = index == history.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLast
                                ? AppColors.primaryBlue
                                : AppColors.textMuted,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 48,
                            color: AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLast
                              ? AppColors.primaryBlue.withValues(alpha: 0.04)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isLast
                                ? AppColors.primaryBlue.withValues(alpha: 0.2)
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(status: item.status),
                                Text(
                                  _formatDateTime(item.createdAt),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            if (item.remarks != null &&
                                item.remarks!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.remarks!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ],
                            if (item.location != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined,
                                      size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.location!,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                            if (item.updatedBy != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Updated by: ${item.updatedBy!.fullName}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _cardContainer({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, [bool bold = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
