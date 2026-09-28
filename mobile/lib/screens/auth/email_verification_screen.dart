import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/role_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? role;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.role,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _resendTimer;
  Timer? _checkTimer;
  int _resendCountdown = 0;
  bool _checking = false;
  bool _resending = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    // Auto-poll every 5 seconds for email verification
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollVerificationStatus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollVerificationStatus() async {
    if (!mounted || _checking) return;
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();
    if (!mounted) return;
    if (verified) {
      _checkTimer?.cancel();
      _navigateToDashboard(auth.user?.role ?? widget.role);
    }
  }

  Future<void> _manualCheckVerification() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _statusMessage = null;
    });
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();
    if (!mounted) return;
    if (verified) {
      _checkTimer?.cancel();
      _navigateToDashboard(auth.user?.role ?? widget.role);
    } else {
      setState(() {
        _checking = false;
        _statusMessage =
            'Email not verified yet. Please check your inbox and click the verification link.';
        _statusIsError = true;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resending || _resendCountdown > 0) return;
    setState(() {
      _resending = true;
      _statusMessage = null;
    });
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendEmailVerification();
    if (!mounted) return;
    if (sent) {
      setState(() {
        _resending = false;
        _resendCountdown = 60;
        _statusMessage = 'Verification email sent! Please check your inbox.';
        _statusIsError = false;
      });
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _resendCountdown--);
        if (_resendCountdown <= 0) t.cancel();
      });
    } else {
      setState(() {
        _resending = false;
        _statusMessage =
            'Could not send email. You may already be verified or there was a network error.';
        _statusIsError = true;
      });
    }
  }

  void _navigateToDashboard(String? role) {
    final route = RoleRouter.getDashboardRoute(role);
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  Future<void> _signOutAndLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.darkNavy, AppColors.purple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'DeliverSync',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.darkNavy,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE0E7FF), Color(0xFFEDE9FE)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_unread_rounded,
                        size: 40, color: AppColors.purple),
                  ),
                ),

                const Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Open the email and click the verification link, then tap the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 28),

                // Status message
                if (_statusMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _statusIsError
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _statusIsError
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIsError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_rounded,
                          color: _statusIsError
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _statusIsError
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Primary CTA
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _checking ? null : _manualCheckVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.verified_user_rounded, size: 20),
                    label: Text(
                      _checking ? 'Checking...' : "I've Verified My Email",
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Resend email
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: (_resending || _resendCountdown > 0)
                        ? null
                        : _resendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      side: const BorderSide(color: AppColors.purple),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: AppColors.purple, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _resendCountdown > 0
                          ? 'Resend in ${_resendCountdown}s'
                          : 'Resend Verification Email',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: _signOutAndLogin,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Sign in with a different account'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Check your spam / junk folder if you do not see the email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
