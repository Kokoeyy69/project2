
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TransferViewModel extends ChangeNotifier {
  String _displayAmount = 'Rp0';
  String get displayAmount => _displayAmount;

  double _numericAmount = 0.0;
  double get numericAmount => _numericAmount;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  void onKeyPress(String key) {
    HapticFeedback.lightImpact();

    if (key == 'backspace') {
      _handleBackspace();
    } else {
      _appendNumber(key);
    }

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
    if (currentAmount == '0' && number != '0') {
      currentAmount = number;
    } else if (currentAmount != '0') {
      currentAmount += number;
    }
    _numericAmount = double.parse(currentAmount);
  }

  void _updateDisplay() {
    _displayAmount = _currencyFormat.format(_numericAmount);
  }

  void reset() {
    _numericAmount = 0.0;
    _updateDisplay();
    notifyListeners();
  }
}
