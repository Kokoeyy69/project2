Android & iOS platform permissions for image picking, cropping and camera

Overview

This project uses `image_picker` and `image_cropper` (plus optional camera recording) to let users pick or take profile photos. Some platforms require declaring "usage" strings (iOS) or permission flags (Android) in platform manifests. Additionally, runtime permission requests are required on Android (and optionally iOS for some flows).

What I added

- Android: Added permissions in `android/app/src/main/AndroidManifest.xml`:
  - `android.permission.CAMERA`
  - `android.permission.READ_EXTERNAL_STORAGE`
  - `android.permission.WRITE_EXTERNAL_STORAGE` (with `android:maxSdkVersion="28"` for legacy devices)
  - `android.permission.READ_MEDIA_IMAGES` (Android 13+)

- iOS: Added keys to `ios/Runner/Info.plist`:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
  - `NSFaceIDUsageDescription`

Runtime permission guidance

- Android (recommended):
  - For Android 6.0+ you must request dangerous permissions at runtime. Consider using the `permission_handler` package to request `CAMERA` and `READ_EXTERNAL_STORAGE`/`READ_MEDIA_IMAGES` before invoking `ImagePicker` or `ImageCropper`.
  - On Android 13 (API 33) prefer requesting `READ_MEDIA_IMAGES` instead of `READ_EXTERNAL_STORAGE`.

  Example with `permission_handler`:

  ```dart
  final status = await Permission.photos.request(); // or Permission.storage / Permission.photos
  if (!status.isGranted) {
    // show rationale or direct user to settings
  }
  ```

- iOS: The platform shows a permission dialog automatically when you access the camera or photo library. Ensure the `NS...UsageDescription` keys are set in `Info.plist` (already added).

Notes & next steps

- If you plan to support saving edited images back to the user's library, ensure `NSPhotoLibraryAddUsageDescription` is present (added).
- Consider adding in-app fallback behavior if runtime permissions are denied (e.g., show a friendly dialog with `Open Settings` button using `openAppSettings()` from `permission_handler`).
- If you use the camera to record audio/video, also add `NSMicrophoneUsageDescription` on iOS and request `RECORD_AUDIO` on Android.

If you want, I can:
- Add `permission_handler` to `pubspec.yaml` and wire simple runtime permission requests in `profile_screen.dart` before pick/crop operations.
- Add a small integration test that verifies permission-denied flows (emulator-dependent).
