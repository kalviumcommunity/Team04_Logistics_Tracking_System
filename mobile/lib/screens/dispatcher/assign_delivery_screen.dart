import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../models/user_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';

class AssignDeliveryScreen extends StatefulWidget {
  final String? preselectedDeliveryId;
  final bool isEmbedded;

  const AssignDeliveryScreen({
    super.key,
    this.preselectedDeliveryId,
    this.isEmbedded = false,
  });

  @override
  State<AssignDeliveryScreen> createState() => _AssignDeliveryScreenState();
}

class _AssignDeliveryScreenState extends State<AssignDeliveryScreen> {
  String? _selectedDeliveryId;
  String _searchExecQuery = '';
  String _execFilter = 'ALL'; // ALL, AVAILABLE, ON_DUTY
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDeliveryId = widget.preselectedDeliveryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<DeliveryProvider>(context, listen: false);
        provider.fetchDeliveries();
        provider.fetchExecutives();
      }
    });
  }

  void _handleAssign(DeliveryModel delivery, UserModel executive) {
    final isReassign = delivery.assignedExecutive != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isReassign
                  ? Icons.swap_horiz_rounded
                  : Icons.assignment_ind_rounded,
              color: AppColors.primaryBlue,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isReassign ? 'Confirm Reassignment' : 'Confirm Assignment',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.darkNavy),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign shipment order to ${executive.fullName}?',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _confirmRow('Tracking #', delivery.trackingNumber),
                  const SizedBox(height: 4),
                  _confirmRow(
                      'Customer', delivery.customer?.fullName ?? 'N/A'),
                  const SizedBox(height: 4),
                  _confirmRow('Destination',
                      '${delivery.deliveryAddress}, ${delivery.city}'),
                  if (isReassign && delivery.assignedExecutive != null) ...[
                    const Divider(height: 12),
                    _confirmRow('Current Driver',
                        delivery.assignedExecutive!.fullName),
                    const SizedBox(height: 4),
                    _confirmRow('New Driver', executive.fullName),
                  ],
                ],
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
              Navigator.pop(ctx);
              _executeAssignment(delivery, executive, isReassign);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            val,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _executeAssignment(
      DeliveryModel delivery, UserModel executive, bool isReassign) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final currentDispatcherUid = FirebaseAuth.instance.currentUser?.uid;
    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    final bool ok = isReassign
        ? await provider.reassignExecutive(delivery.id, executive.id,
            dispatcherId: currentDispatcherUid)
        : await provider.assignExecutive(delivery.id, executive.id,
            dispatcherId: currentDispatcherUid);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${delivery.trackingNumber} successfully assigned to ${executive.fullName}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!widget.isEmbedded && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _errorMessage = provider.actionError ??
            'Failed to assign delivery. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final assignableDeliveries = deliveryProvider.deliveries
        .where((d) =>
            d.status == 'PENDING' ||
            d.status == 'ASSIGNED' ||
            d.id == _selectedDeliveryId)
        .toList();

    // Default to first pending delivery if none selected
    if (_selectedDeliveryId == null && assignableDeliveries.isNotEmpty) {
      _selectedDeliveryId = assignableDeliveries.first.id;
    }

    final selectedDelivery = assignableDeliveries
        .where((d) => d.id == _selectedDeliveryId)
        .firstOrNull;

    final allDeliveries = deliveryProvider.deliveries;

    // Compute live workload count for each executive from the deliveries list
    int liveLoadCount(String execId) => allDeliveries
        .where((d) =>
            d.assignedExecutive?.id == execId &&
            (d.status == 'ASSIGNED' || d.status == 'IN_TRANSIT'))
        .length;

    final filteredExecutives = deliveryProvider.executives.where((e) {
      final matchesQuery = _searchExecQuery.isEmpty ||
          e.fullName.toLowerCase().contains(_searchExecQuery.toLowerCase()) ||
          e.phone.contains(_searchExecQuery) ||
          e.email.toLowerCase().contains(_searchExecQuery.toLowerCase());
      final load = liveLoadCount(e.id);
      final isAvailable = load == 0;
      final matchesFilter = _execFilter == 'ALL' ||
          (_execFilter == 'AVAILABLE' && isAvailable) ||
          (_execFilter == 'ON_DUTY' && !isAvailable);
      return matchesQuery && matchesFilter;
    }).toList();

    Widget bodyContent = RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          deliveryProvider.fetchDeliveries(),
          deliveryProvider.fetchExecutives(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkNavy, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.assignment_ind_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fleet & Dispatch Assignment',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pair pending shipment orders with active delivery executives based on workload.',
                              style: TextStyle(
                                  color: Color(0xFFE2E8F0), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: AppColors.error),
                          onPressed: () =>
                              setState(() => _errorMessage = null),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Responsive Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 850;

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Select Order
                          Expanded(
                            flex: 5,
                            child: _buildOrderSelectorCard(
                                assignableDeliveries, selectedDelivery),
                          ),
                          const SizedBox(width: 18),
                          // Right: Select Executive
                          Expanded(
                            flex: 6,
                            child: _buildExecutiveSelectorCard(
                              filteredExecutives,
                              selectedDelivery,
                              deliveryProvider.isExecutivesLoading,
                              allDeliveries,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildOrderSelectorCard(
                            assignableDeliveries, selectedDelivery),
                        const SizedBox(height: 16),
                        _buildExecutiveSelectorCard(
                          filteredExecutives,
                          selectedDelivery,
                          deliveryProvider.isExecutivesLoading,
                          allDeliveries,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Assign Delivery',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              deliveryProvider.fetchDeliveries();
              deliveryProvider.fetchExecutives();
            },
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildOrderSelectorCard(
      List<DeliveryModel> deliveries, DeliveryModel? selected) {
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
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: AppColors.primaryBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'Step 1: Select Shipment Order',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          if (deliveries.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 36, color: AppColors.success),
                  SizedBox(height: 8),
                  Text(
                    'All Deliveries Assigned!',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.darkNavy),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'There are currently no unassigned pending shipments.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedDeliveryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Shipment Order',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: deliveries.map((d) {
                return DropdownMenuItem(
                  value: d.id,
                  child: Row(
                    children: [
                      Text(
                        d.trackingNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '- ${d.customer?.fullName ?? "Customer"} (${d.city})',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.darkNavy),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedDeliveryId = val);
              },
            ),
            if (selected != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selected.trackingNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        StatusBadge(status: selected.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                        'Customer', selected.customer?.fullName ?? 'N/A'),
                    const SizedBox(height: 4),
                    _infoRow('Phone', selected.customer?.phone ?? 'N/A'),
                    const SizedBox(height: 4),
                    _infoRow('Pickup', selected.pickupAddress),
                    const SizedBox(height: 4),
                    _infoRow('Destination',
                        '${selected.deliveryAddress}, ${selected.city}'),
                    const SizedBox(height: 4),
                    _infoRow(
                        'Current Assigned',
                        selected.assignedExecutive?.fullName ??
                            'Unassigned (Pending)'),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildExecutiveSelectorCard(
    List<UserModel> executives,
    DeliveryModel? selectedDelivery,
    bool isLoading,
    List<DeliveryModel> allDeliveries,
  ) {
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
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.purple, size: 18),
              SizedBox(width: 8),
              Text(
                'Step 2: Choose Delivery Executive',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Search & Filter
          TextField(
            onChanged: (val) => setState(() => _searchExecQuery = val),
            decoration: InputDecoration(
              hintText: 'Search driver by name, phone...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips (All, Available, On Duty)
          Row(
            children: ['ALL', 'AVAILABLE', 'ON_DUTY'].map((filter) {
              final isSel = _execFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: ChoiceChip(
                  label: Text(
                    filter.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : AppColors.darkNavy,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.purple,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onSelected: (_) => setState(() => _execFilter = filter),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          if (isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (executives.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No delivery executives match the filter.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: executives.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exec = executives[index];
                final loadCount = allDeliveries
                    .where((d) =>
                        d.assignedExecutive?.id == exec.id &&
                        (d.status == 'ASSIGNED' || d.status == 'IN_TRANSIT'))
                    .length;
                final isCurrent =
                    selectedDelivery?.assignedExecutive?.id == exec.id;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryBlue.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primaryBlue.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.purple.withValues(alpha: 0.12),
                        child: Text(
                          exec.initials,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.purple,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exec.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.darkNavy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              exec.phone.isNotEmpty ? exec.phone : exec.email,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: loadCount == 0
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  loadCount == 0
                                      ? 'Available (0 active)'
                                      : '$loadCount active delivery orders',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: loadCount == 0
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (_isSubmitting || selectedDelivery == null)
                            ? null
                            : () => _handleAssign(selectedDelivery, exec),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrent
                              ? AppColors.textSecondary
                              : AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          isCurrent ? 'Reassign' : 'Assign',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy),
          ),
        ),
      ],
    );
  }
}
