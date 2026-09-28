import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/access_denied_view.dart';
import '../../widgets/auth_loading_screen.dart';

class RoleRouter {
  /// Returns the corresponding dashboard route for a given role.
  static String getDashboardRoute(String? role) {
    if (role == null || role.trim().isEmpty) return '/welcome';
    final normalized = role.trim().toUpperCase();
    switch (normalized) {
      case 'ADMIN':
      case 'OPERATIONS':
      case 'OPERATIONS_MANAGER':
        return '/operations';
      case 'DISPATCHER':
        return '/dispatcher';
      case 'EXECUTIVE':
      case 'DELIVERY_EXECUTIVE':
      case 'FIELD_EXECUTIVE':
        return '/executive';
      default:
        return '/welcome';
    }
  }

  /// Checks if the user's role matches any of the allowed roles.
  static bool isRoleAllowed(String? userRole, List<String> allowedRoles) {
    if (userRole == null || userRole.trim().isEmpty) return false;
    final normalizedUser = userRole.trim().toUpperCase();
    for (final role in allowedRoles) {
      final normalizedRole = role.trim().toUpperCase();
      if (normalizedUser == normalizedRole) return true;

      // Group Executive roles
      final isUserExec = normalizedUser == 'EXECUTIVE' ||
          normalizedUser == 'DELIVERY_EXECUTIVE' ||
          normalizedUser == 'FIELD_EXECUTIVE';
      final isRoleExec = normalizedRole == 'EXECUTIVE' ||
          normalizedRole == 'DELIVERY_EXECUTIVE' ||
          normalizedRole == 'FIELD_EXECUTIVE';
      if (isUserExec && isRoleExec) return true;

      // Group Admin / Operations roles
      final isUserAdmin = normalizedUser == 'ADMIN' ||
          normalizedUser == 'OPERATIONS' ||
          normalizedUser == 'OPERATIONS_MANAGER';
      final isRoleAdmin = normalizedRole == 'ADMIN' ||
          normalizedRole == 'OPERATIONS' ||
          normalizedRole == 'OPERATIONS_MANAGER';
      if (isUserAdmin && isRoleAdmin) return true;
    }
    return false;
  }
}

/// A route wrapper that protects routes according to user authentication and roles.
/// Renders [AuthLoadingScreen] while session is restoring, [AccessDeniedView] if
/// unauthenticated or role is unauthorized, and [child] if authorized.
class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final String requiredRoleName;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.requiredRoleName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isChecking) {
      return const AuthLoadingScreen();
    }

    if (!auth.isAuthenticated ||
        !RoleRouter.isRoleAllowed(auth.user?.role, allowedRoles)) {
      return AccessDeniedView(requiredRoleName: requiredRoleName);
    }

    return child;
  }
}

