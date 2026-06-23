import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/models/transaction_model.dart';
import 'package:neopay_ai/presentation/home_screen/widgets/recent_transactions_widget.dart';
import 'package:neopay_ai/repositories/transactions_repository.dart';
import 'package:neopay_ai/widgets/status_badge_widget.dart';
import 'package:neopay_ai/core/di/locator.dart';

class FakeTransactionsRepository implements TransactionsRepository {
  final List<TransactionModel> cachedTransactions;

  FakeTransactionsRepository({required this.cachedTransactions});

  @override
  Future<TransactionsFetchResult> fetchPage({
    required int pageSize,
    dynamic cursor,
  }) async {
    return TransactionsFetchResult(items: [], hasMore: false);
  }

  @override
  Stream<TransactionModel?> watchTopTransaction(String uid) {
    return Stream.empty();
  }

  @override
  Future<List<TransactionModel>> loadCachedTransactions() async {
    return cachedTransactions;
  }

  @override
  Future<void> saveCachedTransactions(
    List<TransactionModel> transactions,
  ) async {}

  @override
  Future<void> clearCache() async {}
}

void main() {
  setUpAll(() {
    locator.allowReassignment = true;
    setupLocator();
  });

  testWidgets('Shows cached transactions when available (disableNetwork)', (
    tester,
  ) async {
    final model = TransactionModel(
      id: 't1',
      merchantName: 'Shop 1',
      category: 'Shopping',
      amount: '- Rp 100.000',
      currency: 'IDR',
      time: '1h ago',
      isDebit: true,
      status: TransactionStatus.completed,
      categoryIcon: Icons.receipt_outlined,
      categoryColor: const Color(0xFF3B82F6),
    );

    final fakeRepository = FakeTransactionsRepository(
      cachedTransactions: [model],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentTransactionsWidget(
            disableNetwork: true,
            repository: fakeRepository,
          ),
        ),
      ),
    );

    // Let the Future inside _init complete
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Shop 1'), findsOneWidget);
    expect(find.text('Please login first'), findsNothing);
    expect(find.text('No recent transactions yet.'), findsNothing);
  });

  testWidgets('Shows empty state when no cache and network disabled', (
    tester,
  ) async {
    final fakeRepository = FakeTransactionsRepository(cachedTransactions: []);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentTransactionsWidget(
            disableNetwork: true,
            repository: fakeRepository,
          ),
        ),
      ),
    );

    // Let the Future inside _init complete
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No recent transactions yet.'), findsOneWidget);
  });
}
