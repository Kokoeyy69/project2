import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Future<SharedPreferences> _prefs;

  FirestoreTransactionsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SharedPreferences? prefs,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _prefs = prefs != null
           ? Future.value(prefs)
           : SharedPreferences.getInstance();

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatAmount(num? amountNum, String? currency) {
    final amountVal = (amountNum ?? 0).toDouble();
    String amountStr = amountVal
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    String prefix = currency == 'USD'
        ? '\$'
        : (currency == 'CNY' ? '¥ ' : 'Rp ');
    return '- $prefix$amountStr';
  }

  TransactionModel _buildTransactionModel(
    String docId,
    Map<String, dynamic> data,
  ) {
    return TransactionModel(
      id: docId,
      merchantName: data['recipientName'] ?? 'Unknown',
      category: data['type'] == 'transfer_out' ? 'Transfer Out' : 'Transaction',
      amount: _formatAmount(data['amount'] as num?, data['currency']),
      currency: data['currency'] ?? 'IDR',
      time: _getTimeAgo(data['timestamp'] as Timestamp?),
      isDebit: true,
      status: TransactionModel.statusFromString(data['status'] ?? 'completed'),
      categoryIcon: Icons.swap_horiz_rounded,
      categoryColor: const Color(0xFF3B82F6),
      recipientNote: data['note'] as String?,
    );
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
          .where('userId', isEqualTo: user.uid)
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
      return Stream.empty();
    }

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .where((snap) => snap.docs.isNotEmpty)
        .map((snap) {
          final doc = snap.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          return _buildTransactionModel(doc.id, data);
        });
  }

  @override
  Future<List<TransactionModel>> loadCachedTransactions() async {
    try {
      final prefs = await _prefs;
      final cached = prefs.getString(_cacheKey);
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
        await prefs.remove(_cacheKey);
        return [];
      }

      if (list.isEmpty) {
        return [];
      }

      return list
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
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
      final prefs = await _prefs;
      final list = transactions
          .take(_cacheMaxItems)
          .map((m) => m.toJson())
          .toList();
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
      final prefs = await _prefs;
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }
}
