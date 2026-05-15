import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neopay_ai/services/hive_cache_service.dart';

import '../presentation/home_screen/widgets/recent_transactions_widget.dart';
import 'transactions_repository.dart';

/// Firestore implementation of [TransactionsRepository].
///
/// Handles all Firestore queries, real-time subscriptions, and cache persistence.
class FirestoreTransactionsRepository implements TransactionsRepository {
  static const int _cacheMaxItems = 50;
  static const int _cacheExpiryMs = 1000 * 60 * 60 * 24 * 7; // 7 days
  static const String _cacheKey = 'cached_transactions';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreTransactionsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  TransactionModel _buildTransactionModel(
    String docId,
    Map<String, dynamic> data,
  ) {
    // Use the model's factory constructor which handles dynamic name resolution
    return TransactionModel.fromMap(data);
  }

  @override
  Future<TransactionsFetchResult> fetchPage({
    required int pageSize,
    dynamic cursor,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return TransactionsFetchResult(items: [], hasMore: false);
    }

    try {
      Query query = _firestore
          .collection('transactions')
          .where(Filter.or(
            Filter('sender_uid', isEqualTo: user.uid),
            Filter('recipient_uid', isEqualTo: user.uid),
          ))
          .orderBy('timestamp', descending: true)
          .limit(pageSize);

      if (cursor is DocumentSnapshot) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      final fetched = snap.docs;

      if (fetched.isEmpty) {
        return TransactionsFetchResult(items: [], hasMore: false);
      }

      final models = fetched.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _buildTransactionModel(doc.id, data);
      }).toList();

      return TransactionsFetchResult(
        items: models,
        hasMore: fetched.length == pageSize,
        cursor: fetched.last,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<TransactionModel> watchTopTransaction() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('watchTopTransaction: No user logged in, returning empty stream');
      return Stream.empty();
    }

    debugPrint('watchTopTransaction: Watching for user ${user.uid}');
    return _firestore
        .collection('transactions')
        .where(Filter.or(
          Filter('sender_uid', isEqualTo: user.uid),
          Filter('recipient_uid', isEqualTo: user.uid),
        ))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          debugPrint('watchTopTransaction: Received snapshot with ${snapshot.docs.length} docs');
          if (snapshot.docs.isEmpty) {
            debugPrint('watchTopTransaction: No documents in snapshot');
            return <TransactionModel>[];
          }
          final doc = snapshot.docs.first;
          final data = doc.data();
          debugPrint('watchTopTransaction: Building model for doc ${doc.id}');
          try {
            final model = _buildTransactionModel(doc.id, data);
            debugPrint('watchTopTransaction: Successfully built model - merchant: ${model.merchantName}, amount: ${model.amount}');
            return [model];
          } catch (e, stackTrace) {
            debugPrint('watchTopTransaction: Error building model: $e');
            debugPrint('watchTopTransaction: Stack trace: $stackTrace');
            debugPrint('watchTopTransaction: Document data: $data');
            return <TransactionModel>[];
          }
        })
        .expand((models) => models);
  }

  @override
  Future<List<TransactionModel>> loadCachedTransactions() async {
    try {
      final cached = HiveCacheService.getCachedTransactions(_cacheKey);
      if (cached == null || cached.isEmpty) {
        return [];
      }

      final decoded = json.decode(cached);
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

      // expire cache older than _cacheExpiryMs
      if (lastUpdated != 0 &&
          DateTime.now().millisecondsSinceEpoch - lastUpdated >
              _cacheExpiryMs) {
        await HiveCacheService.clearTransactionCache(_cacheKey);
        return [];
      }

      if (list.isEmpty) {
        return [];
      }

      return list
          .map((e) => TransactionModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCachedTransactions(
    List<TransactionModel> transactions,
  ) async {
    try {
      final list = transactions
          .take(_cacheMaxItems)
          .map((m) => m.toJson())
          .toList();
      final payload = {
        'items': list,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      await HiveCacheService.setCachedTransactions(
        _cacheKey,
        json.encode(payload),
      );
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      await HiveCacheService.clearTransactionCache(_cacheKey);
    } catch (_) {}
  }
}
