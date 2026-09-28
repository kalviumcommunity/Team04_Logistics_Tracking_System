import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class PhoneCaller {
  PhoneCaller._();

  /// Normalizes a phone number to standard international format (E.164).
  /// Especially handles Indian phone numbers (10 digits -> +91XXXXXXXXXX).
  /// Returns null if the number is missing, empty, or invalid.
  static String? normalizePhoneNumber(String? rawPhone) {
    if (rawPhone == null) return null;
    final trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return null;

    // Check if it already starts with '+'
    final hasPlus = trimmed.startsWith('+');

    // Extract all digits
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return null;

    // Reject all identical repeating dummy numbers (e.g. 0000000000, 1111111111)
    if (RegExp(r'^(\d)\1+$').hasMatch(digitsOnly)) {
      return null;
    }

    // If it started with '+', keep the country code with '+'
    if (hasPlus) {
      if (digitsOnly.length >= 7 && digitsOnly.length <= 15) {
        return '+$digitsOnly';
      }
      return null;
    }

    // Standard 10-digit Indian phone number
    if (digitsOnly.length == 10) {
      // Indian mobile numbers typically start with 6, 7, 8, 9
      return '+91$digitsOnly';
    }

    // 11-digit number starting with 0 (e.g. 09876543210)
    if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
      final stripped = digitsOnly.substring(1);
      return '+91$stripped';
    }

    // 12-digit number starting with 91 (e.g. 919876543210)
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }

    // General valid length between 7 and 15 digits
    if (digitsOnly.length >= 7 && digitsOnly.length <= 15) {
      return '+$digitsOnly';
    }

    return null;
  }

  /// Checks whether a phone number is valid and can be normalized.
  static bool isValidPhoneNumber(String? rawPhone) {
    return normalizePhoneNumber(rawPhone) != null;
  }

  /// Attempts to launch the native dialer with the customer's phone number.
  /// Shows appropriate DeliverSync styled feedback if missing, invalid, or unsupported.
  static Future<bool> makePhoneCall(
    BuildContext context,
    String? rawPhone, {
    String roleLabel = 'Customer',
  }) async {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      _showFeedback(
        context,
        message: '$roleLabel phone number is not available.',
        isError: true,
      );
      return false;
    }

    final normalized = normalizePhoneNumber(rawPhone);
    if (normalized == null) {
      _showFeedback(
        context,
        message: 'Invalid $roleLabel phone number.',
        isError: true,
      );
      return false;
    }

    final Uri telUri = Uri(scheme: 'tel', path: normalized);

    if (kIsWeb) {
      try {
        final canLaunch = await canLaunchUrl(telUri);
        if (canLaunch) {
          final launched = await launchUrl(telUri);
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('[PhoneCaller] Web launch error: $e');
      }

      if (context.mounted) {
        _showFeedback(
          context,
          message: 'Calling is available on the mobile application.',
          isError: false,
          icon: Icons.info_outline_rounded,
        );
      }
      return false;
    }

    // Mobile / Desktop platforms
    try {
      if (await canLaunchUrl(telUri)) {
        final launched = await launchUrl(
          telUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('[PhoneCaller] Mobile launch error: $e');
    }

    if (context.mounted) {
      _showFeedback(
        context,
        message: 'Calling is not available on this device.',
        isError: true,
      );
    }
    return false;
  }

  /// Attempts to launch the native SMS app with the customer's phone number.
  static Future<bool> sendSms(
    BuildContext context,
    String? rawPhone, {
    String roleLabel = 'Customer',
  }) async {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      _showFeedback(
        context,
        message: '$roleLabel phone number is not available.',
        isError: true,
      );
      return false;
    }

    final normalized = normalizePhoneNumber(rawPhone);
    if (normalized == null) {
      _showFeedback(
        context,
        message: 'Invalid $roleLabel phone number.',
        isError: true,
      );
      return false;
    }

    final Uri smsUri = Uri(scheme: 'sms', path: normalized);

    if (kIsWeb) {
      if (context.mounted) {
        _showFeedback(
          context,
          message: 'SMS is available on the mobile application.',
          isError: false,
          icon: Icons.info_outline_rounded,
        );
      }
      return false;
    }

    try {
      if (await canLaunchUrl(smsUri)) {
        final launched = await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('[PhoneCaller] SMS launch error: $e');
    }

    if (context.mounted) {
      _showFeedback(
        context,
        message: 'SMS is not available on this device.',
        isError: true,
      );
    }
    return false;
  }

  static void _showFeedback(
    BuildContext context, {
    required String message,
    required bool isError,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ??
                  (isError
                      ? Icons.error_outline_rounded
                      : Icons.phone_in_talk_rounded),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.darkNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
