import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_validators.dart';
import '../../providers/auth_provider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String portalTitle;
  final bool isEmbedded;

  const ProfileSettingsScreen({
    super.key,
    required this.portalTitle,
    this.isEmbedded = false,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isChangingPassword = false;
  String? _errorMessage;

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      if (auth.user == null && !auth.isChecking) {
        await auth.fetchUserProfile();
      }

      final user = auth.user;
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Profile information is unavailable.';
        });
        return;
      }

      _nameController.text = user.fullName;
      _phoneController.text = user.phone;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your profile. Please try again.';
      });
    }
  }

  Future<void> _handleChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();
    var obscureCurrent = true;
    var obscureNew = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Change Password'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(() {
                          obscureCurrent = !obscureCurrent;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() {
                          obscureNew = !obscureNew;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newCtrl.text != confirmCtrl.text) {
                    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                      const SnackBar(
                        content: Text('Passwords do not match.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );

    if (!(ok ?? false)) return;

    setState(() => _isChangingPassword = true);
    final response = await auth.changePassword(
      currentPassword: currentCtrl.text,
      newPassword: newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isChangingPassword = false);

    if (response.success) {
      _showMessage(response.message ?? 'Password changed successfully.',
          AppColors.success);
    } else {
      _showMessage(
          response.message ?? 'Unable to change password.', AppColors.error);
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    await auth.logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading settings...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline_rounded, size: 52),
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentRole = user?.roleDisplayName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.portalTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user?.fullName ?? 'Profile',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.email ?? 'No email available',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow(
                              'Full Name', user?.fullName ?? 'Not available'),
                          const Divider(height: 1, color: AppColors.divider),
                          _infoRow('Email', user?.email ?? 'Not available'),
                          const Divider(height: 1, color: AppColors.divider),
                          _infoRow(
                              'Phone Number', user?.phone ?? 'Not available'),
                          const Divider(height: 1, color: AppColors.divider),
                          _infoRow('Role', currentRole),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showEditProfileDialog(),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.lock_outline_rounded),
                            title: const Text('Change Password'),
                            onTap: _isChangingPassword
                                ? null
                                : _handleChangePassword,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.logout_rounded,
                                color: AppColors.error),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: AppColors.error),
                            ),
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Name cannot be empty.'),
                      backgroundColor: AppColors.error),
                );
                return;
              }
              if (phone.isNotEmpty) {
                final error = AppValidators.validateIndianMobileNumber(phone);
                if (error != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.error),
                    );
                  }
                  return;
                }
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final normalizedPhone = phoneController.text.trim().isNotEmpty
        ? (AppValidators.normalizeIndianMobileNumber(
                phoneController.text.trim()) ??
            phoneController.text.trim())
        : '';
    final success = await auth.updateUserProfile(
      fullName: nameController.text.trim(),
      phone: normalizedPhone,
    );
    if (!mounted) return;

    if (success) {
      await _loadProfile();
      _showMessage('Profile updated successfully.', AppColors.success);
    } else {
      _showMessage(auth.error ?? 'Failed to update profile.', AppColors.error);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
