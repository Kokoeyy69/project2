import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/utils/permission_helper.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets(
    'ensurePermissionsForImage returns true when permissions granted',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Builder(builder: (ctx) => const Text('ok'))),
      );
      final ctx = tester.element(find.text('ok'));

      Future<Map<Permission, PermissionStatus>> requester(
        List<Permission> perms,
      ) async {
        final res = <Permission, PermissionStatus>{};
        for (final p in perms) {
          res[p] = PermissionStatus.granted;
        }
        return res;
      }

      final result = await ensurePermissionsForImage(ctx, requester: requester);
      expect(result, isTrue);
    },
  );

  testWidgets('ensurePermissionsForImage retries on denied then succeeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: (ctx) => const Text('ok'))),
    );
    final ctx = tester.element(find.text('ok'));

    int calls = 0;
    Future<Map<Permission, PermissionStatus>> requester(
      List<Permission> perms,
    ) async {
      calls++;
      final res = <Permission, PermissionStatus>{};
      for (final p in perms) {
        res[p] = (calls == 1)
            ? PermissionStatus.denied
            : PermissionStatus.granted;
      }
      return res;
    }

    final future = ensurePermissionsForImage(ctx, requester: requester);

    // allow the dialog to appear
    await tester.pumpAndSettle();

    expect(find.text('Permission needed'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    final result = await future;
    expect(result, isTrue);
    expect(calls, greaterThanOrEqualTo(2));
  });
}
