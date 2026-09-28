import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../dispatcher/delivery_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isEmbedded;

  const NotificationsScreen({super.key, this.isEmbedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
      }
    });
  }

  void _onNotificationTap(
      NotificationModel notif, NotificationProvider provider) {
    if (!notif.isRead) {
      provider.markAsRead(notif.id);
    }

    if (notif.link != null && notif.link!.isNotEmpty) {
      final link = notif.link!;
      if (link.contains('/deliveries/')) {
        final id = link.split('/deliveries/').last.replaceAll('/', '').trim();
        if (id.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeliveryDetailsScreen(deliveryId: id),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final allNotifications = notificationProvider.notifications;

    final filtered = allNotifications.where((n) {
      if (_selectedCategory == 'UNREAD') return !n.isRead;
      if (_selectedCategory == 'ASSIGNMENT') {
        return n.type == 'ASSIGNMENT';
      }
      if (_selectedCategory == 'STATUS_CHANGE') {
        return n.type == 'STATUS_CHANGE';
      }
      if (_selectedCategory == 'ESCALATION') {
        return n.type.contains('ESCALATION');
      }
      return true;
    }).toList();

    Widget content = RefreshIndicator(
      onRefresh: () => notificationProvider.fetchNotifications(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All', allNotifications.length),
                      _buildFilterChip(
                          'UNREAD', 'Unread', notificationProvider.unreadCount),
                      _buildFilterChip(
                        'ASSIGNMENT',
                        'Assignments',
                        allNotifications
                            .where((n) => n.type == 'ASSIGNMENT')
                            .length,
                      ),
                      _buildFilterChip(
                        'STATUS_CHANGE',
                        'Status Updates',
                        allNotifications
                            .where((n) => n.type == 'STATUS_CHANGE')
                            .length,
                      ),
                      _buildFilterChip(
                        'ESCALATION',
                        'Alerts',
                        allNotifications
                            .where((n) => n.type.contains('ESCALATION'))
                            .length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded,
                              size: 44, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'All Caught Up!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCategory != 'ALL'
                              ? 'No notifications in "$_selectedCategory" category.'
                              : 'Real-time dispatch updates and task assignments will appear here.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return InkWell(
                        onTap: () =>
                            _onNotificationTap(notif, notificationProvider),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? Colors.white
                                : AppColors.primaryBlue
                                    .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: notif.isRead
                                  ? AppColors.border
                                  : AppColors.primaryBlue
                                      .withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getNotificationIconColor(notif.type)
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getNotificationIcon(notif.type),
                                  size: 18,
                                  color:
                                      _getNotificationIconColor(notif.type),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontWeight: notif.isRead
                                                  ? FontWeight.w700
                                                  : FontWeight.w900,
                                              fontSize: 13,
                                              color: AppColors.darkNavy,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimeAgo(notif.createdAt),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (notif.link != null &&
                                        notif.link!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      const Row(
                                        children: [
                                          Text(
                                            'View Details',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 12,
                                              color: AppColors.primaryBlue),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!notif.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
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
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text(
                'Mark all as read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildFilterChip(String key, String label, int count) {
    final isSelected = _selectedCategory == key;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.darkNavy,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        selectedColor: AppColors.primaryBlue,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _selectedCategory = key),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'ASSIGNMENT':
        return Icons.assignment_ind_rounded;
      case 'STATUS_CHANGE':
        return Icons.local_shipping_rounded;
      case 'ESCALATION':
      case 'ESCALATION_RESOLVED':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationIconColor(String type) {
    switch (type) {
      case 'ASSIGNMENT':
        return AppColors.primaryBlue;
      case 'STATUS_CHANGE':
        return AppColors.cyanTeal;
      case 'ESCALATION':
        return AppColors.error;
      case 'ESCALATION_RESOLVED':
        return AppColors.success;
      default:
        return AppColors.purple;
    }
  }

  String _formatTimeAgo(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

