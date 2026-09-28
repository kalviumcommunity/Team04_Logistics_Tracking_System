import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final String id;
  final int? badge;
  final Color? badgeColor;

  const SidebarItem({
    required this.title,
    required this.icon,
    required this.id,
    this.badge,
    this.badgeColor,
  });
}

class AppSidebar extends StatelessWidget {
  final String portalTitle;
  final String activeItemId;
  final List<SidebarItem> primaryItems;
  final List<SidebarItem>? secondaryItems;
  final ValueChanged<String> onItemSelected;
  final bool isDrawer;

  const AppSidebar({
    super.key,
    required this.portalTitle,
    required this.activeItemId,
    required this.primaryItems,
    this.secondaryItems,
    required this.onItemSelected,
    this.isDrawer = false,
  });

  void _handleItemTap(BuildContext context, String id) {
    if (id == 'logout') {
      _showLogoutDialog(context);
      return;
    }
    onItemSelected(id);
    if (isDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content:
            const Text('Are you sure you want to sign out of DeliverSync?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isDrawer && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isDrawer
            ? null
            : const Border(
                right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Sidebar Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkNavy.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/DeliverSync logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sync_rounded,
                          color: AppColors.cyanTeal,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'sans-serif',
                            ),
                            children: [
                              TextSpan(
                                text: 'Deliver',
                                style: TextStyle(color: AppColors.darkNavy),
                              ),
                              TextSpan(
                                text: 'Sync',
                                style: TextStyle(color: AppColors.primaryBlue),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          portalTitle,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyanTeal,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // ── Navigation Menu Items ────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  _buildSectionHeader('MAIN MENU'),
                  ...primaryItems.map((item) => _buildMenuItem(context, item)),
                  if (secondaryItems != null && secondaryItems!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader('MANAGEMENT'),
                    ...secondaryItems!
                        .map((item) => _buildMenuItem(context, item)),
                  ],
                  const SizedBox(height: 16),
                  _buildSectionHeader('ACCOUNT'),
                  _buildMenuItem(
                    context,
                    const SidebarItem(
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        id: 'notifications'),
                  ),
                  _buildMenuItem(
                    context,
                    const SidebarItem(
                        title: 'Profile',
                        icon: Icons.person_outline_rounded,
                        id: 'profile'),
                  ),
                  _buildMenuItem(
                    context,
                    const SidebarItem(
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        id: 'settings'),
                  ),
                ],
              ),
            ),

            // ── Bottom Profile & Logout ───────────────────────
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.primaryBlue.withValues(alpha: 0.12),
                        child: Text(
                          user?.initials ?? 'U',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User Account',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.roleDisplayName ?? 'Staff',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _handleItemTap(context, 'logout'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 9, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, SidebarItem item) {
    final isSelected = activeItemId == item.id;
    final notifProvider =
        Provider.of<NotificationProvider>(context);
    final badgeCount =
        item.id == 'notifications' ? notifProvider.unreadCount : item.badge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _handleItemTap(context, item.id),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : (item.badgeColor ?? AppColors.primaryBlue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? (item.badgeColor ?? AppColors.primaryBlue)
                            : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
