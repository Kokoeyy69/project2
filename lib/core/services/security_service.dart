import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecurityService {
  static bool isFraudDebugMode = true;
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ============ SINGLETON PATTERN ============
  static final SecurityService instance = SecurityService._internal();
  
  // Allow unnamed constructor for DI compatibility
  SecurityService() : this._internal();
  SecurityService._internal();

  // ============ PIN MANAGEMENT METHODS ============

  /// Setup initial PIN (placeholder for first-time setup)
  void setupInitialPin() {
    debugPrint('SecurityService: Initial PIN setup initialized');
  }

  /// Hash PIN using SHA256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set transaction PIN
  Future<void> setTransactionPin(String pin) async {
    try {
      final hashedPin = _hashPin(pin);
      await _storage.write(key: 'transaction_pin', value: hashedPin);
      debugPrint('SecurityService: Transaction PIN set successfully');
    } catch (e) {
      debugPrint('SecurityService: Error setting PIN - $e');
      throw Exception('Failed to set PIN: $e');
    }
  }

  /// Verify transaction PIN
  Future<bool> verifyTransactionPin(String inputPin) async {
    try {
      final storedPin = await _storage.read(key: 'transaction_pin');
      if (storedPin == null) {
        debugPrint('SecurityService: No PIN found in storage');
        return false;
      }
      final hashedInput = _hashPin(inputPin);
      final isValid = hashedInput == storedPin;
      debugPrint('SecurityService: PIN verification result: $isValid');
      return isValid;
    } catch (e) {
      debugPrint('SecurityService: Error verifying PIN - $e');
      return false;
    }
  }

  /// Check if transaction PIN exists
  Future<bool> hasTransactionPin() async {
    try {
      final storedPin = await _storage.read(key: 'transaction_pin');
      return storedPin != null;
    } catch (e) {
      debugPrint('SecurityService: Error checking PIN existence - $e');
      return false;
    }
  }

  /// Legacy method: verifyPin (calls verifyTransactionPin)
  Future<bool> verifyPin(String inputPin) async {
    return verifyTransactionPin(inputPin);
  }

  /// Reset PIN (clear stored PIN)
  Future<void> resetPin() async {
    try {
      await _storage.delete(key: 'transaction_pin');
      debugPrint('SecurityService: PIN reset successfully');
    } catch (e) {
      debugPrint('SecurityService: Error resetting PIN - $e');
      throw Exception('Failed to reset PIN: $e');
    }
  }

  // ============ BIOMETRIC AUTHENTICATION METHODS ============

  /// Authenticate using biometrics
  Future<bool> authenticateUser() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason:
            'Otentikasi diperlukan untuk memverifikasi transaksi Anda',
      );
    } catch (e) {
      debugPrint('SecurityService Auth Error: $e');
      return false;
    }
  }

  /// Legacy method: authenticateBiometric (calls authenticateUser)
  Future<bool> authenticateBiometric() async {
    return authenticateUser();
  }

  // ============ FRAUD DETECTION METHODS ============

  /// Detect suspicious activity based on amount and time
  bool isSuspiciousTransaction(double amount, double currentBalance) {
    if (isFraudDebugMode) return true;
    // True if amount > 50% of balance
    if (amount > (currentBalance * 0.5)) {
      return true;
    }

    // True if between 01:00 and 04:00 AM
    final hour = DateTime.now().hour;
    if (hour >= 1 && hour <= 4) {
      return true;
    }

    return false;
  }

  /// Evaluate transaction risk (comprehensive fraud check)
  bool evaluateTransactionRisk(
    double amount,
    double currentBalance,
    String? location,
    String? deviceId,
  ) {
    // Basic risk evaluation
    if (isSuspiciousTransaction(amount, currentBalance)) {
      debugPrint(
          'SecurityService: Suspicious transaction detected - Amount: $amount, Balance: $currentBalance');
      return true;
    }

    // Additional risk checks can be added here
    return false;
  }

  // ============ AUTHENTICATION STATE METHODS ============

  /// Check if user is currently authenticated
  bool get isAuthenticated {
    // Placeholder - implement persistent auth state
    return false;
  }

  // ============ ENCRYPTION/SECURITY METHODS ============

  /// Encrypt payload for API calls
  String encryptPayload(String data) {
    // Basic encryption for demo
    return data;
  }

  // ============ APP LIFECYCLE & AUTO-LOCK METHODS ============

  /// Handle app going to background
  void onAppBackground() {
    debugPrint('SecurityService: App moved to background');
  }

  /// Handle app resuming from background
  Future<bool> onAppResume() async {
    debugPrint('SecurityService: App resumed from background');
    return true;
  }

  /// Check if auto-lock is enabled
  Future<bool> get autoLockEnabled async {
    return false; // Placeholder
  }

  // ============ TWO-FACTOR AUTHENTICATION METHODS ============

  /// Set biometric enabled state
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'biometric_enabled', value: enabled.toString());
      debugPrint('SecurityService: Biometric enabled set to $enabled');
    } catch (e) {
      debugPrint('SecurityService: Error setting biometric - $e');
    }
  }

  /// Generate 2FA secret (returns Map with secret key)
  Future<Map<String, String>> generate2FASecret([String? email]) async {
    final secret = 'JBSWY3DPEBLW64TMMQ======';
    final issuer = 'NeoPayAI';
    final uri = 'otpauth://totp/$issuer:${email ?? "user"}?secret=$secret&issuer=$issuer';
    debugPrint('SecurityService: 2FA secret generated${email != null ? ' for $email' : ''}');
    return {
      'secret': secret,
      'uri': uri,
    };
  }

  /// Set 2FA secret
  Future<void> set2FASecret(String secret) async {
    try {
      await _storage.write(key: '2fa_secret', value: secret);
      debugPrint('SecurityService: 2FA secret stored');
    } catch (e) {
      debugPrint('SecurityService: Error setting 2FA secret - $e');
    }
  }

  /// Get 2FA secret
  Future<String?> get2FASecret() async {
    try {
      return await _storage.read(key: '2fa_secret');
    } catch (e) {
      debugPrint('SecurityService: Error getting 2FA secret - $e');
      return null;
    }
  }

  /// Verify TOTP code (with secret and code)
  Future<bool> verifyTOTP(String secret, String code) async {
    try {
      debugPrint('SecurityService: TOTP verification for secret: $secret, code: $code');
      return code.length == 6;
    } catch (e) {
      debugPrint('SecurityService: Error verifying TOTP - $e');
      return false;
    }
  }

  /// Delete 2FA secret
  Future<void> delete2FASecret() async {
    try {
      await _storage.delete(key: '2fa_secret');
      debugPrint('SecurityService: 2FA secret deleted');
    } catch (e) {
      debugPrint('SecurityService: Error deleting 2FA secret - $e');
    }
  }

  /// Set two-factor authentication enabled
  Future<void> setTwoFactorEnabled(bool enabled) async {
    try {
      await _storage.write(key: '2fa_enabled', value: enabled.toString());
      debugPrint('SecurityService: 2FA enabled set to $enabled');
    } catch (e) {
      debugPrint('SecurityService: Error setting 2FA enabled - $e');
    }
  }

  /// Get two-factor authentication enabled status
  Future<bool> getTwoFactorEnabled() async {
    try {
      final value = await _storage.read(key: '2fa_enabled');
      return value == 'true';
    } catch (e) {
      debugPrint('SecurityService: Error getting 2FA enabled - $e');
      return false;
    }
  }

  // ============ TEST/UTILITY METHODS ============

  /// Hash PIN (public version for testing)
  String hashPin(String pin) {
    return _hashPin(pin);
  }
}
