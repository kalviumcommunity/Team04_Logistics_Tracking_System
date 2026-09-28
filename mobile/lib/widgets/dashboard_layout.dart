import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'app_sidebar.dart';
import 'dashboard_header.dart';

class DashboardLayout extends StatelessWidget {
  final String portalTitle;
  final String activeMenuId;
  final List<SidebarItem> primaryMenuItems;
  final List<SidebarItem>? secondaryMenuItems;
  final ValueChanged<String> onMenuSelected;
  final String headerTitle;
  final String? headerSubtitle;
  final bool showSearch;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onRefresh;
  final List<Widget>? headerActions;
  final Widget? floatingActionButton;
  final Widget body;

  const DashboardLayout({
    super.key,
    required this.portalTitle,
    required this.activeMenuId,
    required this.primaryMenuItems,
    this.secondaryMenuItems,
    required this.onMenuSelected,
    required this.headerTitle,
    this.headerSubtitle,
    this.showSearch = true,
    this.onSearchChanged,
    this.onRefresh,
    this.headerActions,
    this.floatingActionButton,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        final sidebarWidget = AppSidebar(
          portalTitle: portalTitle,
          activeItemId: activeMenuId,
          primaryItems: primaryMenuItems,
          secondaryItems: secondaryMenuItems,
          onItemSelected: onMenuSelected,
          isDrawer: !isDesktop,
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            floatingActionButton: floatingActionButton,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fixed Desktop Sidebar
                sidebarWidget,

                // Main Content Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Header
                      DashboardHeader(
                        title: headerTitle,
                        subtitle: headerSubtitle,
                        showSearch: showSearch,
                        onSearchChanged: onSearchChanged,
                        onRefresh: onRefresh,
                        customActions: headerActions,
                        isMobile: false,
                      ),

                      // Content Body
                      Expanded(
                        child: SelectionArea(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: body,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile & Tablet with Drawer
          return Scaffold(
            backgroundColor: AppColors.background,
            drawer: Drawer(
              elevation: 4,
              child: sidebarWidget,
            ),
            floatingActionButton: floatingActionButton,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardHeader(
                    title: headerTitle,
                    subtitle: headerSubtitle,
                    showSearch: showSearch,
                    onSearchChanged: onSearchChanged,
                    onRefresh: onRefresh,
                    customActions: headerActions,
                    isMobile: true,
                  ),
                  Expanded(
                    child: SelectionArea(child: body),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
