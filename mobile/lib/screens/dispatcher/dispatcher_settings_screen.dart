import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_validators.dart';
import '../../providers/auth_provider.dart';

class DispatcherSettingsScreen extends StatefulWidget {
  final bool isEmbedded;

  const DispatcherSettingsScreen({super.key, this.isEmbedded = false});

  @override
  State<DispatcherSettingsScreen> createState() =>
      _DispatcherSettingsScreenState();
}

class _DispatcherSettingsScreenState extends State<DispatcherSettingsScreen> {
  // Account info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _savingProfile = false;
  bool? _emailVerified;

  // Dispatch settings
  bool _autoRefresh = true;
  bool _soundAlerts = true;
  bool _pushNotifications = true;
  bool _compactView = false;
  bool _autoAssignRecommendations = true;
  String _selectedHub = 'Central Logistics Hub, Bay 4';
  int _refreshInterval = 30; // seconds

  final List<String> _availableHubs = [
    'Central Logistics Hub, Bay 4',
    'North Metro Distribution Depot',
    'South Harbor Cargo Terminal',
    'East Industrial Express Center',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone;
    }
    final verified = await auth.checkEmailVerified();
    if (mounted) setState(() => _emailVerified = verified);
  }

  Future<void> _saveProfile() async {
    if (_savingProfile) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name cannot be empty.'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (phone.isNotEmpty) {
      final phoneError = AppValidators.validateIndianMobileNumber(phone);
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(phoneError), backgroundColor: AppColors.error),
        );
        return;
      }
    }
    setState(() => _savingProfile = true);
    final auth = context.read<AuthProvider>();
    final normalizedPhone = phone.isNotEmpty
        ? (AppValidators.normalizeIndianMobileNumber(phone) ?? phone)
        : '';
    final ok = await auth.updateUserProfile(fullName: name, phone: normalizedPhone);
    if (!mounted) return;
    setState(() => _savingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(ok ? 'Profile updated successfully!' : 'Failed to update profile.'),
      ]),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _sendVerificationEmail() async {
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent
          ? 'Verification email sent! Check your inbox.'
          : 'Could not send email. You may already be verified.'),
      backgroundColor: sent ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDlg(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDlg(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final auth = context.read<AuthProvider>();
                final resp = await auth.changePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(resp.message ?? (resp.success ? 'Password changed!' : 'Failed.')),
                  backgroundColor: resp.success ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _saveNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Settings saved successfully!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Local Cache',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
            'This will clear temporary stored shipment images and logs. Your account session will remain active.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local cache cleared successfully.'),
                  backgroundColor: AppColors.darkNavy,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear Cache',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.darkNavy, AppColors.secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispatcher Portal Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Customize notification triggers, default hub routing, and dispatch views.',
                            style: TextStyle(
                                color: Color(0xFFE2E8F0), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Account Information ---
              _buildSection(
                title: 'Account Information',
                icon: Icons.manage_accounts_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<AuthProvider>(builder: (_, auth, __) {
                          final user = auth.user;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user?.email ?? '—',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user?.role ?? 'DISPATCHER',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryBlue),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(
                                      Icons.person_outline_rounded, size: 20),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(
                                      Icons.phone_outlined, size: 20),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _savingProfile ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _savingProfile
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_rounded, size: 18),
                            label: Text(
                              _savingProfile ? 'Saving...' : 'Save Changes',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Security ---
              _buildSection(
                title: 'Security',
                icon: Icons.security_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email Verification',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkNavy)),
                              Text(
                                _emailVerified == null
                                    ? 'Checking...'
                                    : _emailVerified!
                                        ? 'Your email is verified.'
                                        : 'Email not verified.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _emailVerified == true
                                        ? AppColors.success
                                        : AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (_emailVerified == false)
                          TextButton(
                            onPressed: _sendVerificationEmail,
                            child: const Text('Send Link',
                                style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          )
                        else if (_emailVerified == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Verified',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textSecondary, size: 20),
                    title: const Text('Change Password',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy)),
                    subtitle: const Text('Update your login password',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textSecondary),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 20),
                    title: const Text('Sign Out',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error)),
                    subtitle: const Text('End your current session',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    onTap: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Dispatch Operations & Hub Preferences
              _buildSection(
                title: 'Dispatch & Logistics Preferences',
                icon: Icons.storefront_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Primary Dispatch Warehouse Hub',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedHub,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _availableHubs.map((hub) {
                            return DropdownMenuItem(
                              value: hub,
                              child: Text(hub,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkNavy)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedHub = val);
                              _saveNotification();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _buildSwitchTile(
                    title: 'Smart Driver Recommendations',
                    subtitle:
                        'Automatically prioritize couriers with zero active load',
                    value: _autoAssignRecommendations,
                    onChanged: (v) {
                      setState(() => _autoAssignRecommendations = v);
                      _saveNotification();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Real-Time Sync & Notifications
              _buildSection(
                title: 'Live Sync & Alerts',
                icon: Icons.notifications_active_outlined,
                children: [
                  _buildSwitchTile(
                    title: 'Auto-Refresh Orders',
                    subtitle:
                        'Periodically poll server for new orders & status changes',
                    value: _autoRefresh,
                    onChanged: (v) {
                      setState(() => _autoRefresh = v);
                      _saveNotification();
                    },
                  ),
                  if (_autoRefresh) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Refresh Interval',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkNavy),
                          ),
                          DropdownButton<int>(
                            value: _refreshInterval,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                  value: 15, child: Text('15 seconds')),
                              DropdownMenuItem(
                                  value: 30, child: Text('30 seconds')),
                              DropdownMenuItem(
                                  value: 60, child: Text('60 seconds')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _refreshInterval = v);
                                _saveNotification();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 1, color: AppColors.divider),
                  _buildSwitchTile(
                    title: 'Sound Alerts for Critical Events',
                    subtitle:
                        'Chime audio for delivery failure reports & cancellations',
                    value: _soundAlerts,
                    onChanged: (v) {
                      setState(() => _soundAlerts = v);
                      _saveNotification();
                    },
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle:
                        'Receive high-priority desktop & mobile notifications',
                    value: _pushNotifications,
                    onChanged: (v) {
                      setState(() => _pushNotifications = v);
                      _saveNotification();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. UI Display Options
              _buildSection(
                title: 'Appearance & Display',
                icon: Icons.palette_outlined,
                children: [
                  _buildSwitchTile(
                    title: 'Compact Density Mode',
                    subtitle:
                        'Fit more delivery table rows on larger display screens',
                    value: _compactView,
                    onChanged: (v) {
                      setState(() => _compactView = v);
                      _saveNotification();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4. System Status & Storage
              _buildSection(
                title: 'System Health & Maintenance',
                icon: Icons.dns_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Backend Connection',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Connected (Cloud Firestore)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Version',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'DeliverSync Dispatch Suite v1.0.0',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: _clearCache,
                          icon: const Icon(Icons.delete_sweep_outlined,
                              size: 16),
                          label: const Text('Clear Cache',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
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
          'Settings',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
      ),
      body: content,
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
