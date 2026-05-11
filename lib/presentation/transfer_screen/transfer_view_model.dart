import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TransferViewModel extends ChangeNotifier {
  String _displayAmount = 'Rp0';
  String get displayAmount => _displayAmount;

  double _numericAmount = 0.0;
  double get numericAmount => _numericAmount;

  final NumberFormat _currencyFormatIdr =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  /// Update display format based on wallet index (0=IDR, 1=USD, 2=CNY)
  void updateCurrencyFormat(int walletIndex) {
    _updateDisplay();
    notifyListeners();
  }

  // Fungsi untuk menambah angka yang dipanggil UI
  void appendDigit(String key) {
    HapticFeedback.lightImpact();
    _appendNumber(key);
    _updateDisplay();
    notifyListeners();
  }

  // Fungsi untuk menghapus 1 angka dari belakang (backspace)
  void removeLastDigit() {
    HapticFeedback.lightImpact();
    _handleBackspace();
    _updateDisplay();
    notifyListeners();
  }

  // Fungsi untuk mereset angka jadi 0 (clear)
  void clearAmount() {
    HapticFeedback.lightImpact();
    _numericAmount = 0.0;
    _updateDisplay();
    notifyListeners();
  }

  void _handleBackspace() {
    String currentAmount = _numericAmount.toStringAsFixed(0);
    if (currentAmount.length > 1) {
      currentAmount = currentAmount.substring(0, currentAmount.length - 1);
    } else {
      currentAmount = '0';
    }
    _numericAmount = double.parse(currentAmount);
  }

  void _appendNumber(String number) {
    String currentAmount = _numericAmount.toStringAsFixed(0);
    
    // Batasi maksimal 12 digit (ratusan miliar) biar layout gak jebol
    if (currentAmount.length >= 12) return;

    if (currentAmount == '0' && number != '0') {
      currentAmount = number;
    } else if (currentAmount != '0') {
      currentAmount += number;
    }
    _numericAmount = double.parse(currentAmount);
  }

  void _updateDisplay() {
    _displayAmount = _currencyFormatIdr.format(_numericAmount);
  }
}
