import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/core/services/security_service.dart';
import 'package:neopay_ai/core/di/locator.dart';

void main() {
  setUpAll(() {
    locator.allowReassignment = true;
    setupLocator();
  });

  group('FraudShield Integration Tests', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService();
    });

    test('Test 1 (High Risk): Transfer 15.000.000 IDR at 02:00 AM', () {
      final result = securityService.evaluateTransactionRisk(
        15000000,
        100000000,
        null,
        null,
      );

      expect(result, true);
    });

    test('Test 2 (Safe): Transfer 50.000 IDR at 02:00 PM', () {
      final result = securityService.evaluateTransactionRisk(
        50000,
        100000000,
        null,
        null,
      );

      expect(result, false);
    });
  });
}
