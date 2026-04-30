import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Requests the necessary permissions for camera/gallery use and shows
// rationale dialogs if denied/permanently denied. `requester` is injectable
// for tests: it should accept a list of permissions and return a map of
// Permission -> PermissionStatus.
Future<bool> ensurePermissionsForImage(
  BuildContext context, {
  Future<Map<Permission, PermissionStatus>> Function(List<Permission>)?
  requester,
}) async {
  try {
    final permissions = <Permission>[
      Permission.camera,
      if (Platform.isAndroid) Permission.storage,
      Permission.photos,
    ];

    final statuses = requester != null
        ? await requester(permissions)
        : await permissions.request();

    // If any granted, continue
    if (statuses.values.any((s) => s.isGranted)) return true;

    // If any permanently denied or restricted, prompt user to open app settings
    if (statuses.values.any((s) => s.isPermanentlyDenied || s.isRestricted)) {
      if (!context.mounted) return false;
      final open =
          await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Permission required'),
                content: const Text(
                  'Please open app settings and allow camera or photo access to pick or take profile photos.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Open Settings'),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (open) await openAppSettings();
      return false;
    }

    // If denied but not permanent, offer a retry
    if (statuses.values.any((s) => s.isDenied)) {
      if (!context.mounted) return false;
      final retry =
          await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Permission needed'),
                content: const Text(
                  'This action needs permission to access camera or photos. Retry permission request?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Retry'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (retry) {
        final re = requester != null
            ? await requester(permissions)
            : await permissions.request();
        if (re.values.any((s) => s.isGranted)) return true;
        if (re.values.any((s) => s.isPermanentlyDenied)) {
          if (!context.mounted) return false;
          final open2 =
              await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Permission required'),
                    content: const Text(
                      'Permission permanently denied. Open app settings to allow it.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  );
                },
              ) ??
              false;
          if (open2) await openAppSettings();
        }
      }
      return false;
    }
  } catch (_) {}
  return true;
}
