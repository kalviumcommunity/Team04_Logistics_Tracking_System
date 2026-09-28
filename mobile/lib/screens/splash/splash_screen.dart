import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/role_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6)),
    );
    _controller.forward();
    _initializeApp();
  }

  /// Waits for Firebase Auth to finish restoring the session from IndexedDB
  /// (Flutter Web), then routes the user to their dashboard or the welcome page.
  ///
  /// DO NOT call auth.checkSession() here — it reads currentUser synchronously,
  /// which is null on web while Firebase is still restoring from IndexedDB.
  /// Instead, we wait for AuthProvider._initAuthListener()'s authStateChanges()
  /// stream to resolve (isChecking → false) using a Completer + ChangeNotifier
  /// listener, with a 10-second safety timeout.
  Future<void> _initializeApp() async {
    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // If auth hasn't resolved yet, wait for authStateChanges() to fire.
    if (auth.isChecking) {
      final completer = Completer<void>();

      void listener() {
        if (!auth.isChecking && !completer.isCompleted) {
          completer.complete();
        }
      }

      auth.addListener(listener);

      try {
        await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // Safety: proceed even if Firebase takes unexpectedly long
            debugPrint('[Splash] Auth check timed out — proceeding anyway.');
          },
        );
      } finally {
        auth.removeListener(listener);
      }
    }

    if (!mounted) return;

    if (auth.isAuthenticated && auth.user != null) {
      final route = RoleRouter.getDashboardRoute(auth.user!.role);
      debugPrint('[Splash] Authenticated as ${auth.user!.role} → $route');
      Navigator.pushReplacementNamed(context, route);
    } else {
      debugPrint('[Splash] Not authenticated → /welcome');
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.cyanTeal.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/DeliverSync logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sync_rounded,
                        color: AppColors.cyanTeal,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'sans-serif',
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                          text: 'Deliver',
                          style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: 'Sync',
                          style: TextStyle(color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '"Delivering trust, every mile."',
                  style: TextStyle(
                    color: AppColors.cyanTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue.withValues(alpha: 0.7),
                    strokeWidth: 2.5,
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
