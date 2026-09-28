import 'package:flutter_test/flutter_test.dart';
import 'package:deliversync_mobile/core/utils/app_validators.dart';

void main() {
  group('Email Validation Tests', () {
    test('Valid email addresses are accepted', () {
      expect(AppValidators.validateEmail('john@gmail.com'), isNull);
      expect(AppValidators.validateEmail('john.smith@gmail.com'), isNull);
      expect(AppValidators.validateEmail('john123@outlook.com'), isNull);
      expect(AppValidators.validateEmail('user.name123@yahoo.com'), isNull);
      expect(AppValidators.validateEmail('  john@gmail.com  '), isNull);
    });

    test('Invalid email addresses are rejected', () {
      expect(AppValidators.validateEmail('john@gmail'), isNotNull);
      expect(AppValidators.validateEmail('john@'), isNotNull);
      expect(AppValidators.validateEmail('@gmail.com'), isNotNull);
      expect(AppValidators.validateEmail('@gamil.com'), isNotNull);
      expect(AppValidators.validateEmail('john gmail.com'), isNotNull);
      expect(AppValidators.validateEmail('john..smith@gmail.com'), isNotNull);
      expect(AppValidators.validateEmail('john@gmail..com'), isNotNull);
      expect(AppValidators.validateEmail('john@.com'), isNotNull);
      expect(AppValidators.validateEmail('john@com'), isNotNull);
      expect(AppValidators.validateEmail(''), isNotNull);
      expect(AppValidators.validateEmail(null), isNotNull);
    });
  });

  group('Indian Mobile Number Validation Tests', () {
    test('Valid Indian mobile numbers are accepted', () {
      expect(AppValidators.validateIndianMobileNumber('9876543210'), isNull);
      expect(AppValidators.validateIndianMobileNumber('+919876543210'), isNull);
      expect(AppValidators.validateIndianMobileNumber('+91 98765 43210'), isNull);
      expect(AppValidators.validateIndianMobileNumber('8876543210'), isNull);
      expect(AppValidators.validateIndianMobileNumber('7876543210'), isNull);
      expect(AppValidators.validateIndianMobileNumber('6876543210'), isNull);
    });

    test('Invalid Indian mobile numbers are rejected', () {
      expect(AppValidators.validateIndianMobileNumber('1234567890'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber('5123456789'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber('98765'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber('987654321'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber('98765432101'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber('abcdefghij'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber('98765abc10'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber('+911234567890'), isNotNull);
      expect(AppValidators.validateIndianMobileNumber(''), isNotNull);
      expect(AppValidators.validateIndianMobileNumber(null), isNotNull);
    });

    test('Normalization to E.164 +91 format', () {
      expect(AppValidators.normalizeIndianMobileNumber('9876543210'), equals('+919876543210'));
      expect(AppValidators.normalizeIndianMobileNumber('+919876543210'), equals('+919876543210'));
      expect(AppValidators.normalizeIndianMobileNumber('+91 98765 43210'), equals('+919876543210'));
      expect(AppValidators.normalizeIndianMobileNumber('1234567890'), isNull);
    });
  });
}
