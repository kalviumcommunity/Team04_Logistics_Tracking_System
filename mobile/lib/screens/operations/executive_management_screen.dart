import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/user_model.dart';
import '../../providers/delivery_provider.dart';

class ExecutiveManagementScreen extends StatefulWidget {
  final bool isEmbedded;

  const ExecutiveManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<ExecutiveManagementScreen> createState() =>
      _ExecutiveManagementScreenState();
}

class _ExecutiveManagementScreenState extends State<ExecutiveManagementScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<DeliveryProvider>(context, listen: false);
        provider.fetchExecutives();
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
    await PhoneCaller.makePhoneCall(context, phone, roleLabel: 'Executive');
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final executives = deliveryProvider.executives;
    final allDeliveries = deliveryProvider.deliveries;

    final q = _searchQuery.toLowerCase();
    final filteredExecs = executives.where((e) {
      return q.isEmpty ||
          e.fullName.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          e.phone.contains(q);
    }).toList();

    Widget content = RefreshIndicator(
      onRefresh: () async {
        await deliveryProvider.fetchExecutives();
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
                  colors: [AppColors.darkNavy, AppColors.cyanTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Field Executive Roster',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Monitor field couriers, live duty availability, active load telemetry, and phone contact.',
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

            // Search Bar
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
                  hintText: 'Search field executive by name, phone, or email...',
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

            // List of Executives
            if (deliveryProvider.isExecutivesLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredExecs.isEmpty)
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
                    const Icon(Icons.person_off_outlined,
                        size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No field executives match query.'
                          : 'No field executives registered in the system yet.',
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
                itemCount: filteredExecs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final exec = filteredExecs[index];
                  final activeLoad = allDeliveries
                      .where((d) =>
                          d.assignedExecutive?.id == exec.id &&
                          (d.status == 'ASSIGNED' || d.status == 'IN_TRANSIT'))
                      .length;

                  return _buildExecutiveCard(exec, activeLoad);
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
        title: const Text('Field Executive Management',
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
            onPressed: () {
              deliveryProvider.fetchExecutives();
              deliveryProvider.fetchDeliveries();
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildExecutiveCard(UserModel exec, int activeLoad) {
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
            backgroundColor: AppColors.cyanTeal.withValues(alpha: 0.15),
            child: Text(
              exec.initials,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.cyanTeal,
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
                      exec.fullName,
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
                        color: activeLoad > 0
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activeLoad > 0 ? '$activeLoad Active' : 'Available',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: activeLoad > 0
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  exec.email,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (exec.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    exec.phone,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          if (exec.phone.isNotEmpty)
            IconButton.filledTonal(
              icon: const Icon(Icons.phone_rounded,
                  size: 18, color: AppColors.cyanTeal),
              onPressed: () => _makePhoneCall(exec.phone),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.cyanTeal.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }
}
