import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/home_screen/widgets/recent_transactions_widget.dart';
import 'transactions_repository.dart';

/// Simple in-memory / SharedPreferences-backed repository for tests and
/// offline usage. It reads/writes the same cache format used by
/// FirestoreTransactionsRepository.
class InMemoryTransactionsRepository implements TransactionsRepository {
  static const String _cacheKey = 'cached_transactions';

  InMemoryTransactionsRepository();

  List<TransactionModel> _fromPayload(dynamic decoded) {
    List<dynamic> list = <dynamic>[];
    int lastUpdated = 0;

    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      if (decoded['items'] is List) {
        list = decoded['items'] as List<dynamic>;
        lastUpdated = decoded['lastUpdated'] is int
            ? decoded['lastUpdated'] as int
            : 0;
      }
    }

    return list
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<TransactionsFetchResult> fetchPage({
    required int pageSize,
    dynamic cursor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null || cached.isEmpty)
      return TransactionsFetchResult(items: [], hasMore: false);

    final decoded = json.decode(cached);
    final items = _fromPayload(decoded);
    final page = items.take(pageSize).toList();
    return TransactionsFetchResult(
      items: page,
      hasMore: items.length > page.length,
      cursor: null,
    );
  }

  @override
  Stream<TransactionModel> watchTopTransaction() {
    return Stream.empty();
  }

  @override
  Future<List<TransactionModel>> loadCachedTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null || cached.isEmpty) return [];
    try {
      final decoded = json.decode(cached);
      return _fromPayload(decoded);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCachedTransactions(
    List<TransactionModel> transactions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = transactions.map((m) => m.toJson()).toList();
      final payload = {
        'items': list,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, json.encode(payload));
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }
}
