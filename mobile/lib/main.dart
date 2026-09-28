import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';
import 'providers/escalation_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

import 'screens/auth/otp_verification_screen.dart';
import 'screens/dispatcher/dispatcher_dashboard_screen.dart';
import 'screens/executive/executive_dashboard_screen.dart';
import 'screens/operations/operations_dashboard_screen.dart';

import 'screens/dispatcher/create_delivery_screen.dart';
import 'screens/dispatcher/all_deliveries_screen.dart';
import 'screens/dispatcher/assign_delivery_screen.dart';
import 'screens/dispatcher/delivery_tracking_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/dispatcher/dispatcher_profile_screen.dart';
import 'screens/dispatcher/dispatcher_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }

  // Allow all orientations — the app is responsive for desktop, tablet, and phone.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => EscalationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const DeliverSyncApp(),
    ),
  );
}

class DeliverSyncApp extends StatelessWidget {
  const DeliverSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeliverSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/dispatcher': (_) => const DispatcherDashboardScreen(),
        '/dispatcher/create-delivery': (_) => const CreateDeliveryScreen(),
        '/dispatcher/deliveries': (_) => const AllDeliveriesScreen(),
        '/dispatcher/assign': (_) => const AssignDeliveryScreen(),
        '/dispatcher/tracking': (_) => const DeliveryTrackingScreen(),
        '/dispatcher/notifications': (_) => const NotificationsScreen(),
        '/dispatcher/profile': (_) => const DispatcherProfileScreen(),
        '/dispatcher/settings': (_) => const DispatcherSettingsScreen(),
        '/executive': (_) => const ExecutiveDashboardScreen(),
        '/operations': (_) => const OperationsDashboardScreen(),
        '/admin': (_) => const OperationsDashboardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/otp-verify') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: args?['phoneNumber'] as String? ?? '',
              verificationId: args?['verificationId'] as String? ?? '',
              resendToken: args?['resendToken'] as int?,
              email: args?['email'] as String? ?? '',
              role: args?['role'] as String?,
            ),
          );
        }
        // Fallback for unknown routes — prevents black screens
        debugPrint('[Router] Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: const Color(0xFFF8FAFF),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  Text('Page not found: ${settings.name}',
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
