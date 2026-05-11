import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityResult {
  final bool success;
  final String? error;
  const SecurityResult(this.success, {this.error});
}

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static SecurityService get instance => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Secure storage keys
  static const String _pinHashKey = 'transaction_pin_hash';
  static const String _pinSaltKey = 'transaction_pin_salt';
  
  // Shared preferences keys (non-sensitive)
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const String _autoLockEnabledKey = 'auto_lock_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _failedAttemptsKey = 'failed_pin_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';
  
  static const int _autoLockSeconds = 300; // 5 minutes
  static const int _maxFailedAttempts = 3;
  static const int _lockoutDurationSeconds = 30;

  bool _isAuthenticated = false;
  DateTime? _lastBackgroundTime;

  bool get isAuthenticated => _isAuthenticated;
  
  Future<bool> get autoLockEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLockEnabledKey) ?? true;
  }
  
  Future<bool> get biometricEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Set up 6-digit transaction PIN
  Future<void> setTransactionPin(String pin) async {
    if (pin.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw Exception('PIN must be exactly 6 digits');
    }

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    
    await _secureStorage.write(key: _pinHashKey, value: base64Encode(hash));
    await _secureStorage.write(key: _pinSaltKey, value: base64Encode(salt));
    
    // Reset failed attempts
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_failedAttemptsKey, 0);
    await prefs.remove(_lockoutUntilKey);
  }

  /// Verify entered PIN against stored hash
  Future<bool> verifyTransactionPin(String pin) async {
    // Check lockout
    if (await isLockedOut()) {
      return false;
    }

    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final storedSalt = await _secureStorage.read(key: _pinSaltKey);
    
    if (storedHash == null || storedSalt == null) {
      return false; // No PIN set
    }

    final salt = base64Decode(storedSalt);
    final hash = _hashPin(pin, salt);
    final inputHash = base64Encode(hash);

    if (inputHash == storedHash) {
      // Success - reset failed attempts and update auth time
      _isAuthenticated = true;
      await _updateLastAuthTime();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_failedAttemptsKey, 0);
      await prefs.remove(_lockoutUntilKey);
      return true;
    } else {
      // Failed - increment attempts
      final prefs = await SharedPreferences.getInstance();
      int attempts = prefs.getInt(_failedAttemptsKey) ?? 0;
      attempts++;
      await prefs.setInt(_failedAttemptsKey, attempts);
      
      if (attempts >= _maxFailedAttempts) {
        await prefs.setInt(
          _lockoutUntilKey,
          DateTime.now().add(Duration(seconds: _lockoutDurationSeconds)).millisecondsSinceEpoch,
        );
      }
      
      return false;
    }
  }

  /// Check if user has set a PIN
  Future<bool> hasTransactionPin() async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    return storedHash != null;
  }

  /// Check if account is locked out due to too many failed attempts
  Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getInt(_lockoutUntilKey);
    
    if (lockoutUntil == null) return false;
    
    if (DateTime.now().millisecondsSinceEpoch >= lockoutUntil) {
      // Lockout expired
      await prefs.remove(_lockoutUntilKey);
      await prefs.setInt(_failedAttemptsKey, 0);
      return false;
    }
    
    return true;
  }

  /// Get remaining lockout time in seconds
  Future<int> getRemainingLockoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getInt(_lockoutUntilKey);
    
    if (lockoutUntil == null) return 0;
    
    final remaining = lockoutUntil - DateTime.now().millisecondsSinceEpoch;
    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }

  /// Get number of failed attempts
  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  /// Authenticate with biometrics
  Future<SecurityResult> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheck || !isDeviceSupported) {
        return const SecurityResult(false, error: 'Biometrics not available');
      }
      
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to proceed with transaction',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      
      if (didAuthenticate) {
        _isAuthenticated = true;
        await _updateLastAuthTime();
      }
      
      return SecurityResult(didAuthenticate);
    } catch (e) {
      return SecurityResult(false, error: e.toString());
    }
  }

  /// Authenticate with PIN
  Future<SecurityResult> authenticateWithPin(String pin) async {
    final valid = await verifyTransactionPin(pin);
    if (valid) {
      return const SecurityResult(true);
    }
    
    if (await isLockedOut()) {
      final remaining = await getRemainingLockoutSeconds();
      return SecurityResult(false, error: 'Too many failed attempts. Try again in $remaining seconds.');
    }
    
    final attempts = await getFailedAttempts();
    final remaining = _maxFailedAttempts - attempts;
    return SecurityResult(false, error: 'Invalid PIN. $remaining attempts remaining.');
  }

  /// Check if authentication is required
  Future<bool> requireAuthentication() async {
    if (!await hasTransactionPin()) return true; // No PIN set, allow
    
    final lastAuth = _getLastAuthTime();
    if (lastAuth == null) return false;
    
    final diff = DateTime.now().difference(lastAuth);
    if (diff.inSeconds > _autoLockSeconds) {
      _isAuthenticated = false;
      return false;
    }
    
    return _isAuthenticated;
  }

  /// Clear PIN (emergency reset)
  Future<void> clearTransactionPin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _secureStorage.deleteAll();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastAuthTimeKey);
    await prefs.remove(_autoLockEnabledKey);
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutUntilKey);
    
    _isAuthenticated = false;
  }

  /// Set auto-lock preference
  Future<void> setAutoLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLockEnabledKey, enabled);
  }

  /// Set biometric enabled preference
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  void onAppBackground() {
    _lastBackgroundTime = DateTime.now();
  }

  Future<bool> onAppResume() async {
    if (_lastBackgroundTime == null) return _isAuthenticated;
    
    final diff = DateTime.now().difference(_lastBackgroundTime!);
    if (diff.inSeconds > _autoLockSeconds) {
      _isAuthenticated = false;
      return false;
    }
    
    return _isAuthenticated;
  }

  void lock() {
    _isAuthenticated = false;
  }

  Future<void> _updateLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastAuthTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  DateTime? _getLastAuthTime() {
    // This is a simplified version - in production, use secure storage
    return null; // Will be implemented with proper storage
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  }

  Uint8List _hashPin(String pin, Uint8List salt) {
    final bytes = utf8.encode(pin);
    final hmac = Hmac(sha256, salt);
    return Uint8List.fromList(hmac.convert(bytes).bytes);
  }
}