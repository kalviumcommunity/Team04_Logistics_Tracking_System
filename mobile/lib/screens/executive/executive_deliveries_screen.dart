import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import 'active_delivery_screen.dart';
import 'executive_delivery_details_screen.dart';
import 'failure_report_screen.dart';

class ExecutiveDeliveriesScreen extends StatefulWidget {
  final bool isEmbedded;
  final String initialFilter;

  const ExecutiveDeliveriesScreen({
    super.key,
    this.isEmbedded = false,
    this.initialFilter = 'ALL',
  });

  @override
  State<ExecutiveDeliveriesScreen> createState() =>
      _ExecutiveDeliveriesScreenState();
}

class _ExecutiveDeliveriesScreenState extends State<ExecutiveDeliveriesScreen> {
  late String _selectedFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'ALL',
    'ASSIGNED',
    'IN_TRANSIT',
    'DELIVERED',
    'FAILED',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    await PhoneCaller.makePhoneCall(context, phoneNumber, roleLabel: 'Customer');
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

    // Filter deliveries
    final filtered = allDeliveries.where((d) {
      final matchesStatus =
          _selectedFilter == 'ALL' || d.status == _selectedFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          d.trackingNumber.toLowerCase().contains(q) ||
          (d.customer?.fullName.toLowerCase().contains(q) ?? false) ||
          d.deliveryAddress.toLowerCase().contains(q) ||
          d.city.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();

    final content = RefreshIndicator(
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
                  hintText: 'Search by tracking #, customer or address...',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final count = filter == 'ALL'
                      ? allDeliveries.length
                      : allDeliveries.where((d) => d.status == filter).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        '${filter.replaceAll('_', ' ')} ($count)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.darkNavy,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.border,
                        ),
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Content State
            if (deliveryProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (deliveryProvider.error != null)
              _buildErrorCard(deliveryProvider)
            else if (filtered.isEmpty)
              _buildEmptyCard()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final del = filtered[index];
                  return _buildDeliveryCard(del, deliveryProvider);
                },
              ),
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
          'My Assigned Deliveries',
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
            tooltip: 'Sync Orders',
            onPressed: () => deliveryProvider.fetchDeliveries(),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildDeliveryCard(DeliveryModel del, DeliveryProvider provider) {
    final isAssigned = del.status == 'ASSIGNED';
    final isInTransit = del.status == 'IN_TRANSIT';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInTransit
              ? AppColors.primaryBlue.withValues(alpha: 0.4)
              : AppColors.border,
          width: isInTransit ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isInTransit
                ? AppColors.primaryBlue.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Tracking # + Status
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
                    child: const Icon(Icons.local_shipping_outlined,
                        size: 16, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    del.trackingNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              StatusBadge(status: del.status),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Info Row + Call Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      del.customer?.fullName ?? 'Customer Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (del.customer?.phone.isNotEmpty == true)
                          ? del.customer!.phone
                          : 'Phone not available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.phone_rounded,
                    size: 16, color: AppColors.primaryBlue),
                tooltip: 'Call Customer',
                onPressed: () => _makePhoneCall(del.customer?.phone ?? ''),
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Address Line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${del.deliveryAddress}, ${del.city}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pickup & ETA Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pickup: ${del.pickupAddress}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ETA: ${del.eta ?? "Standard"}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Action Buttons Bar
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExecutiveDeliveryDetailsScreen(
                          deliveryId: del.id,
                          initialDelivery: del,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) {
                        provider.fetchDeliveries();
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkNavy,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Details',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isAssigned)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await provider.updateStatus(
                        del.id,
                        'IN_TRANSIT',
                        remarks: 'Delivery executive accepted & started route',
                      );
                      if (mounted) {
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Delivery started! Now in transit.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActiveDeliveryScreen(deliveryId: del.id),
                            ),
                          ).then((_) {
                            if (mounted) provider.fetchDeliveries();
                          });
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(provider.actionError ??
                                  'Failed to start delivery.'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Start Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                )
              else if (isInTransit) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FailureReportScreen(delivery: del),
                        ),
                      ).then((_) {
                        if (mounted) provider.fetchDeliveries();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Issue',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await provider.updateStatus(
                        del.id,
                        'DELIVERED',
                        remarks: 'Delivered successfully to customer',
                      );
                      if (mounted) {
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Order marked as DELIVERED! 🎉'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(provider.actionError ??
                                  'Failed to update status.'),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text('Delivered',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Deliveries Found',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFilter != 'ALL'
                ? 'No deliveries currently under status "$_selectedFilter".'
                : 'You have no assigned deliveries currently. When orders are dispatched to you, they will appear here.',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(DeliveryProvider provider) {
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
          const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.error),
          const SizedBox(height: 10),
          const Text(
            'Connection Issue',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.darkNavy),
          ),
          const SizedBox(height: 4),
          Text(
            provider.error ??
                'Unable to reach DeliverSync logistics server. Check your internet connection.',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => provider.fetchDeliveries(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
