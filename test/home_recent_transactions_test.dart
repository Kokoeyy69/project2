import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neopay_ai/presentation/home_screen/widgets/recent_transactions_widget.dart';
import 'package:neopay_ai/widgets/status_badge_widget.dart';
import 'package:neopay_ai/repositories/mock_transactions_repository.dart';

void main() {
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

    SharedPreferences.setMockInitialValues({
      'cached_transactions': json.encode([model.toJson()]),
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecentTransactionsWidget(disableNetwork: true)),
      ),
    );

    await tester.pump();

    expect(find.text('Shop 1'), findsOneWidget);
    expect(find.text('Please login first'), findsNothing);
    expect(find.text('No recent transactions yet.'), findsNothing);
  });

  testWidgets('Shows empty state when no cache and network disabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecentTransactionsWidget(disableNetwork: true)),
      ),
    );

    await tester.pump();

    expect(find.text('No recent transactions yet.'), findsOneWidget);
  });
}
