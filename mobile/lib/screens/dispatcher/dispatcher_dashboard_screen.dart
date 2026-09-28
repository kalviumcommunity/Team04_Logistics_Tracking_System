import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../core/utils/role_router.dart';
import '../../widgets/access_denied_view.dart';
import '../../widgets/auth_loading_screen.dart';
import '../../widgets/assign_delivery_dialog.dart';
import '../notifications/notifications_screen.dart';
import 'all_deliveries_screen.dart';
import 'assign_delivery_screen.dart';
import 'create_delivery_screen.dart';
import 'delivery_details_screen.dart';
import 'delivery_tracking_screen.dart';
import 'dispatcher_profile_screen.dart';
import 'dispatcher_settings_screen.dart';

class DispatcherDashboardScreen extends StatefulWidget {
  const DispatcherDashboardScreen({super.key});

  @override
  State<DispatcherDashboardScreen> createState() =>
      _DispatcherDashboardScreenState();
}

class _DispatcherDashboardScreenState extends State<DispatcherDashboardScreen> {
  String _activeMenuId = 'dashboard';
  String _selectedStatusFilter = 'ALL';
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
    if (menuId == 'create_delivery') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()),
      ).then((_) {
        if (mounted) {
          Provider.of<DeliveryProvider>(context, listen: false)
              .fetchDeliveries();
        }
      });
      return;
    }

    setState(() {
      _activeMenuId = menuId;
    });
  }

  String get _headerTitle {
    switch (_activeMenuId) {
      case 'deliveries':
        return 'All Deliveries';
      case 'assign_deliveries':
        return 'Assign Deliveries';
      case 'track_deliveries':
        return 'Live Shipment Tracking';
      case 'notifications':
        return 'Notifications & Alerts';
      case 'profile':
        return 'Dispatcher Profile';
      case 'settings':
        return 'Dispatcher Settings';
      case 'dashboard':
      default:
        return 'Dispatcher Dashboard';
    }
  }

  String get _headerSubtitle {
    switch (_activeMenuId) {
      case 'deliveries':
        return 'Browse, filter, search, and manage all shipment orders.';
      case 'assign_deliveries':
        return 'Allocate pending orders to available field executives.';
      case 'track_deliveries':
        return 'Monitor real-time progress, checkpoints, and delivery milestones.';
      case 'notifications':
        return 'Real-time updates, alerts, and operational event logs.';
      case 'profile':
        return 'Account details, permissions, and hub operational activity.';
      case 'settings':
        return 'Preferences, alerts, default hub, and diagnostics.';
      case 'dashboard':
      default:
        return 'Coordinate live orders, fleet assignments, and shipment tracking.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isChecking) {
      return const AuthLoadingScreen();
    }
    if (!auth.isAuthenticated ||
        !RoleRouter.isRoleAllowed(auth.user?.role, ['DISPATCHER'])) {
      return const AccessDeniedView(requiredRoleName: 'Dispatcher');
    }

    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final allDeliveries = deliveryProvider.deliveries;

    // Computed Stats
    final total = allDeliveries.length;
    final pendingAssignments =
        allDeliveries.where((d) => d.status == 'PENDING').length;
    final inTransit =
        allDeliveries.where((d) => d.status == 'IN_TRANSIT').length;
    final deliveredToday =
        allDeliveries.where((d) => d.status == 'DELIVERED').length;

    // Filtered Deliveries
    final filteredDeliveries = allDeliveries.where((d) {
      final matchesStatus =
          _selectedStatusFilter == 'ALL' || d.status == _selectedStatusFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          d.trackingNumber.toLowerCase().contains(q) ||
          (d.customer?.fullName.toLowerCase().contains(q) ?? false) ||
          d.deliveryAddress.toLowerCase().contains(q) ||
          d.city.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();

    const primarySidebarItems = [
      SidebarItem(
          title: 'Dashboard', icon: Icons.dashboard_rounded, id: 'dashboard'),
      SidebarItem(
          title: 'Create Delivery',
          icon: Icons.add_circle_outline_rounded,
          id: 'create_delivery'),
      SidebarItem(
          title: 'Deliveries',
          icon: Icons.inventory_2_outlined,
          id: 'deliveries'),
      SidebarItem(
          title: 'Assign Deliveries',
          icon: Icons.assignment_ind_outlined,
          id: 'assign_deliveries'),
    ];

    return DashboardLayout(
      portalTitle: 'Dispatcher Portal',
      activeMenuId: _activeMenuId,
      primaryMenuItems: primarySidebarItems,
      onMenuSelected: _handleMenuSelection,
      headerTitle: _headerTitle,
      headerSubtitle: _headerSubtitle,
      showSearch: _activeMenuId == 'dashboard',
      onSearchChanged: (q) => setState(() => _searchQuery = q),
      onRefresh: () => deliveryProvider.fetchDeliveries(),
      floatingActionButton:
          _activeMenuId == 'dashboard' || _activeMenuId == 'deliveries'
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateDeliveryScreen()),
                    ).then((_) => deliveryProvider.fetchDeliveries());
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Delivery',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : null,
      body: _buildBody(
        deliveryProvider,
        filteredDeliveries,
        total,
        pendingAssignments,
        inTransit,
        deliveredToday,
      ),
    );
  }

  Widget _buildBody(
    DeliveryProvider deliveryProvider,
    List<DeliveryModel> filteredDeliveries,
    int total,
    int pendingAssignments,
    int inTransit,
    int deliveredToday,
  ) {
    switch (_activeMenuId) {
      case 'deliveries':
        return const AllDeliveriesScreen(isEmbedded: true);
      case 'assign_deliveries':
        return const AssignDeliveryScreen(isEmbedded: true);
      case 'track_deliveries':
        return const DeliveryTrackingScreen(isEmbedded: true);
      case 'notifications':
        return const NotificationsScreen(isEmbedded: true);
      case 'profile':
        return const DispatcherProfileScreen(isEmbedded: true);
      case 'settings':
        return const DispatcherSettingsScreen(isEmbedded: true);
      case 'dashboard':
      default:
        return _buildDashboardOverview(
          deliveryProvider,
          filteredDeliveries,
          total,
          pendingAssignments,
          inTransit,
          deliveredToday,
        );
    }
  }

  Widget _buildDashboardOverview(
    DeliveryProvider deliveryProvider,
    List<DeliveryModel> filteredDeliveries,
    int total,
    int pendingAssignments,
    int inTransit,
    int deliveredToday,
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
                      title: 'Total Deliveries',
                      value: '$total',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primaryBlue,
                      subtitle: 'All active & closed orders',
                      onTap: () =>
                          setState(() => _selectedStatusFilter = 'ALL'),
                    ),
                    DashboardStatCard(
                      title: 'Pending Assignments',
                      value: '$pendingAssignments',
                      icon: Icons.schedule_rounded,
                      color: AppColors.warning,
                      badgeText:
                          pendingAssignments > 0 ? 'Requires Action' : null,
                      badgeColor: AppColors.warning,
                      subtitle: 'Awaiting executive assignment',
                      onTap: () =>
                          setState(() => _selectedStatusFilter = 'PENDING'),
                    ),
                    DashboardStatCard(
                      title: 'In Transit',
                      value: '$inTransit',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.cyanTeal,
                      subtitle: 'Active on field route',
                      onTap: () =>
                          setState(() => _selectedStatusFilter = 'IN_TRANSIT'),
                    ),
                    DashboardStatCard(
                      title: 'Delivered Today',
                      value: '$deliveredToday',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      subtitle: 'Successfully completed',
                      onTap: () =>
                          setState(() => _selectedStatusFilter = 'DELIVERED'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── 2. Quick Actions Section ─────────────────────────────
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
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.add_box_rounded,
                      label: 'Create Delivery',
                      color: AppColors.primaryBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateDeliveryScreen()),
                        ).then((_) => deliveryProvider.fetchDeliveries());
                      },
                    ),
                    _buildQuickActionButton(
                      icon: Icons.assignment_ind_rounded,
                      label: 'Assign Pending',
                      color: AppColors.warning,
                      onTap: () {
                        setState(() {
                          _activeMenuId = 'assign_deliveries';
                        });
                      },
                    ),
                    _buildQuickActionButton(
                      icon: Icons.filter_list_rounded,
                      label: 'View All Deliveries',
                      color: AppColors.darkNavy,
                      onTap: () {
                        setState(() {
                          _activeMenuId = 'deliveries';
                        });
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // ── 3. Recent Deliveries Section & Filters ───────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded,
                          size: 18, color: AppColors.primaryBlue),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Recent Deliveries',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredDeliveries.length} entries',
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
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  'ALL',
                  'PENDING',
                  'ASSIGNED',
                  'IN_TRANSIT',
                  'DELIVERED',
                  'FAILED',
                  'CANCELLED'
                ].map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
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
                          setState(() => _selectedStatusFilter = status),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Deliveries Content Area
            if (deliveryProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredDeliveries.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
                      'No deliveries found',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.darkNavy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedStatusFilter != 'ALL'
                          ? 'No deliveries currently match the status "$_selectedStatusFilter".'
                          : 'No deliveries recorded yet. Create a new delivery order to begin.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktopTable = constraints.maxWidth >= 780;

                  if (isDesktopTable) {
                    return _buildDeliveriesTable(filteredDeliveries);
                  } else {
                    return _buildDeliveriesCardList(filteredDeliveries);
                  }
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveriesTable(List<DeliveryModel> deliveries) {
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
            constraints: const BoxConstraints(minWidth: 780),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 18,
              columnSpacing: 24,
              columns: const [
                DataColumn(
                    label: Text('DELIVERY ID',
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
                    label: Text('EXECUTIVE',
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
                    label: Text('ACTION',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
              ],
              rows: deliveries.map((del) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        del.trackingNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                            fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        del.customer?.fullName ?? 'Customer',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.darkNavy),
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
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeliveryDetailsScreen(
                                      deliveryId: del.id, initialDelivery: del),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  Provider.of<DeliveryProvider>(context,
                                          listen: false)
                                      .fetchDeliveries();
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              foregroundColor: AppColors.primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: const Size(54, 28),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('View',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          if (del.status == 'PENDING' ||
                              del.status == 'ASSIGNED') ...[
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  AssignDeliveryDialog.show(context, del),
                              icon: Icon(
                                del.assignedExecutive != null
                                    ? Icons.swap_horiz_rounded
                                    : Icons.assignment_ind_rounded,
                                size: 13,
                              ),
                              label: Text(
                                del.assignedExecutive != null
                                    ? 'Reassign'
                                    : 'Assign',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700),
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
                                    horizontal: 8, vertical: 6),
                                minimumSize: const Size(60, 28),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
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

  Widget _buildDeliveriesCardList(List<DeliveryModel> deliveries) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deliveries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final del = deliveries[index];
        final isAssigned = del.assignedExecutive != null ||
            (del.assignedTo != null && del.assignedTo!.isNotEmpty);
        final canAssign = del.status == 'PENDING' || del.status == 'ASSIGNED';

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      del.trackingNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.primaryBlue),
                    ),
                    StatusBadge(status: del.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  del.customer?.fullName ??
                      del.recipientName ??
                      'Customer Name',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.darkNavy),
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
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isAssigned
                          ? Icons.person_outline
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: isAssigned
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
                                  (isAssigned ? 'Assigned' : 'Unassigned'),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isAssigned
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (canAssign)
                      ElevatedButton.icon(
                        onPressed: () =>
                            AssignDeliveryDialog.show(context, del),
                        icon: Icon(
                          isAssigned
                              ? Icons.swap_horiz_rounded
                              : Icons.assignment_ind_rounded,
                          size: 14,
                        ),
                        label: Text(
                          isAssigned ? 'Reassign' : 'Assign Delivery',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAssigned
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : AppColors.primaryBlue,
                          foregroundColor:
                              isAssigned ? AppColors.warning : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryDetailsScreen(
                                deliveryId: del.id, initialDelivery: del),
                          ),
                        ).then((_) {
                          if (mounted) {
                            Provider.of<DeliveryProvider>(context,
                                    listen: false)
                                .fetchDeliveries();
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Details →',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
