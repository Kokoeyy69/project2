import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Sets the display refresh rate to the highest supported mode on Android.
/// Has no effect on non-Android platforms or web.
Future<void> setHighRefreshRate() async {
  try {
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }
  } catch (e) {
    debugPrint('Failed to set high refresh rate: $e');
  }
}
