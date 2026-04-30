import 'package:cloud_firestore/cloud_firestore.dart';
import '../presentation/home_screen/widgets/recent_transactions_widget.dart';

/// Result of a single fetch operation.
class TransactionsFetchResult {
  final List<TransactionModel> items;
  final bool hasMore;
  final dynamic cursor; // e.g., DocumentSnapshot or page token

  TransactionsFetchResult({
    required this.items,
    required this.hasMore,
    this.cursor,
  });
}

/// Abstract repository for transactions with injectable Firestore access.
///
/// Separates query logic from UI, making it testable without Firebase.
/// Implement for Firestore (production) or in-memory (testing).
abstract class TransactionsRepository {
  /// Fetch a page of transactions.
  /// [pageSize] — number of items per page.
  /// [cursor] — pagination cursor (e.g., last document, null for first page).
  /// Returns a [TransactionsFetchResult] with items, hasMore, and next cursor.
  Future<TransactionsFetchResult> fetchPage({
    required int pageSize,
    dynamic cursor,
  });

  /// Subscribe to realtime updates of the most recent transaction.
  /// Returns a stream that emits the latest transaction when it changes.
  /// Returns an empty stream if not logged in or if errors occur.
  Stream<TransactionModel> watchTopTransaction();

  /// Load cached transactions from disk.
  /// Returns list of cached items, or empty if no cache or cache expired.
  Future<List<TransactionModel>> loadCachedTransactions();

  /// Save transactions to disk cache.
  /// Should apply size limits and expiry.
  Future<void> saveCachedTransactions(List<TransactionModel> transactions);

  /// Clear the cache.
  Future<void> clearCache();
}
