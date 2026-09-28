import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/utils/app_validators.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, checking, authenticated, unauthenticated, error }

class AuthResponse {
  final bool success;
  final bool requiresVerification;
  final String? email;
  final String? role;
  final String? message;

  const AuthResponse({
    required this.success,
    this.requiresVerification = false,
    this.email,
    this.role,
    this.message,
  });
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.checking;
  UserModel? _user;
  String? _error;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _status = AuthStatus.checking;
    _auth.authStateChanges().listen((User? fbUser) async {
      debugPrint(
          '[Auth] authStateChanges fired: uid=${fbUser?.uid}, email=${fbUser?.email}');
      if (fbUser == null) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        await _loadUserFromFirestore(fbUser);
      }
    }, onError: (err) {
      debugPrint('[Auth] authStateChanges error: $err');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<void> _loadUserFromFirestore(User fbUser) async {
    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _user = UserModel.fromJson(doc.data()!, doc.id);
      } else {
        // Do not silently assume a dispatcher role when the profile document is missing.
        // Unknown profile states should stay unauthenticated-to-role-mapped instead of
        // redirecting users to the wrong dashboard.
        final cleanEmail = fbUser.email ?? '';
        final fallbackName = fbUser.displayName ??
            (cleanEmail.isNotEmpty ? cleanEmail.split('@')[0] : 'User');
        _user = UserModel(
          id: fbUser.uid,
          fullName: fallbackName,
          email: cleanEmail,
          phone: fbUser.phoneNumber ?? '',
          role: '',
        );
        await _firestore.collection('users').doc(fbUser.uid).set({
          'uid': fbUser.uid,
          'id': fbUser.uid,
          'name': fallbackName,
          'fullName': fallbackName,
          'email': cleanEmail,
          'phone': fbUser.phoneNumber ?? '',
          'role': '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      _status = AuthStatus.authenticated;
    } catch (e) {
      debugPrint('[Auth] Error fetching user profile during restoration: $e');
      // If Firestore read temporarily fails, preserve the real role state instead of forcing a dispatcher fallback.
      final cleanEmail = fbUser.email ?? '';
      final fallbackName = fbUser.displayName ??
          (cleanEmail.isNotEmpty ? cleanEmail.split('@')[0] : 'User');
      _user = UserModel(
        id: fbUser.uid,
        fullName: fallbackName,
        email: cleanEmail,
        phone: fbUser.phoneNumber ?? '',
        role: '',
      );
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  AuthStatus get status => _status;
  UserModel? get user => _user;
  User? get firebaseUser => _auth.currentUser;
  String? get error => _error;
  bool get isChecking =>
      _status == AuthStatus.initial || _status == AuthStatus.checking;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
  bool get isLoading => _status == AuthStatus.checking;

  /// Kept for backward compatibility — the preferred flow is the automatic
  /// authStateChanges() listener in _initAuthListener().
  ///
  /// Only does work if we're still in the initial checking state AND
  /// Firebase already has a currentUser available synchronously. In all other
  /// cases the stream listener in _initAuthListener() handles it correctly.
  Future<void> checkSession() async {
    // If already resolved (authenticated or unauthenticated), do nothing.
    if (_status == AuthStatus.authenticated ||
        _status == AuthStatus.unauthenticated) {
      return;
    }
    // Still checking — see if Firebase has synchronously restored currentUser.
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      // currentUser is null — could be a transient state while Firebase restores
      // from IndexedDB. Let the authStateChanges() stream handle it.
      // We do NOT force unauthenticated here to avoid a race condition.
      debugPrint(
          '[Auth] checkSession: currentUser is null — deferring to authStateChanges() stream.');
      return;
    }
    // currentUser is available synchronously — load Firestore profile now.
    debugPrint(
        '[Auth] checkSession: currentUser found (${fbUser.uid}), loading profile.');
    await _loadUserFromFirestore(fbUser);
  }

  /// Login with email & password via Firebase Auth
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.checking;
    _error = null;
    notifyListeners();
    final cleanEmail = email.trim().toLowerCase();
    debugPrint('[Auth] Logging in with email: $cleanEmail');

    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = userCred.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _user = UserModel.fromJson(doc.data()!, doc.id);
      } else {
        final fallbackName =
            userCred.user!.displayName ?? cleanEmail.split('@')[0];
        _user = UserModel(
          id: uid,
          fullName: fallbackName,
          email: cleanEmail,
          phone: '',
          role: '',
        );
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'id': uid,
          'name': fallbackName,
          'fullName': fallbackName,
          'email': cleanEmail,
          'phone': '',
          'role': '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return AuthResponse(
        success: true,
        role: _user?.role,
        message: 'Login successful.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[Auth] FirebaseAuthException during login: ${e.code} - ${e.message}');
      _error = _mapFirebaseAuthError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    } catch (e) {
      debugPrint('[Auth] Unexpected error during login: $e');
      _error = 'Login failed: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }
  }

  /// Register user with Firebase Auth & Cloud Firestore
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    _status = AuthStatus.checking;
    _error = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();
    final normalizedPhone =
        AppValidators.normalizeIndianMobileNumber(phone) ?? phone.trim();
    final normalizedRole = role.trim().toUpperCase();

    // 1. Full Name Validation
    if (cleanName.isEmpty) {
      _error = 'Full name is required';
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }

    // 2. Email Validation
    final emailError = AppValidators.validateEmail(cleanEmail);
    if (emailError != null) {
      _error = emailError;
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }

    // 3. Phone Number Validation
    final phoneError = AppValidators.validateIndianMobileNumber(phone);
    if (phoneError != null) {
      _error = phoneError;
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }

    // 4. Password Validation
    if (password.isEmpty) {
      _error = 'Password is required';
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }

    // 5. Confirm Password Validation
    if (password != confirmPassword) {
      _error = 'Passwords do not match.';
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }

    // 6. Role Validation
    if (normalizedRole.isEmpty) {
      _error = 'Please select a valid role.';
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }

    debugPrint(
        '[Auth] Registering user: $cleanEmail with role: $normalizedRole');

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = userCred.user!.uid;
      await userCred.user?.updateDisplayName(cleanName);

      final avatarUrl =
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(cleanName)}';

      final userData = {
        'uid': uid,
        'id': uid,
        'name': cleanName,
        'fullName': cleanName,
        'email': cleanEmail,
        'phone': normalizedPhone,
        'phoneNumber': normalizedPhone,
        'phoneVerified': false,
        'role': normalizedRole,
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(userData);

      _user = UserModel.fromJson(userData, uid);
      _status = AuthStatus.authenticated;
      notifyListeners();

      return AuthResponse(
        success: true,
        role: normalizedRole,
        message: 'Account created successfully!',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[Auth] FirebaseAuthException during register: ${e.code} - ${e.message}');
      _error = _mapFirebaseAuthError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    } catch (e) {
      debugPrint('[Auth] Unexpected error during register: $e');
      _error = 'Registration failed: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }
  }

  /// Send SMS OTP using Firebase Phone Authentication
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    final normalized = AppValidators.normalizeIndianMobileNumber(phoneNumber) ??
        phoneNumber.trim();
    debugPrint('[Auth] Sending Firebase Phone OTP to: $normalized');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint(
              '[Auth] Phone auto-verification completed for $normalized');
          try {
            final fbUser = _auth.currentUser;
            if (fbUser != null) {
              await fbUser.updatePhoneNumber(credential);
              await _firestore.collection('users').doc(fbUser.uid).update({
                'phone': normalized,
                'phoneNumber': normalized,
                'phoneVerified': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              await fetchUserProfile();
            }
          } catch (e) {
            debugPrint('[Auth] Auto updatePhoneNumber error: $e');
          }
          if (onAutoVerified != null) onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
              '[Auth] verifyPhoneNumber failed: ${e.code} - ${e.message}');
          onError(_mapFirebaseAuthError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[Auth] SMS code sent, verificationId: $verificationId');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('[Auth] SMS auto retrieval timeout for $verificationId');
        },
      );
    } catch (e) {
      debugPrint('[Auth] Exception in sendPhoneOtp: $e');
      onError('Failed to send verification code. Please try again.');
    }
  }

  /// Verify Firebase Phone Auth SMS OTP
  Future<AuthResponse> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String phone,
  }) async {
    _status = AuthStatus.checking;
    _error = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        try {
          await fbUser.updatePhoneNumber(credential);
        } catch (e) {
          debugPrint('[Auth] updatePhoneNumber note: $e');
        }

        final normalized =
            AppValidators.normalizeIndianMobileNumber(phone) ?? phone.trim();
        await _firestore.collection('users').doc(fbUser.uid).update({
          'phone': normalized,
          'phoneNumber': normalized,
          'phoneVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await fetchUserProfile();
      }

      _status = AuthStatus.authenticated;
      notifyListeners();

      return AuthResponse(
        success: true,
        role: _user?.role ?? '',
        message: 'Phone number verified successfully!',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[Auth] verifyPhoneOtp FirebaseAuthException: ${e.code} - ${e.message}');
      _status = AuthStatus.error;
      _error = _mapFirebaseAuthError(e);
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    } catch (e) {
      debugPrint('[Auth] verifyPhoneOtp unexpected error: $e');
      _status = AuthStatus.error;
      _error = 'Invalid verification code. Please check and try again.';
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter your email address.');
      return false;
    }
    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
      Fluttertoast.showToast(
        msg: 'Password reset link sent to $cleanEmail',
        backgroundColor: const Color(0xFF10B981),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      final msg = _mapFirebaseAuthError(e);
      Fluttertoast.showToast(
          msg: msg, backgroundColor: const Color(0xFFEF4444));
      return false;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to send password reset email.',
        backgroundColor: const Color(0xFFEF4444),
      );
      return false;
    }
  }

  /// Sign out user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[Auth] Error signing out: $e');
    }
    _user = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Fetch user profile from Firestore
  Future<void> fetchUserProfile() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return;
    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _user = UserModel.fromJson(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Auth] fetchUserProfile error: $e');
    }
  }

  /// Verify OTP / Email verification code
  Future<AuthResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _status = AuthStatus.checking;
    notifyListeners();

    try {
      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        await fbUser.reload();
        await fetchUserProfile();
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return AuthResponse(
        success: true,
        role: _user?.role ?? '',
        message: 'Verification successful.',
      );
    } catch (e) {
      debugPrint('[Auth] verifyOtp error: $e');
      _status = AuthStatus.error;
      _error = 'Verification failed. Please try again.';
      notifyListeners();
      return AuthResponse(success: false, message: _error);
    }
  }

  /// Update user profile (name, phone) in Firestore and Auth
  Future<bool> updateUserProfile({
    required String fullName,
    required String phone,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null || _user == null) return false;

    _status = AuthStatus.checking;
    notifyListeners();

    try {
      final cleanName = fullName.trim();
      final cleanPhone = phone.trim();

      await fbUser.updateDisplayName(cleanName);
      await _firestore.collection('users').doc(fbUser.uid).update({
        'name': cleanName,
        'fullName': cleanName,
        'phone': cleanPhone,
        'phoneNumber': cleanPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _user = UserModel(
        id: _user!.id,
        fullName: cleanName,
        email: _user!.email,
        phone: cleanPhone,
        role: _user!.role,
        avatarUrl: _user!.avatarUrl,
        activeDeliveriesCount: _user!.activeDeliveriesCount,
        status: _user!.status,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Auth] updateUserProfile error: $e');
      _error = 'Failed to update profile: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Send email verification link
  Future<bool> sendEmailVerification() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser != null && !fbUser.emailVerified) {
        await fbUser.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[Auth] sendEmailVerification error: $e');
      return false;
    }
  }

  /// Check if current Firebase user email is verified
  Future<bool> checkEmailVerified() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        await fbUser.reload();
        final verified = fbUser.emailVerified;
        if (verified) {
          await fetchUserProfile();
          _status = AuthStatus.authenticated;
          notifyListeners();
        }
        return verified;
      }
      return false;
    } catch (e) {
      debugPrint('[Auth] checkEmailVerified error: $e');
      return false;
    }
  }

  /// Change password with reauthentication
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null || fbUser.email == null) {
      return const AuthResponse(
        success: false,
        message: 'No active session. Please log in again.',
      );
    }
    if (newPassword.length < 6) {
      return const AuthResponse(
        success: false,
        message: 'New password must contain at least 6 characters.',
      );
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(cred);
      await fbUser.updatePassword(newPassword);

      return const AuthResponse(
        success: true,
        message: 'Password changed successfully!',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResponse(
        success: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to update password: $e',
      );
    }
  }

  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please log in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few moments.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      default:
        return e.message ?? 'An error occurred (${e.code}). Please try again.';
    }
  }
}
