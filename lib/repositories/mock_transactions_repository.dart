import '../presentation/home_screen/widgets/recent_transactions_widget.dart';
import 'transactions_repository.dart';

/// Mock repository for testing pagination and load-more scenarios.
class MockTransactionsRepository implements TransactionsRepository {
  final List<List<TransactionModel>> pages;
  int currentPage = 0;

  MockTransactionsRepository({required this.pages});

  @override
  Future<TransactionsFetchResult> fetchPage({
    required int pageSize,
    dynamic cursor,
  }) async {
    if (currentPage >= pages.length) {
      return TransactionsFetchResult(items: [], hasMore: false);
    }

    final page = pages[currentPage];
    currentPage++;

    return TransactionsFetchResult(
      items: page,
      hasMore: currentPage < pages.length,
      cursor: currentPage,
    );
  }

  @override
  Stream<TransactionModel> watchTopTransaction() {
    return Stream.empty();
  }

  @override
  Future<List<TransactionModel>> loadCachedTransactions() async {
    return [];
  }

  @override
  Future<void> saveCachedTransactions(
    List<TransactionModel> transactions,
  ) async {}

  @override
  Future<void> clearCache() async {}

  void reset() {
    currentPage = 0;
  }
}
