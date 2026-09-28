import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AuthLoadingScreen extends StatelessWidget {
  final String message;

  const AuthLoadingScreen({
    super.key,
    this.message = 'Restoring your session...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo mark container
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.cyanTeal.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyanTeal.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/DeliverSync logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.sync_rounded,
                      color: AppColors.cyanTeal,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // DeliverSync brand name
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Deliver',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'Sync',
                      style: TextStyle(color: AppColors.cyanTeal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Spinner
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.cyanTeal,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Checking authentication and user permissions...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
