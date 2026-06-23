import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/presentation/security/pin_verification_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock flutter_secure_storage platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          // Return a stored PIN hash that does NOT match hash of '111111'
          // This ensures any PIN entered as '111111' will always fail verification
          return 'fake_stored_hash_that_will_never_match_any_input';
        } else if (methodCall.method == 'write') {
          return null;
        }
        return null;
      },
    );

    // Mock local_auth platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'canCheckBiometrics') {
          return false;
        } else if (methodCall.method == 'isDeviceSupported') {
          return false;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      null,
    );
  });

  /// Helper: enter 6-digit wrong PIN and wait for async processing
  Future<void> enterWrongPin(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.text('1'));
      await tester.pump();
    }
    // Allow async verifyPin + setState to complete
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    // Dismiss any SnackBar so next attempt can proceed cleanly
    await tester.pump(const Duration(seconds: 5));
  }

  group('PinVerificationScreen - Brute Force Lockout', () {
    testWidgets('shows error SnackBar on first failed PIN attempt',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PinVerificationScreen()),
      );
      await tester.pumpAndSettle();

      // Enter wrong PIN (111111)
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('1'));
        await tester.pump();
      }
      // Process async verifyPin
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // SnackBar should show error with remaining attempts
      expect(find.text('PIN salah. Sisa percobaan: 2'), findsOneWidget);
    });

    testWidgets('locks screen after 3 consecutive failed PIN attempts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PinVerificationScreen()),
      );
      await tester.pumpAndSettle();

      // Enter wrong PIN 3 times
      for (int attempt = 0; attempt < 3; attempt++) {
        await enterWrongPin(tester);
      }

      // After 3 failed attempts, lockout text should appear
      expect(
        find.textContaining('Terlalu banyak percobaan salah'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Layar dikunci selama'),
        findsOneWidget,
      );
    });

    testWidgets('blocks input during lockout period',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PinVerificationScreen()),
      );
      await tester.pumpAndSettle();

      // Trigger lockout with 3 wrong attempts
      for (int attempt = 0; attempt < 3; attempt++) {
        await enterWrongPin(tester);
      }

      // Verify locked state
      expect(
        find.textContaining('Terlalu banyak percobaan salah'),
        findsOneWidget,
      );

      // Try tapping buttons while locked — should have no effect
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();

      // Lockout message should still be displayed (input blocked)
      expect(
        find.textContaining('Terlalu banyak percobaan salah'),
        findsOneWidget,
      );
    });

    testWidgets('displays countdown timer during lockout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PinVerificationScreen()),
      );
      await tester.pumpAndSettle();

      // First two attempts use helper (includes 5s pump for SnackBar dismiss)
      await enterWrongPin(tester);
      await enterWrongPin(tester);

      // Third attempt: enter PIN without the 5s SnackBar dismiss pump
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('1'));
        await tester.pump();
      }
      // Process async verifyPin + setState + lockScreen
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify lockout starts at 30 seconds
      expect(find.textContaining('30 detik'), findsOneWidget);

      // Tick 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('29 detik'), findsOneWidget);

      // Tick 5 more seconds
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('24 detik'), findsOneWidget);
    });
  });
}