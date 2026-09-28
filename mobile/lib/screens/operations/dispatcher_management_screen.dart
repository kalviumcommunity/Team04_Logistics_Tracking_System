import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/user_model.dart';
import '../../providers/delivery_provider.dart';

class DispatcherManagementScreen extends StatefulWidget {
  final bool isEmbedded;

  const DispatcherManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<DispatcherManagementScreen> createState() =>
      _DispatcherManagementScreenState();
}

class _DispatcherManagementScreenState
    extends State<DispatcherManagementScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<DeliveryProvider>(context, listen: false);
        provider.fetchDispatchers();
        provider.fetchDeliveries();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phone) async {
    await PhoneCaller.makePhoneCall(context, phone, roleLabel: 'Dispatcher');
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final deliveries = deliveryProvider.deliveries;

    // Use live registered dispatchers from Firestore users collection
    final List<UserModel> dispatchers = deliveryProvider.dispatchers;

    final q = _searchQuery.toLowerCase();
    final filteredDispatchers = dispatchers.where((d) {
      return q.isEmpty ||
          d.fullName.toLowerCase().contains(q) ||
          d.email.toLowerCase().contains(q) ||
          d.phone.contains(q);
    }).toList();

    Widget content = RefreshIndicator(
      onRefresh: () async {
        await deliveryProvider.fetchDispatchers();
        await deliveryProvider.fetchDeliveries();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Header
            Container(
              padding: const EdgeInsets.all(20),
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
                  Icon(Icons.badge_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatcher Hub Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hub station leads, dispatch desk telemetry, active shipment workload, and emergency contact.',
                          style: TextStyle(
                              color: Color(0xFFE2E8F0), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search hub dispatcher by name, phone, or email...',
                  hintStyle: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
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
            const SizedBox(height: 16),

            // List of Dispatchers
            if (deliveryProvider.isDispatchersLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(36.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredDispatchers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No dispatchers found matching search.'
                          : 'No dispatchers registered in the system yet.',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDispatchers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final disp = filteredDispatchers[index];
                  // Compute active deliveries managed by this dispatcher
                  final managedCount = deliveries
                      .where((d) => d.createdBy?.id == disp.id)
                      .length;

                  return _buildDispatcherCard(disp, managedCount, index);
                },
              ),
            const SizedBox(height: 40),
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
        title: const Text('Dispatcher Management',
            style: TextStyle(
                color: AppColors.darkNavy,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
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

  Widget _buildDispatcherCard(UserModel disp, int managedCount, int index) {
    final hubs = [
      'Central Metro Hub, Bay 4',
      'North Cargo Depot',
      'South Harbor Logistics Center',
      'East Express Warehouse',
    ];
    final hubName = hubs[index % hubs.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.purple.withValues(alpha: 0.15),
            child: Text(
              disp.initials,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.purple,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      disp.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'On Duty',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hubName,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue),
                ),
                const SizedBox(height: 2),
                Text(
                  '${disp.email} • $managedCount Active Managed Orders',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (disp.phone.isNotEmpty)
            IconButton.filledTonal(
              icon: const Icon(Icons.phone_rounded,
                  size: 18, color: AppColors.purple),
              onPressed: () => _makePhoneCall(disp.phone),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.purple.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }
}
