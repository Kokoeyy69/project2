import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Event Constants
  static const String EVENT_ESCROW_INIT = 'escrow_init';
  static const String EVENT_FRAUD_BLOCK = 'fraud_block';
  static const String EVENT_BURNER_CARD_GEN = 'burner_card_gen';
  static const String EVENT_PREMIUM_UPGRADE_CLICK = 'premium_upgrade_click';

  Future<void> logBusinessEvent(String name, Map<String, Object> parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('AnalyticsService: Failed to log event $name - $e');
    }
  }
}