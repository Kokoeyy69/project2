import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:neopay_ai/services/hive_cache_service.dart';
import 'package:rxdart/rxdart.dart';

import '../models/transaction_model.dart';
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
      final outgoingQuery = _firestore
          .collection('transactions')
          .where('sender_uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true);

      final incomingQuery = _firestore
          .collection('transactions')
          .where('recipient_uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true);

      // Fetch a larger buffer since we are combining two streams locally
      final fetchLimit = cursor != null ? 100 : pageSize;

      final results = await Future.wait([
        outgoingQuery.limit(fetchLimit).get(),
        incomingQuery.limit(fetchLimit).get(),
      ]);

      final s1 = results[0];
      final s2 = results[1];

      final combinedDocs = [...s1.docs, ...s2.docs];
      final transactions = combinedDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final map = Map<String, dynamic>.from(data);
        if (!map.containsKey('id')) {
          map['id'] = doc.id;
        }
        return _buildTransactionModel(doc.id, map);
      }).toList();

      // Deduplicate by ID and sort by timestamp descending
      final seenIds = <String>{};
      final deduped = transactions.where((t) => seenIds.add(t.id)).toList();
      deduped.sort((a, b) {
        final tsA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tsB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tsB.compareTo(tsA);
      });

      // Local cursor-based pagination
      List<TransactionModel> pageItems;
      if (cursor is DocumentSnapshot) {
        final cursorId = cursor.id;
        final cursorIndex = deduped.indexWhere((t) => t.id == cursorId);
        if (cursorIndex != -1 && cursorIndex + 1 < deduped.length) {
          pageItems = deduped.skip(cursorIndex + 1).take(pageSize).toList();
        } else {
          pageItems = [];
        }
      } else {
        pageItems = deduped.take(pageSize).toList();
      }

      // Find the corresponding DocumentSnapshot to use as the next cursor
      dynamic nextCursor;
      if (pageItems.isNotEmpty) {
        final lastId = pageItems.last.id;
        try {
          nextCursor = combinedDocs.firstWhere((doc) => doc.id == lastId);
        } catch (_) {
          nextCursor = null;
        }
      }

      return TransactionsFetchResult(
        items: pageItems,
        hasMore: pageItems.length == pageSize,
        cursor: nextCursor,
      );
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<TransactionModel>> watchUserTransactions(String uid) {
    if (uid.isEmpty || uid.contains('/') || uid.length > 100) {
      return Stream.value([]);
    }

    final outgoing = _firestore
        .collection('transactions')
        .where('sender_uid', isEqualTo: uid.trim())
        .snapshots()
        .handleError((e) => const Stream.empty());
    final incoming = _firestore
        .collection('transactions')
        .where('recipient_uid', isEqualTo: uid.trim())
        .snapshots()
        .handleError((e) => const Stream.empty());

    return Rx.combineLatest2(outgoing, incoming, (
      QuerySnapshot s1,
      QuerySnapshot s2,
    ) {
      final combined = [...s1.docs, ...s2.docs];
      final list = combined
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // Deduplicate by transaction ID and sort descending safely
      final seenIds = <String>{};
      return list.where((t) => seenIds.add(t.id)).toList()..sort((a, b) {
        final timeA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });
    }).handleError((e) => Stream.value(<TransactionModel>[]));
  }

  Stream<List<TransactionModel>> watchAllUserTransactions(String uid) {
    return watchUserTransactions(uid);
  }

  @override
  Stream<TransactionModel?> watchTopTransaction(String uid) {
    if (uid.isEmpty || uid.contains('/') || uid.length > 100) {
      if (kDebugMode) {
        print('[FirestoreTransactionsRepository] Invalid UID for watchTopTransaction: "$uid"');
      }
      return Stream.value(null);
    }

    final outgoing = _firestore
        .collection('transactions')
        .where('sender_uid', isEqualTo: uid.trim())
        .snapshots()
        .handleError((e) {
          if (kDebugMode) {
            print('[FirestoreTransactionsRepository] Error in outgoing stream: $e');
          }
          return const Stream.empty();
        });

    final incoming = _firestore
        .collection('transactions')
        .where('recipient_uid', isEqualTo: uid.trim())
        .snapshots()
        .handleError((e) {
          if (kDebugMode) {
            print('[FirestoreTransactionsRepository] Error in incoming stream: $e');
          }
          return const Stream.empty();
        });

    return Rx.combineLatest2(outgoing, incoming, (
      QuerySnapshot s1,
      QuerySnapshot s2,
    ) {
      final combined = [...s1.docs, ...s2.docs];
      if (combined.isEmpty) return null;

      final list = combined
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // Null-safe sorting
      list.sort((a, b) {
        final timeA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      return list.first;
    }).handleError((e) {
      if (kDebugMode) {
        print('[FirestoreTransactionsRepository] Error in combined stream: $e');
      }
      return Stream.value(null);
    });
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

      return list.map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[FirestoreTransactionsRepository] Error loading cache: $e');
      }
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