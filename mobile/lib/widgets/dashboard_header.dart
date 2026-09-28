import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications/notifications_screen.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showSearch;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onRefresh;
  final List<Widget>? customActions;
  final bool isMobile;
  final VoidCallback? onMenuPressed;

  const DashboardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showSearch = true,
    this.onSearchChanged,
    this.onRefresh,
    this.customActions,
    this.isMobile = false,
    this.onMenuPressed,
  });

  void _showProfileModal(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  user?.initials ?? 'U',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.fullName ?? 'User Account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user?.roleDisplayName ?? 'Staff',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.email_outlined,
                    size: 20, color: AppColors.textSecondary),
                title: const Text('Email',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                subtitle: Text(user?.email ?? 'N/A',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkNavy)),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined,
                    size: 20, color: AppColors.textSecondary),
                title: const Text('Phone',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                subtitle: Text(
                    (user?.phone.isNotEmpty == true) ? user!.phone : 'Not provided',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkNavy)),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  auth.logout();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/welcome', (r) => false);
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final user = auth.user;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Mobile drawer toggle
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.darkNavy, size: 24),
              onPressed:
                  onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkNavy,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && !isMobile) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Search Field on Desktop/Tablet
          if (showSearch && !isMobile) ...[
            Container(
              width: 220,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search deliveries...',
                  hintStyle:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Refresh button if provided
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary, size: 20),
              tooltip: 'Refresh Data',
              onPressed: onRefresh,
            ),

          // Custom Actions
          if (customActions != null) ...customActions!,

          // Notification Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.darkNavy, size: 22),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        notifProvider.unreadCount > 9
                            ? '9+'
                            : '${notifProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),

          // User Profile Avatar
          InkWell(
            onTap: () => _showProfileModal(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 16 : 18,
                    backgroundColor:
                        AppColors.primaryBlue.withValues(alpha: 0.12),
                    child: Text(
                      user?.initials ?? 'U',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          user?.roleDisplayName ?? 'Staff',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: AppColors.textMuted),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
