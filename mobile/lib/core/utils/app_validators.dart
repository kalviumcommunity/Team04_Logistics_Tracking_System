class AppValidators {
  AppValidators._();

  /// Validates email address format strictly.
  /// Rejects invalid formats: abc, abc@, abc@gmail, @gmail.com, test@, test@., test..test@gmail.com, whitespace.
  /// Returns null if valid, or a user-facing error message.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a valid email address.';
    }
    final clean = value.trim().toLowerCase();

    // Reject whitespace inside
    if (clean.contains(' ') || clean.contains('\t') || clean.contains('\n')) {
      return 'Please enter a valid email address.';
    }

    // Reject consecutive dots
    if (clean.contains('..')) {
      return 'Please enter a valid email address.';
    }

    // Must contain exactly one @
    final atParts = clean.split('@');
    if (atParts.length != 2) {
      return 'Please enter a valid email address.';
    }

    final local = atParts[0];
    final domain = atParts[1];

    if (local.isEmpty || domain.isEmpty) {
      return 'Please enter a valid email address.';
    }

    if (local.startsWith('.') || local.endsWith('.')) {
      return 'Please enter a valid email address.';
    }

    // Check local part characters (RFC 5322 standard characters)
    final localRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+$");
    if (!localRegex.hasMatch(local)) {
      return 'Please enter a valid email address.';
    }

    // Check domain parts
    final domainParts = domain.split('.');
    if (domainParts.length < 2) {
      return 'Please enter a valid email address.';
    }

    for (final p in domainParts) {
      if (p.isEmpty || p.startsWith('-') || p.endsWith('-')) {
        return 'Please enter a valid email address.';
      }
      final partRegex = RegExp(r'^[a-zA-Z0-9-]+$');
      if (!partRegex.hasMatch(p)) {
        return 'Please enter a valid email address.';
      }
    }

    // TLD must be at least 2 alphabetic characters
    if (domainParts.last.length < 2 ||
        !RegExp(r'^[a-zA-Z]+$').hasMatch(domainParts.last)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  /// Validates Indian mobile numbers strictly.
  /// Must be 10 digits starting with 6, 7, 8, or 9.
  /// Handles optional prefixes like +91, 91, 0.
  /// Returns null if valid, or "Please enter a valid 10-digit Indian mobile number."
  static String? validateIndianMobileNumber(String? value) {
    const errorMsg = 'Please enter a valid 10-digit Indian mobile number.';

    if (value == null || value.trim().isEmpty) {
      return errorMsg;
    }

    var clean = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (clean.isEmpty) {
      return errorMsg;
    }

    // Check for alphabetic or special characters (other than optional leading +)
    final digitsOnly = clean.replaceAll(RegExp(r'^\+'), '');
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return errorMsg;
    }

    // Strip prefix if any
    if (clean.startsWith('+91')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('91') && clean.length == 12) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0') && clean.length == 11) {
      clean = clean.substring(1);
    }

    // Must be exactly 10 digits starting with 6, 7, 8, or 9
    if (clean.length != 10) {
      return errorMsg;
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return errorMsg;
    }

    return null;
  }

  /// Normalizes an Indian mobile number to E.164 (+91XXXXXXXXXX).
  /// Returns null if invalid.
  static String? normalizeIndianMobileNumber(String? value) {
    if (validateIndianMobileNumber(value) != null) return null;
    var clean = value!.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (clean.startsWith('+91')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('91') && clean.length == 12) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0') && clean.length == 11) {
      clean = clean.substring(1);
    }
    return '+91$clean';
  }

  /// Masks phone number for presentation: e.g. +91 98*** **210
  static String maskPhoneNumber(String phone) {
    final normalized = normalizeIndianMobileNumber(phone) ?? phone;
    if (normalized.startsWith('+91') && normalized.length == 13) {
      final national = normalized.substring(3);
      final first2 = national.substring(0, 2);
      final last3 = national.substring(7);
      return '+91 $first2*** **$last3';
    }
    return '+91 XXXXX XXXXX';
  }

  /// Fast boolean check for email validity.
  static bool isValidEmail(String? value) => validateEmail(value) == null;

  /// Fast boolean check for Indian phone validity.
  static bool isValidIndianMobileNumber(String? value) =>
      validateIndianMobileNumber(value) == null;
}
