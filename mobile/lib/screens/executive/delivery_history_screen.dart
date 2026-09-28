import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import 'executive_delivery_details_screen.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  final bool isEmbedded;

  const DeliveryHistoryScreen({super.key, this.isEmbedded = false});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String _statusFilter = 'ALL'; // ALL, DELIVERED, FAILED
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final allDeliveries = deliveryProvider.deliveries;

    // Filter historical deliveries (completed or failed)
    final historyDeliveries = allDeliveries.where((d) {
      final isHistoryStatus = d.status == 'DELIVERED' ||
          d.status == 'FAILED' ||
          d.status == 'CANCELLED';

      final matchesStatus =
          _statusFilter == 'ALL' ? isHistoryStatus : d.status == _statusFilter;

      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          d.trackingNumber.toLowerCase().contains(q) ||
          (d.customer?.fullName.toLowerCase().contains(q) ?? false) ||
          d.deliveryAddress.toLowerCase().contains(q) ||
          d.city.toLowerCase().contains(q);

      return matchesStatus && matchesSearch;
    }).toList();

    // Summary Metrics
    final totalDelivered =
        allDeliveries.where((d) => d.status == 'DELIVERED').length;
    final totalFailed =
        allDeliveries.where((d) => d.status == 'FAILED').length;
    final totalFinished = totalDelivered + totalFailed;
    final successRate = totalFinished > 0
        ? ((totalDelivered / totalFinished) * 100).toStringAsFixed(0)
        : '100';

    final content = RefreshIndicator(
      onRefresh: () => deliveryProvider.fetchDeliveries(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Statistics Cards Strip ────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Delivered',
                        value: '$totalDelivered',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Success Rate',
                        value: '$successRate%',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Failed',
                        value: '$totalFailed',
                        icon: Icons.report_problem_rounded,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // ── 2. Search Bar ────────────────────────────────────────
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
                  hintText: 'Search past shipments by ID or customer...',
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

            // ── 3. Filter Chips ──────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['ALL', 'DELIVERED', 'FAILED', 'CANCELLED'].map((s) {
                  final isSelected = _statusFilter == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        s.replaceAll('_', ' '),
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
                      onSelected: (_) => setState(() => _statusFilter = s),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── 4. History List ──────────────────────────────────────
            if (deliveryProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (historyDeliveries.isEmpty)
              _buildEmptyCard()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyDeliveries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final del = historyDeliveries[index];
                  return _buildHistoryCard(del);
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
          'Delivery History',
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
            onPressed: () => deliveryProvider.fetchDeliveries(),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DeliveryModel del) {
    final isSuccess = del.status == 'DELIVERED';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExecutiveDeliveryDetailsScreen(
              deliveryId: del.id,
              initialDelivery: del,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                    Icon(
                      isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: isSuccess ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 6),
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
            const SizedBox(height: 8),
            Text(
              del.customer?.fullName ?? 'Customer Name',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${del.deliveryAddress}, ${del.city}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (del.remarks != null && del.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        del.remarks!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${del.createdAt.length >= 10 ? del.createdAt.substring(0, 10) : del.createdAt}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                const Text(
                  'View Details →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            child: const Icon(Icons.history_toggle_off_rounded,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Delivery History Found',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Completed and closed delivery shipments will automatically be catalogued here.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
