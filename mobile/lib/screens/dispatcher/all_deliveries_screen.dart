import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/assign_delivery_dialog.dart';
import 'create_delivery_screen.dart';
import 'delivery_details_screen.dart';
import 'edit_delivery_screen.dart';
import 'delivery_tracking_screen.dart';

class AllDeliveriesScreen extends StatefulWidget {
  final String initialFilter;
  final bool isEmbedded;

  const AllDeliveriesScreen({
    super.key,
    this.initialFilter = 'ALL',
    this.isEmbedded = false,
  });

  @override
  State<AllDeliveriesScreen> createState() => _AllDeliveriesScreenState();
}

class _AllDeliveriesScreenState extends State<AllDeliveriesScreen> {
  late String _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'ASSIGNED',
    'IN_TRANSIT',
    'DELIVERED',
    'FAILED',
    'CANCELLED'
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmCancelDelivery(DeliveryModel delivery) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Delivery Order',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.darkNavy)),
        content: Text(
          'Are you sure you want to cancel delivery ${delivery.trackingNumber}? This action will stop dispatch processing.',
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider =
                  Provider.of<DeliveryProvider>(context, listen: false);
              final success = await provider.cancelDelivery(delivery.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Delivery ${delivery.trackingNumber} cancelled.'
                          : (provider.actionError ??
                              'Failed to cancel delivery order.'),
                    ),
                    backgroundColor:
                        success ? AppColors.darkNavy : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
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
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final all = deliveryProvider.deliveries;

    final filtered = all.where((d) {
      final matchesStatus =
          _selectedStatus == 'ALL' || d.status == _selectedStatus;
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          d.trackingNumber.toLowerCase().contains(q) ||
          (d.customer?.fullName.toLowerCase().contains(q) ?? false) ||
          (d.customer?.phone.toLowerCase().contains(q) ?? false) ||
          d.deliveryAddress.toLowerCase().contains(q) ||
          d.city.toLowerCase().contains(q) ||
          (d.assignedExecutive?.fullName.toLowerCase().contains(q) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();

    Widget content = RefreshIndicator(
      onRefresh: () => deliveryProvider.fetchDeliveries(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by tracking ID, customer, city, address, or executive...',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primaryBlue, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Status Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _statuses.map((status) {
                  final isSelected = _selectedStatus == status;
                  final count = status == 'ALL'
                      ? all.length
                      : all.where((d) => d.status == status).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedStatus = status),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Results count row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filtered.length} of ${all.length} deliveries',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedStatus != 'ALL')
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedStatus = 'ALL';
                      });
                    },
                    icon: const Icon(Icons.refresh,
                        size: 14, color: AppColors.primaryBlue),
                    label: const Text('Reset Filters',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Main Deliveries Content
            if (deliveryProvider.isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (deliveryProvider.error != null) ...[
              _buildErrorState(deliveryProvider),
            ] else if (filtered.isEmpty) ...[
              _buildEmptyState(),
            ] else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 850;
                  if (isDesktop) {
                    return _buildDesktopTable(filtered);
                  }
                  return _buildMobileCardList(filtered);
                },
              ),
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
          'All Deliveries',
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
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryBlue),
            tooltip: 'New Delivery',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()),
              ).then((_) => deliveryProvider.fetchDeliveries());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => deliveryProvider.fetchDeliveries(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()),
          ).then((_) => deliveryProvider.fetchDeliveries());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Delivery',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: content,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_outlined,
                size: 40, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Deliveries Found',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No deliveries matched your search query "$_searchQuery".'
                : 'No delivery shipments currently match status "$_selectedStatus".',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()),
              ).then((_) {
                if (mounted) {
                  Provider.of<DeliveryProvider>(context, listen: false)
                      .fetchDeliveries();
                }
              });
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create New Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DeliveryProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.error),
          const SizedBox(height: 12),
          const Text(
            'Unable to Load Deliveries',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.darkNavy),
          ),
          const SizedBox(height: 6),
          Text(
            provider.error ?? 'Please verify server connection and try again.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => provider.fetchDeliveries(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<DeliveryModel> deliveries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 850),
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 16,
              columnSpacing: 20,
              columns: const [
                DataColumn(
                    label: Text('TRACKING #',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('CUSTOMER',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('DESTINATION',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('ASSIGNED FLEET',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('STATUS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('ACTIONS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
              ],
              rows: deliveries.map((del) {
                return DataRow(
                  cells: [
                    DataCell(
                      InkWell(
                        onTap: () => _openDetails(del),
                        child: Text(
                          del.trackingNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryBlue,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            del.customer?.fullName ?? 'Customer',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.darkNavy),
                          ),
                          if (del.customer?.phone != null)
                            Text(
                              del.customer!.phone,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          '${del.deliveryAddress}, ${del.city}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            del.assignedExecutive != null
                                ? Icons.person_pin_rounded
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: del.assignedExecutive != null
                                ? AppColors.primaryBlue
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            del.assignedExecutive?.fullName ?? 'Unassigned',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: del.assignedExecutive != null
                                  ? AppColors.darkNavy
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(StatusBadge(status: del.status)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined,
                                size: 18, color: AppColors.primaryBlue),
                            tooltip: 'View Details',
                            onPressed: () => _openDetails(del),
                          ),
                          IconButton(
                            icon: const Icon(Icons.location_searching_rounded,
                                size: 18, color: AppColors.cyanTeal),
                            tooltip: 'Track Order',
                            onPressed: () => _openTracking(del),
                          ),
                          if (del.status == 'PENDING' ||
                              del.status == 'ASSIGNED') ...[
                            IconButton(
                              icon: const Icon(Icons.assignment_ind_outlined,
                                  size: 18, color: AppColors.warning),
                              tooltip: 'Assign / Reassign',
                              onPressed: () => _openAssign(del),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: AppColors.purple),
                              tooltip: 'Edit Delivery',
                              onPressed: () => _openEdit(del),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined,
                                  size: 18, color: AppColors.error),
                              tooltip: 'Cancel Order',
                              onPressed: () => _confirmCancelDelivery(del),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(List<DeliveryModel> deliveries) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deliveries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final del = deliveries[index];

        return Container(
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetails(del),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_rounded,
                                  size: 16, color: AppColors.primaryBlue),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              del.trackingNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(status: del.status),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Customer Name & Phone
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            del.customer?.fullName ?? 'Customer Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (del.customer?.phone != null)
                          Text(
                            del.customer!.phone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Destination Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${del.deliveryAddress}, ${del.city}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 10),

                    // Footer Row with Executive & Actions
                    Row(
                      children: [
                        Icon(
                          del.assignedExecutive != null
                              ? Icons.person_outline
                              : Icons.warning_amber_rounded,
                          size: 14,
                          color: del.assignedExecutive != null
                              ? AppColors.textSecondary
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 11, fontFamily: 'sans-serif'),
                              children: [
                                const TextSpan(
                                  text: 'Assigned To: ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: del.assignedExecutive?.fullName ??
                                      'Unassigned',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: del.assignedExecutive != null
                                        ? AppColors.darkNavy
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (del.status == 'PENDING' || del.status == 'ASSIGNED')
                          ElevatedButton.icon(
                            onPressed: () => _openAssign(del),
                            icon: Icon(
                              del.assignedExecutive != null
                                  ? Icons.swap_horiz_rounded
                                  : Icons.assignment_ind_rounded,
                              size: 14,
                            ),
                            label: Text(
                              del.assignedExecutive != null
                                  ? 'Reassign'
                                  : 'Assign Delivery',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: del.assignedExecutive != null
                                  ? AppColors.warning.withValues(alpha: 0.12)
                                  : AppColors.primaryBlue,
                              foregroundColor: del.assignedExecutive != null
                                  ? AppColors.warning
                                  : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openTracking(del),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.navigation_outlined,
                                  size: 13, color: AppColors.cyanTeal),
                              label: const Text('Track',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cyanTeal)),
                            ),
                            const SizedBox(width: 6),
                            TextButton.icon(
                              onPressed: () => _openDetails(del),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 13, color: AppColors.primaryBlue),
                              label: const Text('Details',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetails(DeliveryModel delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryDetailsScreen(deliveryId: delivery.id),
      ),
    ).then((_) {
      if (mounted) {
        Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
      }
    });
  }

  void _openTracking(DeliveryModel delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DeliveryTrackingScreen(initialTrackingNumber: delivery.trackingNumber),
      ),
    );
  }

  void _openAssign(DeliveryModel delivery) {
    AssignDeliveryDialog.show(context, delivery).then((assigned) {
      if (mounted && assigned == true) {
        Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
      }
    });
  }

  void _openEdit(DeliveryModel delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditDeliveryScreen(delivery: delivery),
      ),
    ).then((_) {
      if (mounted) {
        Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
      }
    });
  }
}
