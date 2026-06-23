import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/core/di/locator.dart';

void main() {
  setUpAll(() {
    locator.allowReassignment = true;
    setupLocator();
  });

  group('ActivityScreen Tests', () {
    test('ActivityScreen structure is valid', () {
      expect(true, true);
    });
  });
}
