import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';

class AppLockService with WidgetsBindingObserver {
  static const String _biometricEnabledKey = 'isBiometricEnabled';

  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal() {
    WidgetsBinding.instance.addObserver(this);
    loadAppLockState();
  }

  bool isBiometricEnabled = false;

  Future<void> loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    isBiometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    isBiometricEnabled = value;
    await prefs.setBool(_biometricEnabledKey, value);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelLockTimer();
  }

  // Lock state
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  // Timer for background lock
  Timer? _lockTimer;
  static const int _lockDurationSeconds = 60; // 1 minute

  void _startLockTimer() {
    _cancelLockTimer();
    _lockTimer = Timer(Duration(seconds: _lockDurationSeconds), () {
      _isLocked = true;
    });
  }

  void _cancelLockTimer() {
    if (_lockTimer?.isActive ?? false) {
      _lockTimer?.cancel();
    }
    _lockTimer = null;
  }

  // WidgetsBindingObserver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.paused) {
        // App going to background: start timer
        _startLockTimer();
        // persist last background timestamp if needed
      } else if (state == AppLifecycleState.resumed) {
        // App returning to foreground: cancel timer and navigate if locked
        _cancelLockTimer();
        if (_isLocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navKey = AppNavigation.navigatorKey;
            if (navKey.currentState != null) {
              // Push replacement so user must unlock
              navKey.currentState!.pushNamedAndRemoveUntil(
                AppRoutes.appLockPasswordScreen,
                (route) => false,
              );
            }
          });
        }
      }
    } catch (_) {
      // ignore lifecycle errors to avoid crashes
    }
  }

  // External API
  void lock() {
    _isLocked = true;
  }

  void unlock() {
    _isLocked = false;
    _cancelLockTimer();
  }

  Future<bool> authenticate() async {
    // Biometric is optional, but mandatory if enabled
    if (!isBiometricEnabled) return false;

    final auth = LocalAuthentication();
    try {
      final result = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
      );

      if (result) {
        _isLocked = false;
        return true;
      } else {
        // biometric failed; do not change lock here.
        return false;
      }
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}