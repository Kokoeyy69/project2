import 'package:flutter/services.dart';

/// Validation result for transaction checks
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? warningMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null,
        warningMessage = null;

  const ValidationResult.invalid(this.errorMessage, {this.warningMessage})
      : isValid = false;
}

/// Enterprise-grade validation service for anti-fraud and input validation
class ValidationService {
  // Transaction limits in IDR
  static const double _minTransferAmount = 1000;
  static const double _maxTransferAmount = 50000000;
  static const double _minTopUpAmount = 10000;
  static const double _maxTopUpAmount = 10000000;

  /// Validate transfer amount
  static ValidationResult validateTransferAmount(double amount) {
    // Anti-negative check
    if (amount <= 0) {
      return const ValidationResult.invalid(
        'Nominal harus lebih dari 0',
      );
    }

    // Minimum check
    if (amount < _minTransferAmount) {
      return ValidationResult.invalid(
        'Minimal transfer Rp ${_formatCurrency(_minTransferAmount)}',
      );
    }

    // Maximum check
    if (amount > _maxTransferAmount) {
      return ValidationResult.invalid(
        'Maksimal transfer Rp ${_formatCurrency(_maxTransferAmount)}',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validate top-up amount
  static ValidationResult validateTopUpAmount(double amount) {
    if (amount <= 0) {
      return const ValidationResult.invalid('Nominal harus lebih dari 0');
    }

    if (amount < _minTopUpAmount) {
      return ValidationResult.invalid(
        'Minimal top up Rp ${_formatCurrency(_minTopUpAmount)}',
      );
    }

    if (amount > _maxTopUpAmount) {
      return ValidationResult.invalid(
        'Maksimal top up Rp ${_formatCurrency(_maxTopUpAmount)}',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validate balance for transaction (Double-spend protection)
  static ValidationResult validateBalance(double balance, double amount, String transactionType) {
    if (balance < amount) {
      return ValidationResult.invalid(
        'Saldo tidak mencukupi. Saldo Anda: Rp ${_formatCurrency(balance)}',
      );
    }

    // Warning if balance is low after transaction
    final remainingBalance = balance - amount;
    if (remainingBalance < 10000) {
      return ValidationResult.invalid(
        'Saldo tidak mencukupi. Saldo Anda: Rp ${_formatCurrency(balance)}',
        warningMessage: 'Saldo tersisa akan kurang dari Rp 10.000',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validate recipient (anti-self-transfer)
  static ValidationResult validateRecipient(String senderUid, String recipientUid) {
    if (senderUid == recipientUid) {
      return const ValidationResult.invalid('Tidak dapat transfer ke diri sendiri');
    }

    if (recipientUid.isEmpty) {
      return const ValidationResult.invalid('Penerima tidak valid');
    }

    return const ValidationResult.valid();
  }

  /// Full transaction validation
  static ValidationResult validateTransaction({
    required double amount,
    required double balance,
    required String senderUid,
    required String recipientUid,
    required String type,
  }) {
    // Validate amount based on type
    ValidationResult amountValidation;
    if (type == 'top_up') {
      amountValidation = validateTopUpAmount(amount);
    } else {
      amountValidation = validateTransferAmount(amount);
    }
    if (!amountValidation.isValid) return amountValidation;

    // Validate balance (for transfers, not top-ups)
    if (type != 'top_up') {
      final balanceValidation = validateBalance(balance, amount, type);
      if (!balanceValidation.isValid) return balanceValidation;
    }

    // Validate recipient
    final recipientValidation = validateRecipient(senderUid, recipientUid);
    if (!recipientValidation.isValid) return recipientValidation;

    return const ValidationResult.valid();
  }

  /// Trigger haptic feedback for keypad press
  static void hapticKeypadPress() {
    HapticFeedback.lightImpact();
  }

  /// Trigger haptic feedback for success
  static void hapticSuccess() {
    HapticFeedback.mediumImpact();
    // Additional vibration pattern for emphasis
    HapticFeedback.vibrate();
  }

  /// Trigger haptic feedback for error
  static void hapticError() {
    HapticFeedback.heavyImpact();
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

/// Transaction security checker for real-time validation
class TransactionSecurityChecker {
  /// Check if transaction is suspicious
  static bool isSuspiciousTransaction({
    required double amount,
    required Duration timeSinceLastTransaction,
    required int transactionsLastHour,
  }) {
    // Flag if more than 10 transactions in an hour
    if (transactionsLastHour >= 10) return true;

    // Flag if transactions are less than 5 seconds apart
    if (timeSinceLastTransaction.inSeconds < 5) return true;

    // Flag if amount is unusually high (> 10 million)
    if (amount > 10000000) return true;

    return false;
  }

  /// Get security level for transaction
  static String getSecurityLevel(double amount) {
    if (amount > 10000000) return 'HIGH';
    if (amount > 1000000) return 'MEDIUM';
    return 'STANDARD';
  }
}