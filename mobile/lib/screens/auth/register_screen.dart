import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_validators.dart';
import '../../core/utils/role_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'DISPATCHER';

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  final List<_RoleOption> _roles = const [
    _RoleOption(
      value: 'DISPATCHER',
      title: 'Dispatcher',
      subtitle: 'Manage and assign deliveries.',
      icon: Icons.dashboard_customize_rounded,
      gradient: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    ),
    _RoleOption(
      value: 'DELIVERY_EXECUTIVE',
      title: 'Field Executive',
      subtitle: 'Deliver and update tasks.',
      icon: Icons.local_shipping_rounded,
      gradient: [Color(0xFF0891B2), Color(0xFF06B6D4)],
    ),
    _RoleOption(
      value: 'OPERATIONS',
      title: 'Operations Manager',
      subtitle: 'Monitor and oversee operations.',
      icon: Icons.analytics_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF9333EA)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final cleanName = _nameController.text.trim();
    final cleanEmail = _emailController.text.trim().toLowerCase();
    final rawPhone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final role = _selectedRole.trim();

    // ── 1. Full Name Validation ──────────────────────────────────
    if (cleanName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name is required'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _formKey.currentState?.validate();
      return;
    }

    // ── 2. Email Validation ──────────────────────────────────────
    final emailError = AppValidators.validateEmail(cleanEmail);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _formKey.currentState?.validate();
      return;
    }

    // ── 3. Phone Number Validation ──────────────────────────────
    final phoneError = AppValidators.validateIndianMobileNumber(rawPhone);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _formKey.currentState?.validate();
      return;
    }

    // ── 4. Password Validation ───────────────────────────────────
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password is required'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _formKey.currentState?.validate();
      return;
    }

    // ── 5. Confirm Password Validation ───────────────────────────
    if (confirmPassword.isEmpty || password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _formKey.currentState?.validate();
      return;
    }

    // ── 6. Role Validation ───────────────────────────────────────
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final normalizedPhone =
        AppValidators.normalizeIndianMobileNumber(rawPhone) ?? rawPhone;

    debugPrint(
        '[Register] Submitting registration for email: $cleanEmail, phone: $normalizedPhone, role: $_selectedRole');

    final response = await auth.register(
      fullName: cleanName,
      email: cleanEmail,
      phone: normalizedPhone,
      password: password,
      confirmPassword: confirmPassword,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (response.success) {
      debugPrint(
          '[Register] Account created -> navigating to dashboard for role: $_selectedRole');
      final route = RoleRouter.getDashboardRoute(_selectedRole);
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } else {
      debugPrint('[Register] Registration failed: ${response.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            // ── Gradient Header ─────────────────────────────────────────────
            _GradientHeader(
              topPadding: media.padding.top,
              onBack: () => Navigator.pop(context),
              title: 'Create Account',
              subtitle: 'Join us and start managing your deliveries.',
            ),

            // ── Scrollable Form ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Error Banner ──────────────────────────────────────
                        if (auth.error != null)
                          _ErrorBanner(
                            message: auth.error!,
                            onDismiss: () => auth.clearError(),
                          ),

                        // ── Full Name ─────────────────────────────────────────
                        const _FieldLabel(label: 'Full Name'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            final clean = v.trim();
                            if (clean.length < 2) {
                              return 'Full name must be at least 2 characters';
                            }
                            if (RegExp(r'^\d+$').hasMatch(clean)) {
                              return 'Full name cannot contain numbers only';
                            }
                            if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(clean)) {
                              return 'Please enter a valid full name';
                            }
                            return null;
                          },
                          decoration: _fieldDecoration(
                            hint: 'John Doe',
                            icon: Icons.person_outline,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Email ─────────────────────────────────────────────
                        const _FieldLabel(label: 'Email Address'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.email,
                            AutofillHints.username,
                          ],
                          validator: AppValidators.validateEmail,
                          decoration: _fieldDecoration(
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Phone ─────────────────────────────────────────────
                        const _FieldLabel(label: 'Phone Number'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          validator: AppValidators.validateIndianMobileNumber,
                          decoration: _fieldDecoration(
                            hint: '9876543210 / +91 98765 43210',
                            icon: Icons.phone_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Password ──────────────────────────────────────────
                        const _FieldLabel(label: 'Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(v)) {
                              return 'Password must contain at least one uppercase letter';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(v)) {
                              return 'Password must contain at least one lowercase letter';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(v)) {
                              return 'Password must contain at least one number';
                            }
                            return null;
                          },
                          decoration: _fieldDecoration(
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Confirm Password ──────────────────────────────────
                        const _FieldLabel(label: 'Confirm Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _passwordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                          decoration: _fieldDecoration(
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // ── Role Selection ────────────────────────────────────
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5),
                                    Color(0xFF7C3AED),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Choose Your Role',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Text(
                            'Select the role that best describes your position.',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        ...(_roles.map((role) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RoleCard(
                                option: role,
                                isSelected: _selectedRole == role.value,
                                onTap: () =>
                                    setState(() => _selectedRole = role.value),
                              ),
                            ))),

                        const SizedBox(height: 26),

                        // ── Create Account Button ─────────────────────────────
                        _GradientButton(
                          label: 'Create Account',
                          isLoading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _handleRegister,
                        ),

                        const SizedBox(height: 24),

                        // ── Login Link ────────────────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: Color(0xFF4F46E5),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
      errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
    );
  }
}

// ── Role Option Model ──────────────────────────────────────────────────────────
class _RoleOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _RoleOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

// ── Role Card ──────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = option.gradient[0];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Gradient icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: option.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                option.icon,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color:
                          isSelected ? primaryColor : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: option.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared: Gradient Header ────────────────────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  final double topPadding;
  final VoidCallback onBack;
  final String title;
  final String subtitle;

  const _GradientHeader({
    required this.topPadding,
    required this.onBack,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF312E81),
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            left: -16,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.only(
              top: topPadding + 12,
              left: 8,
              right: 24,
              bottom: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: onBack,
                ),
                const SizedBox(height: 8),

                // Logo row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x30000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/DeliverSync logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_shipping_rounded,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                          children: [
                            TextSpan(
                              text: 'Deliver',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Sync',
                              style: TextStyle(color: Color(0xFF67E8F9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title & subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE0E7FF),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared: Field Label ────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

// ── Shared: Gradient Button ────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x404F46E5),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ── Shared: Error Banner ───────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
          ),
        ],
      ),
    );
  }
}
