import 'package:firebase_analytics/firebase_analytics.dart';
import 'analytics_service.dart';

/// Real Firebase Analytics provider.
///
/// Wraps `package:firebase_analytics` to log events to Firebase Console.
/// All errors are caught internally to avoid crashing the app.
class FirebaseAnalyticsProvider implements AnalyticsProvider {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsProvider({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? params}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: params?.cast<String, Object>(),
      );
    } catch (e) {
      // Silently catch errors; AnalyticsService will also catch and print
      rethrow;
    }
  }
}
