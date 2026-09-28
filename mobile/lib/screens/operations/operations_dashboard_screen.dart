import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/escalation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/escalation_provider.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../core/utils/role_router.dart';
import '../../widgets/access_denied_view.dart';
import '../../widgets/auth_loading_screen.dart';
import '../notifications/notifications_screen.dart';
import 'analytics_screen.dart';
import 'escalation_center_screen.dart';
import 'operations_deliveries_screen.dart';
import 'failed_deliveries_screen.dart';
import 'failure_reports_screen.dart';
import 'executive_management_screen.dart';
import 'dispatcher_management_screen.dart';
import 'operations_profile_screen.dart';
import 'operations_settings_screen.dart';
import '../dispatcher/delivery_tracking_screen.dart';

class OperationsDashboardScreen extends StatefulWidget {
  const OperationsDashboardScreen({super.key});

  @override
  State<OperationsDashboardScreen> createState() =>
      _OperationsDashboardScreenState();
}

class _OperationsDashboardScreenState extends State<OperationsDashboardScreen> {
  String _activeMenuId = 'dashboard';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
      Provider.of<EscalationProvider>(context, listen: false)
          .fetchEscalations();
    });
  }

  void _handleMenuSelection(String menuId) {
    setState(() => _activeMenuId = menuId);
  }

  String get _headerTitle {
    switch (_activeMenuId) {
      case 'analytics':
        return 'Analytics & Performance';
      case 'monitoring':
        return 'Delivery Monitoring';
      case 'dispatchers':
        return 'Dispatcher Management';
      case 'executives':
        return 'Field Executive Management';
      case 'escalations':
        return 'Escalation Center';
      case 'failed_deliveries':
        return 'Failed Deliveries';
      case 'reports':
        return 'Failure Reports';
      case 'notifications':
        return 'Notifications';
      case 'profile':
        return 'My Profile';
      case 'settings':
        return 'Settings';
      case 'tracking':
        return 'Live Delivery Tracking';
      default:
        return 'Operations Dashboard';
    }
  }

  String get _headerSubtitle {
    switch (_activeMenuId) {
      case 'analytics':
        return 'System-wide delivery performance and KPIs.';
      case 'monitoring':
        return 'Real-time view of all active and completed deliveries.';
      case 'dispatchers':
        return 'Dispatcher team overview and workload distribution.';
      case 'executives':
        return 'Field executive roster, status, and delivery load.';
      case 'escalations':
        return 'Active escalations requiring operational intervention.';
      case 'failed_deliveries':
        return 'Failed and cancelled deliveries requiring follow-up.';
      case 'reports':
        return 'Root-cause analysis and operational failure reporting.';
      case 'notifications':
        return 'System alerts and operational notifications.';
      case 'profile':
        return 'Your Operations Manager account and permissions.';
      case 'settings':
        return 'System configuration and operational preferences.';
      case 'tracking':
        return 'Track active deliveries and monitor real-time GPS locations.';
      default:
        return 'Fleet telemetry, system-wide analytics, and resolution control center.';
    }
  }

  Widget _buildBody(BuildContext context, DeliveryProvider deliveryProvider,
      EscalationProvider escalationProvider) {
    switch (_activeMenuId) {
      case 'analytics':
        return const AnalyticsScreen(isEmbedded: true);
      case 'monitoring':
        return const OperationsDeliveriesScreen(isEmbedded: true);
      case 'dispatchers':
        return const DispatcherManagementScreen(isEmbedded: true);
      case 'executives':
        return const ExecutiveManagementScreen(isEmbedded: true);
      case 'escalations':
        return const EscalationCenterScreen(isEmbedded: true);
      case 'failed_deliveries':
        return const FailedDeliveriesScreen(isEmbedded: true);
      case 'reports':
        return const FailureReportsScreen(isEmbedded: true);
      case 'notifications':
        return const NotificationsScreen(isEmbedded: true);
      case 'profile':
        return const OperationsProfileScreen(isEmbedded: true);
      case 'settings':
        return const OperationsSettingsScreen(isEmbedded: true);
      case 'tracking':
        return const DeliveryTrackingScreen(isEmbedded: true);
      default:
        return _buildDashboardOverview(
            context, deliveryProvider, escalationProvider);
    }
  }

  void _showResolveDialog(String escalationId) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Escalation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Enter resolution action notes to mark this issue as resolved:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'e.g., Customer contacted, re-routed to Hub B...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final provider =
                  Provider.of<EscalationProvider>(context, listen: false);
              await provider.updateEscalation(
                  escalationId, 'RESOLVED', notesController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isChecking) {
      return const AuthLoadingScreen();
    }
    if (!auth.isAuthenticated ||
        !RoleRouter.isRoleAllowed(
            auth.user?.role, ['OPERATIONS', 'OPERATIONS_MANAGER'])) {
      return const AccessDeniedView(requiredRoleName: 'Operations Manager');
    }

    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final escalationProvider = Provider.of<EscalationProvider>(context);

    const primarySidebarItems = [
      SidebarItem(
          title: 'Dashboard', icon: Icons.dashboard_rounded, id: 'dashboard'),
      SidebarItem(
          title: 'Analytics', icon: Icons.insights_rounded, id: 'analytics'),
      SidebarItem(
          title: 'Delivery Monitoring',
          icon: Icons.monitor_heart_outlined,
          id: 'monitoring'),
      SidebarItem(
          title: 'Manage Dispatchers',
          icon: Icons.badge_outlined,
          id: 'dispatchers'),
      SidebarItem(
          title: 'Manage Executives',
          icon: Icons.two_wheeler_rounded,
          id: 'executives'),
      SidebarItem(
          title: 'Escalation Center',
          icon: Icons.warning_amber_rounded,
          id: 'escalations'),
      SidebarItem(
          title: 'Failed Deliveries',
          icon: Icons.error_outline_rounded,
          id: 'failed_deliveries'),
      SidebarItem(
          title: 'Failure Reports',
          icon: Icons.assessment_outlined,
          id: 'reports'),
    ];

    return DashboardLayout(
      portalTitle: 'Operations Portal',
      activeMenuId: _activeMenuId,
      primaryMenuItems: primarySidebarItems,
      onMenuSelected: _handleMenuSelection,
      headerTitle: _headerTitle,
      headerSubtitle: _headerSubtitle,
      showSearch: _activeMenuId == 'dashboard',
      onSearchChanged: (q) => setState(() => _searchQuery = q),
      onRefresh: () {
        deliveryProvider.fetchDeliveries();
        escalationProvider.fetchEscalations();
      },
      body: _buildBody(context, deliveryProvider, escalationProvider),
    );
  }

  Widget _buildDashboardOverview(
      BuildContext context,
      DeliveryProvider deliveryProvider,
      EscalationProvider escalationProvider) {
    final deliveries = deliveryProvider.deliveries;
    final allEscalations = escalationProvider.escalations;

    // Filtered escalations if user types in search
    final q = _searchQuery.toLowerCase();
    final escalations = allEscalations.where((e) {
      if (q.isEmpty) return true;
      final t = e.delivery?.trackingNumber.toLowerCase() ?? '';
      final r = e.reason?.toLowerCase() ?? '';
      return t.contains(q) || r.contains(q);
    }).toList();

    // Statistics
    final total = deliveries.length;
    final inTransit = deliveries.where((d) => d.status == 'IN_TRANSIT').length;
    final assigned = deliveries.where((d) => d.status == 'ASSIGNED').length;
    final active = inTransit + assigned;
    final delivered = deliveries.where((d) => d.status == 'DELIVERED').length;
    final failed = deliveries.where((d) => d.status == 'FAILED').length;

    // Rates
    final completedTotal = delivered + failed;
    final successRate = completedTotal > 0
        ? ((delivered / completedTotal) * 100).toStringAsFixed(1)
        : '100.0';
    final failureRate = completedTotal > 0
        ? ((failed / completedTotal) * 100).toStringAsFixed(1)
        : '0.0';

    return RefreshIndicator(
      onRefresh: () async {
        await deliveryProvider.fetchDeliveries();
        await escalationProvider.fetchEscalations();
      },
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
                      subtitle: 'Lifetime system shipments',
                    ),
                    DashboardStatCard(
                      title: 'Active Deliveries',
                      value: '$active',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.cyanTeal,
                      badgeText: active > 0 ? '$inTransit in transit' : null,
                      badgeColor: AppColors.cyanTeal,
                      subtitle: 'Currently assigned or en route',
                    ),
                    DashboardStatCard(
                      title: 'Successful Deliveries',
                      value: '$delivered',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      badgeText: '$successRate%',
                      badgeColor: AppColors.success,
                      subtitle: 'Signed & verified deliveries',
                    ),
                    DashboardStatCard(
                      title: 'Failed Deliveries',
                      value: '$failed',
                      icon: Icons.error_outline_rounded,
                      color: AppColors.error,
                      badgeText: failed > 0 ? 'Review' : null,
                      badgeColor: AppColors.error,
                      subtitle: 'Requires operational escalation',
                      onTap: () => _handleMenuSelection('failed_deliveries'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── 2. Analytics & Performance Section ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 18, color: AppColors.purple),
                    SizedBox(width: 6),
                    Text(
                      'Delivery Performance Telemetry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _handleMenuSelection('analytics'),
                  child: const Text('View Full Analytics →',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.purple)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 760;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildPerformanceCard(
                              successRate, failureRate, delivered, failed)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildStatusDistributionCard(deliveries)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildPerformanceCard(
                          successRate, failureRate, delivered, failed),
                      const SizedBox(height: 12),
                      _buildStatusDistributionCard(deliveries),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 28),

            // ── 3. Recent Escalations Section ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 6),
                    Text(
                      'Active Escalations Control',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${escalations.where((e) => e.status != "RESOLVED").length} Open',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (escalationProvider.isLoading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()))
            else if (escalations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        size: 40, color: AppColors.success),
                    SizedBox(height: 8),
                    Text('Zero Active Escalations',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.darkNavy)),
                    SizedBox(height: 4),
                    Text(
                        'All delivery operations are running without critical failure bottlenecks.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktopTable = constraints.maxWidth >= 780;
                  if (isDesktopTable) {
                    return _buildEscalationsTable(escalations);
                  } else {
                    return _buildEscalationsCardList(escalations);
                  }
                },
              ),

            const SizedBox(height: 28),

            // ── 4. Recent Activity Feed ──────────────────────────────
            const Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 18, color: AppColors.primaryBlue),
                SizedBox(width: 6),
                Text(
                  'Recent Operations Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildActivityFeed(deliveries, escalations),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
      String successRate, String failureRate, int delivered, int failed) {
    final sVal = (double.tryParse(successRate) ?? 100.0) / 100.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SUCCESS VS FAILURE RATE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary)),
              Icon(Icons.trending_up_rounded,
                  color: AppColors.success, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$successRate%',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success)),
              Text('$failureRate% Fail',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: sVal,
              minHeight: 8,
              backgroundColor: AppColors.error.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$delivered verified deliveries',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text('$failed reported issues',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionCard(List<dynamic> deliveries) {
    final pending = deliveries.where((d) => d.status == 'PENDING').length;
    final assigned = deliveries.where((d) => d.status == 'ASSIGNED').length;
    final inTransit = deliveries.where((d) => d.status == 'IN_TRANSIT').length;
    final delivered = deliveries.where((d) => d.status == 'DELIVERED').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUS DISTRIBUTION',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _distPill('Pending', '$pending', AppColors.warning),
              const SizedBox(width: 8),
              _distPill('Assigned', '$assigned', AppColors.primaryBlue),
              const SizedBox(width: 8),
              _distPill('In Transit', '$inTransit', AppColors.cyanTeal),
              const SizedBox(width: 8),
              _distPill('Delivered', '$delivered', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _distPill(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationsTable(List<EscalationModel> escalations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                    label: Text('ISSUE ID',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('DELIVERY ID',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('PRIORITY',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary))),
                DataColumn(
                    label: Text('REASON',
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
              rows: escalations.map((esc) {
                final isCritical =
                    esc.priority == 'CRITICAL' || esc.priority == 'HIGH';
                return DataRow(
                  cells: [
                    DataCell(Text(
                        'ESC-${esc.id.substring(0, esc.id.length > 5 ? 5 : esc.id.length).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(Text(esc.delivery?.trackingNumber ?? 'DS-ORD',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                            fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              (isCritical ? AppColors.error : AppColors.warning)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          esc.priority,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isCritical
                                ? AppColors.error
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(esc.reason ?? 'Delivery Failure',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(StatusBadge(status: esc.status)),
                    DataCell(
                      esc.status != 'RESOLVED'
                          ? ElevatedButton(
                              onPressed: () => _showResolveDialog(esc.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: const Size(70, 28),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Resolve',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            )
                          : const Text('Resolved ✓',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success)),
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

  Widget _buildEscalationsCardList(List<EscalationModel> escalations) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: escalations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final esc = escalations[index];
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
                    esc.delivery?.trackingNumber ?? 'DS-ORD',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.primaryBlue),
                  ),
                  StatusBadge(status: esc.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reason: ${esc.reason ?? "Delivery Exception"}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.error),
              ),
              const SizedBox(height: 4),
              Text(
                'Remarks: "${esc.remarks ?? "None"}"',
                style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              if (esc.status != 'RESOLVED')
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _showResolveDialog(esc.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Resolve Escalation',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityFeed(
      List<dynamic> deliveries, List<EscalationModel> escalations) {
    final recentDeliveries = deliveries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ...recentDeliveries.map((d) => _activityTile(
                icon: Icons.add_circle_outline_rounded,
                iconColor: AppColors.primaryBlue,
                title: 'Shipment ${d.trackingNumber} Created',
                subtitle: 'Destination: ${d.deliveryAddress}, ${d.city}',
                time: 'Recent',
              )),
          ...escalations.take(2).map((e) => _activityTile(
                icon: Icons.warning_rounded,
                iconColor: AppColors.error,
                title: 'Escalation Logged (${e.reason ?? "Exception"})',
                subtitle: 'Shipment: ${e.delivery?.trackingNumber ?? "N/A"}',
                time: 'Requires Review',
              )),
        ],
      ),
    );
  }

  Widget _activityTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
