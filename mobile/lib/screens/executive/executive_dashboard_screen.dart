import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../core/utils/role_router.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/access_denied_view.dart';
import '../../widgets/auth_loading_screen.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/status_badge.dart';
import '../notifications/notifications_screen.dart';
import 'active_delivery_screen.dart';
import 'delivery_history_screen.dart';
import 'executive_deliveries_screen.dart';
import 'executive_delivery_details_screen.dart';
import 'executive_profile_screen.dart';
import 'executive_settings_screen.dart';
import 'failure_report_screen.dart';
import 'field_delivery_screen.dart';
import 'update_status_screen.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  String _activeMenuId = 'dashboard';
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
    });
  }

  void _handleMenuSelection(String menuId) {
    setState(() {
      _activeMenuId = menuId;
      if (menuId == 'active_delivery') {
        _selectedFilter = 'IN_TRANSIT';
      } else if (menuId == 'my_deliveries') {
        _selectedFilter = 'ALL';
      } else if (menuId == 'update_status') {
        _selectedFilter = 'ASSIGNED';
      }
    });
  }

  String get _headerTitle {
    switch (_activeMenuId) {
      case 'my_deliveries':
        return 'My Assigned Deliveries';
      case 'active_delivery':
        return 'Active Delivery Cockpit';
      case 'update_status':
        return 'Update Delivery Status';
      case 'report_failure':
        return 'Report Delivery Issue';
      case 'delivery_history':
        return 'Delivery Archive & History';
      case 'notifications':
        return 'Alerts & Notifications';
      case 'profile':
        return 'Executive Profile';
      case 'settings':
        return 'Executive Settings';
      case 'dashboard':
      default:
        return 'Field Executive Dashboard';
    }
  }

  String get _headerSubtitle {
    switch (_activeMenuId) {
      case 'my_deliveries':
        return 'View, filter, and execute all active delivery assignments.';
      case 'active_delivery':
        return 'Live turn-by-turn route telemetry and active order progress.';
      case 'update_status':
        return 'Record proof of delivery, recipient notes, and state updates.';
      case 'report_failure':
        return 'Log exceptions, missed attempts, or parcel return reasons.';
      case 'delivery_history':
        return 'Review completed dispatches and operational metrics archive.';
      case 'notifications':
        return 'Real-time alerts, priority dispatches, and system updates.';
      case 'profile':
        return 'Account credentials, region assignment, and courier metrics.';
      case 'settings':
        return 'Configure GPS precision, navigation app, and alert chimes.';
      case 'dashboard':
      default:
        return 'Live delivery assignments, task status telemetry, and route updates.';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    await PhoneCaller.makePhoneCall(context, phoneNumber, roleLabel: 'Customer');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isChecking) {
      return const AuthLoadingScreen();
    }
    if (!auth.isAuthenticated ||
        !RoleRouter.isRoleAllowed(
            auth.user?.role, ['DELIVERY_EXECUTIVE', 'FIELD_EXECUTIVE', 'EXECUTIVE'])) {
      return const AccessDeniedView(requiredRoleName: 'Field Executive');
    }

    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final currentUserId = auth.user?.id;
    final allDeliveries = currentUserId != null
        ? deliveryProvider.deliveries
            .where((d) =>
                d.assignedTo == currentUserId ||
                d.assignedExecutive?.id == currentUserId)
            .toList()
        : deliveryProvider.deliveries;

    // Statistics
    final assigned = allDeliveries.where((d) => d.status == 'ASSIGNED').length;
    final inTransit =
        allDeliveries.where((d) => d.status == 'IN_TRANSIT').length;
    final completed =
        allDeliveries.where((d) => d.status == 'DELIVERED').length;
    final pendingTasks = assigned + inTransit;

    // Active Delivery (In Transit or First Assigned)
    DeliveryModel? activeDelivery;
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

    // Filtered list for overview
    final filteredDeliveries = allDeliveries.where((d) {
      final matchesFilter =
          _selectedFilter == 'ALL' || d.status == _selectedFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          d.trackingNumber.toLowerCase().contains(q) ||
          (d.customer?.fullName.toLowerCase().contains(q) ?? false) ||
          d.deliveryAddress.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    const primarySidebarItems = [
      SidebarItem(
          title: 'Dashboard', icon: Icons.dashboard_rounded, id: 'dashboard'),
      SidebarItem(
          title: 'My Deliveries',
          icon: Icons.local_shipping_outlined,
          id: 'my_deliveries'),
      SidebarItem(
          title: 'Active Delivery',
          icon: Icons.navigation_rounded,
          id: 'active_delivery'),
      SidebarItem(
          title: 'Update Status',
          icon: Icons.update_rounded,
          id: 'update_status'),
      SidebarItem(
          title: 'Report Issue',
          icon: Icons.report_problem_outlined,
          id: 'report_failure'),
      SidebarItem(
          title: 'Delivery History',
          icon: Icons.history_rounded,
          id: 'delivery_history'),
    ];

    return DashboardLayout(
      portalTitle: 'Field Executive Portal',
      activeMenuId: _activeMenuId,
      primaryMenuItems: primarySidebarItems,
      onMenuSelected: _handleMenuSelection,
      headerTitle: _headerTitle,
      headerSubtitle: _headerSubtitle,
      showSearch: _activeMenuId == 'dashboard',
      onSearchChanged: (q) => setState(() => _searchQuery = q),
      onRefresh: () => deliveryProvider.fetchDeliveries(),
      body: _buildBody(
        deliveryProvider,
        filteredDeliveries,
        activeDelivery,
        assigned,
        inTransit,
        completed,
        pendingTasks,
      ),
    );
  }

  Widget _buildBody(
    DeliveryProvider deliveryProvider,
    List<DeliveryModel> filteredDeliveries,
    DeliveryModel? activeDelivery,
    int assigned,
    int inTransit,
    int completed,
    int pendingTasks,
  ) {
    switch (_activeMenuId) {
      case 'my_deliveries':
        return const ExecutiveDeliveriesScreen(isEmbedded: true);
      case 'active_delivery':
        return const ActiveDeliveryScreen(isEmbedded: true);
      case 'update_status':
        return const UpdateStatusScreen(isEmbedded: true);
      case 'report_failure':
        return const FailureReportScreen(isEmbedded: true);
      case 'delivery_history':
        return const DeliveryHistoryScreen(isEmbedded: true);
      case 'notifications':
        return const NotificationsScreen(isEmbedded: true);
      case 'profile':
        return const ExecutiveProfileScreen(isEmbedded: true);
      case 'settings':
        return const ExecutiveSettingsScreen(isEmbedded: true);
      case 'dashboard':
      default:
        return _buildDashboardOverview(
          deliveryProvider,
          filteredDeliveries,
          activeDelivery,
          assigned,
          inTransit,
          completed,
          pendingTasks,
        );
    }
  }

  Widget _buildDashboardOverview(
    DeliveryProvider deliveryProvider,
    List<DeliveryModel> filteredDeliveries,
    DeliveryModel? activeDelivery,
    int assigned,
    int inTransit,
    int completed,
    int pendingTasks,
  ) {
    return RefreshIndicator(
      onRefresh: () => deliveryProvider.fetchDeliveries(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Statistics Cards (Responsive Grid) ────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 4;
                double aspectRatio = 1.6;

                if (constraints.maxWidth < 600) {
                  crossAxisCount = 2;
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  aspectRatio = (cardWidth / 138.0).clamp(0.8, 1.3);
                } else if (constraints.maxWidth < 950) {
                  crossAxisCount = 2;
                  aspectRatio = 1.8;
                } else if (constraints.maxWidth < 1200) {
                  crossAxisCount = 4;
                  aspectRatio = 1.35;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    DashboardStatCard(
                      title: 'Assigned Deliveries',
                      value: '$assigned',
                      icon: Icons.assignment_ind_outlined,
                      color: AppColors.primaryBlue,
                      subtitle: 'Awaiting pickup & transit',
                      onTap: () => setState(() {
                        _activeMenuId = 'my_deliveries';
                      }),
                    ),
                    DashboardStatCard(
                      title: 'Active Deliveries',
                      value: '$inTransit',
                      icon: Icons.directions_run_outlined,
                      color: AppColors.cyanTeal,
                      badgeText: inTransit > 0 ? 'On Route' : null,
                      badgeColor: AppColors.cyanTeal,
                      subtitle: 'Currently out for delivery',
                      onTap: () => setState(() {
                        _activeMenuId = 'active_delivery';
                      }),
                    ),
                    DashboardStatCard(
                      title: 'Completed Today',
                      value: '$completed',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      subtitle: 'Delivered to customer',
                      onTap: () => setState(() {
                        _activeMenuId = 'delivery_history';
                      }),
                    ),
                    DashboardStatCard(
                      title: 'Pending Tasks',
                      value: '$pendingTasks',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.warning,
                      subtitle: 'Total active workload',
                      onTap: () => setState(() => _selectedFilter = 'ALL'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── 2. My Active Delivery Section (Prominent Card) ─────────
            const Row(
              children: [
                Icon(Icons.near_me_rounded,
                    size: 18, color: AppColors.primaryBlue),
                SizedBox(width: 6),
                Text(
                  'My Active Delivery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (activeDelivery != null)
              _buildActiveDeliveryCard(activeDelivery, deliveryProvider)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.done_all_rounded,
                          color: AppColors.success, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All assigned deliveries are clear!',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.darkNavy),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'No active in-transit shipment. Check new assignments below.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ── 3. Quick Actions ─────────────────────────────────────
            const Row(
              children: [
                Icon(Icons.bolt_rounded,
                    size: 18, color: AppColors.primaryBlue),
                SizedBox(width: 6),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (activeDelivery != null &&
                    activeDelivery.status == 'ASSIGNED')
                  _buildActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'Start Delivery',
                    color: AppColors.primaryBlue,
                    onTap: () async {
                      await deliveryProvider.updateStatus(
                          activeDelivery.id, 'IN_TRANSIT',
                          remarks: 'Executive started delivery');
                    },
                  ),
                if (activeDelivery != null &&
                    activeDelivery.status == 'IN_TRANSIT') ...[
                  _buildActionButton(
                    icon: Icons.check_circle_rounded,
                    label: 'Mark Delivered',
                    color: AppColors.success,
                    onTap: () async {
                      await deliveryProvider.updateStatus(
                          activeDelivery.id, 'DELIVERED',
                          remarks: 'Delivered successfully by executive');
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.report_problem_rounded,
                    label: 'Report an Issue',
                    color: AppColors.error,
                    onTap: () {
                      setState(() {
                        _activeMenuId = 'report_failure';
                      });
                    },
                  ),
                ],
                _buildActionButton(
                  icon: Icons.update_rounded,
                  label: 'Update Status',
                  color: AppColors.primaryBlue,
                  onTap: () {
                    setState(() {
                      _activeMenuId = 'update_status';
                    });
                  },
                ),
                _buildActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Sync Orders',
                  color: AppColors.darkNavy,
                  onTap: () => deliveryProvider.fetchDeliveries(),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── 4. All Assigned Tasks Feed (Mobile Stacked Cards) ────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_list_bulleted_rounded,
                        size: 18, color: AppColors.primaryBlue),
                    SizedBox(width: 6),
                    Text(
                      'Assigned Tasks Feed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${filteredDeliveries.length} items',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'ALL',
                  'ASSIGNED',
                  'IN_TRANSIT',
                  'DELIVERED',
                  'FAILED'
                ].map((status) {
                  final isSelected = _selectedFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? Colors.white : AppColors.darkNavy,
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
                                : AppColors.border),
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedFilter = status),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            if (filteredDeliveries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.task_outlined,
                        size: 36, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text('No assigned tasks in this view',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDeliveries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final del = filteredDeliveries[index];
                  return _buildTaskCard(del, deliveryProvider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDeliveryCard(
      DeliveryModel delivery, DeliveryProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.trackingNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.darkNavy),
                      ),
                      Text(
                        'ETA: ${delivery.eta ?? "25 mins"}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(status: delivery.status, large: true),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Route Block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked,
                      size: 14, color: AppColors.primaryBlue),
                  Container(width: 2, height: 26, color: AppColors.border),
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.error),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup: ${delivery.pickupAddress}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Text(
                      'Destination: ${delivery.deliveryAddress}, ${delivery.city}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Customer Row with Call Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.person,
                        size: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.customer?.fullName ?? 'Customer Name',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.darkNavy),
                      ),
                      Text(
                        (delivery.customer?.phone.isNotEmpty == true)
                            ? delivery.customer!.phone
                            : 'Phone not available',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.phone,
                    size: 18, color: AppColors.primaryBlue),
                tooltip: 'Call Customer',
                onPressed: () =>
                    _makePhoneCall(delivery.customer?.phone ?? ''),
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons Bar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ExecutiveDeliveryDetailsScreen(deliveryId: delivery.id)),
                    ).then((_) => provider.fetchDeliveries());
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View Full Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FieldDeliveryScreen(delivery: delivery)),
                    ).then((_) => provider.fetchDeliveries());
                  },
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Field Terminal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DeliveryModel delivery, DeliveryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                delivery.trackingNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.primaryBlue),
              ),
              StatusBadge(status: delivery.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            delivery.customer?.fullName ?? 'Customer',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.darkNavy),
          ),
          const SizedBox(height: 4),
          Text(
            '📍 ${delivery.deliveryAddress}, ${delivery.city}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ETA: ${delivery.eta ?? "Standard"}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ExecutiveDeliveryDetailsScreen(deliveryId: delivery.id)),
                  ).then((_) => provider.fetchDeliveries());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(90, 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Manage Task',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy),
            ),
          ],
        ),
      ),
    );
  }
}
