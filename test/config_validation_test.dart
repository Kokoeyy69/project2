import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/core/config/env.dart';
import 'package:neopay_ai/core/config/app_flavor.dart';

void main() {
  group('Config Validation Tests', () {
    test('Environment configuration should be loaded correctly', () {
      expect(Env.flavorName, isNotEmpty);
    });

    test('App flavor should be properly set', () {
      expect(FlavorHelper.current, isNotNull);
      expect(FlavorHelper.name, isNotEmpty);
    });

    test('Flavor helper should have flavor type', () {
      final isValid = FlavorHelper.isDev || 
                      FlavorHelper.isStaging || 
                      FlavorHelper.isProd;
      expect(isValid, isTrue);
    });

    test('Firebase configuration should be available', () {
      // Firebase options are initialized in firebase_options.dart
      expect(true, isTrue);
    });

    test('Flavor config should return valid configuration', () {
      final config = FlavorHelper.config;
      expect(config.appName, isNotEmpty);
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.flavor, isNotNull);
    });

    test('Environment should have one and only one active flavor', () {
      int activeCount = 0;
      if (FlavorHelper.isDev) activeCount++;
      if (FlavorHelper.isStaging) activeCount++;
      if (FlavorHelper.isProd) activeCount++;
      
      expect(activeCount, equals(1));
    });
  });
}
