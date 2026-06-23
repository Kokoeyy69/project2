import 'dart:convert';
import 'package:neopay_ai/core/services/security_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate crypto test vector', () {
    final payload = jsonEncode({"test": "data"});
    print('Payload: $payload');
    print('Payload length: ${payload.length}');
    
    final encrypted = SecurityService.instance.encryptPayload(payload);
    print('RESULT_START');
    print(encrypted);
    print('RESULT_END');
  });
}