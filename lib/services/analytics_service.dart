/// Lightweight analytics facade with an injectable provider.
///
/// Default implementation is a safe print-based provider. Call
/// `AnalyticsService.instance.setProvider(...)` to plug a real provider
/// (for example, a wrapper around `firebase_analytics`) in app startup.
abstract class AnalyticsProvider {
  Future<void> logEvent(String name, {Map<String, Object?>? params});
}

class _PrintAnalyticsProvider implements AnalyticsProvider {
  @override
  Future<void> logEvent(String name, {Map<String, Object?>? params}) async {
    final p = params == null ? '{}' : params.toString();
    // ignore: avoid_print
    print('[Analytics] $name: $p');
  }
}

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  AnalyticsProvider _provider = _PrintAnalyticsProvider();

  /// Replace the analytics provider. Safe to call at runtime from
  /// application startup; provider errors are caught and won't crash the app.
  void setProvider(AnalyticsProvider provider) {
    _provider = provider;
  }

  /// Reset to the default (print) provider.
  void resetProvider() {
    _provider = _PrintAnalyticsProvider();
  }

  /// Log an event. Fire-and-forget; errors are swallowed and printed.
  void logEvent(String name, {Map<String, Object?>? params}) {
    try {
      _provider.logEvent(name, params: params).catchError((e) {
        // ignore: avoid_print
        print('[Analytics] logEvent failed: $e');
      });
    } catch (e) {
      // ignore: avoid_print
      print('[Analytics] unexpected error: $e');
    }
  }
}
