import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/core/services/security_service.dart';

void main() {
  group('SecurityService', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService();
    });

    test('hashPin should return consistent output for the same input', () {
      final pin = '123456';
      final hash1 = securityService.hashPin(pin);
      final hash2 = securityService.hashPin(pin);
      expect(hash1, hash2);
      expect(hash1.length, 64); // SHA-256 hex length
    });

    test('hashPin should return different outputs for different inputs', () {
      final hash1 = securityService.hashPin('123456');
      final hash2 = securityService.hashPin('111111');
      expect(hash1, isNot(hash2));
    });
  });
}
