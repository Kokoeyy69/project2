import 'package:hive_flutter/hive_flutter.dart';

/// Central cache service using Hive for offline storage
class HiveCacheService {
  static const String _boxName = 'neopay_cache';
  static late Box _box;
  static bool _initialized = false;

  /// Initialize Hive (call in main.dart)
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _initialized = true;
  }

  /// Dispose Hive (call in app cleanup)
  static Future<void> dispose() async {
    if (_initialized) {
      await _box.close();
      _initialized = false;
    }
  }

  // User balance cache
  static Future<void> setCachedBalance(double balance) =>
      _box.put('cached_balance', balance);

  static double? getCachedBalance() => _box.get('cached_balance');

  // AI settings cache
  static Future<void> setAiApiKey(String key) => _box.put('ai_api_key', key);

  static String? getAiApiKey() => _box.get('ai_api_key');

  static Future<void> setAiProvider(String provider) =>
      _box.put('ai_provider', provider);

  static String getAiProvider() => _box.get('ai_provider') ?? 'openai';

  static Future<void> setAiEnabled(bool enabled) =>
      _box.put('ai_enabled', enabled);

  static bool getAiEnabled() => _box.get('ai_enabled') ?? true;

  // Transaction cache (stores JSON string)
  static Future<void> setCachedTransactions(String cacheKey, String jsonData) =>
      _box.put(cacheKey, jsonData);

  static String? getCachedTransactions(String cacheKey) => _box.get(cacheKey);

  static Future<void> clearTransactionCache(String cacheKey) =>
      _box.delete(cacheKey);

  // Clear all cache
  static Future<void> clearAll() => _box.clear();

  // Generic get/set for extensibility
  static Future<void> set(String key, dynamic value) => _box.put(key, value);

  static dynamic get(String key) => _box.get(key);

  static Future<void> delete(String key) => _box.delete(key);
}
