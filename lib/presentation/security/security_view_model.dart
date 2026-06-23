import 'package:flutter/material.dart';
import '../../core/services/security_service.dart';
import '../../core/di/locator.dart';

class SecurityViewModel extends ChangeNotifier {
  final SecurityService _securityService = locator<SecurityService>();

  String _pin = '';
  String get pin => _pin;

  String _confirmPin = '';
  String get confirmPin => _confirmPin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isConfirming = false;
  bool get isConfirming => _isConfirming;

  bool _otpSent = false;
  bool get otpSent => _otpSent;

  // PIN methods
  void appendDigit(String digit) {
    if (_isConfirming) {
      if (_confirmPin.length < 6) {
        _confirmPin += digit;
        _errorMessage = null;
        notifyListeners();
        if (_confirmPin.length == 6) {
          _verifyAndSavePin();
        }
      }
    } else {
      if (_pin.length < 6) {
        _pin += digit;
        _errorMessage = null;
        notifyListeners();
        if (_pin.length == 6) {
          _isConfirming = true;
          notifyListeners();
        }
      }
    }
  }

  void removeLastDigit() {
    if (_isConfirming) {
      if (_confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        notifyListeners();
      } else {
        _isConfirming = false;
        notifyListeners();
      }
    } else {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
        notifyListeners();
      }
    }
  }

  void clearPin() {
    _pin = '';
    _confirmPin = '';
    _isConfirming = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _verifyAndSavePin() async {
    if (_pin == _confirmPin) {
      _isLoading = true;
      notifyListeners();
      try {
        await _securityService.setTransactionPin(_pin);
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Gagal menyimpan PIN: $e';
        notifyListeners();
      }
    } else {
      _confirmPin = '';
      _errorMessage = 'PIN tidak cocok. Silakan ulangi.';
      notifyListeners();
    }
  }

  Future<bool> verifyPin(String inputPin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final isValid = await _securityService.verifyTransactionPin(inputPin);
      _isLoading = false;
      if (!isValid) {
        _errorMessage = 'PIN salah';
      }
      notifyListeners();
      return isValid;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal verifikasi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> hasPin() async {
    return await _securityService.hasTransactionPin();
  }

  void setOtpSent(bool sent) {
    _otpSent = sent;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
