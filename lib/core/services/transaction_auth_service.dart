import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TransactionAuthService {
  final _storage = const FlutterSecureStorage();

  Future<bool> authenticate() async {
    final auth = LocalAuthentication();

    try {
      final result = await auth.authenticate(
        localizedReason: 'Please authenticate to proceed with the transaction',
      );

      if (result) {
        return true;
      } else {
        // If authentication fails, prompt for PIN
        final pin = await _promptForPin();
        if (pin != null) {
          final storedPin = await _storage.read(key: 'transaction_pin');
          final hashedPin = _hashPin(pin);
          if (hashedPin == storedPin) {
            return true;
          }
        }
        return false;
      }
    } on PlatformException {
      // Handle platform exceptions
      return false;
    }
  }

  Future<String?> _promptForPin() async {
    // Implement PIN prompt and verification here
    return null;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
