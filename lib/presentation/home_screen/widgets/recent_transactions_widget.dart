import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class TransactionModel {
  final String id;
  final String merchantName;
  final String category;
  final String amount;
  final String currency;
  final String time;
  final bool isDebit;
  final TransactionStatus status;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? recipientNote;

  const TransactionModel({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.currency,
    required this.time,
    required this.isDebit,
    required this.status,
    required this.categoryIcon,
    required this.categoryColor,
    this.recipientNote,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      merchantName: map['merchantName'] as String,
      category: map['category'] as String,
      amount: map['amount'] as String,
      currency: map['currency'] as String,
      time: map['time'] as String,
      isDebit: map['isDebit'] as bool,
      status: _statusFromString(map['status'] as String),
      categoryIcon: _iconFromString(map['categoryIcon'] as String),
      categoryColor: Color(map['categoryColor'] as int),
      recipientNote: map['recipientNote'] as String?,
    );
  }

  static TransactionStatus _statusFromString(String v) {
    switch (v) {
      case 'completed':
        return TransactionStatus.completed;
      case 'pending':
        return TransactionStatus.pending;
      case 'processing':
        return TransactionStatus.processing;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.completed;
    }
  }

  static IconData _iconFromString(String v) {
    switch (v) {
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'phone_android':
        return Icons.phone_android_outlined;
      case 'flight':
        return Icons.flight_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }
}

class RecentTransactionsWidget extends StatefulWidget {
  const RecentTransactionsWidget({super.key});

  @override
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  late List<TransactionModel> _transactions;

  static final List<Map<String, dynamic>> _transactionMaps = [
    {
      'id': 'TXN-001',
      'merchantName': 'Tokopedia',
      'category': 'Shopping',
      'amount': '- Rp 425.000',
      'currency': 'IDR',
      'time': '2 min ago',
      'isDebit': true,
      'status': 'completed',
      'categoryIcon': 'shopping_bag',
      'categoryColor': 0xFF8B5CF6,
      'recipientNote': null,
    },
    {
      'id': 'TXN-002',
      'merchantName': 'Ahmad Fauzi',
      'category': 'Transfer Out',
      'amount': '- \$120.00',
      'currency': 'USD',
      'time': '1h ago',
      'isDebit': true,
      'status': 'processing',
      'categoryIcon': 'swap_horiz',
      'categoryColor': 0xFF3B82F6,
      'recipientNote': 'Rent share April',
    },
    {
      'id': 'TXN-003',
      'merchantName': 'Siti Rahayu',
      'category': 'Transfer In',
      'amount': '+ Rp 2.500.000',
      'currency': 'IDR',
      'time': '3h ago',
      'isDebit': false,
      'status': 'completed',
      'categoryIcon': 'swap_horiz',
      'categoryColor': 0xFF10B981,
      'recipientNote': 'Project payment',
    },
    {
      'id': 'TXN-004',
      'merchantName': 'GoFood',
      'category': 'Food & Dining',
      'amount': '- Rp 87.000',
      'currency': 'IDR',
      'time': 'Yesterday',
      'isDebit': true,
      'status': 'failed',
      'categoryIcon': 'restaurant',
      'categoryColor': 0xFFEF4444,
      'recipientNote': null,
    },
    {
      'id': 'TXN-005',
      'merchantName': 'Lion Air',
      'category': 'Travel',
      'amount': '- ¥1.850',
      'currency': 'CNY',
      'time': 'Yesterday',
      'isDebit': true,
      'status': 'pending',
      'categoryIcon': 'flight',
      'categoryColor': 0xFFF59E0B,
      'recipientNote': 'CGK-SIN Apr 15',
    },
  ];

  @override
  void initState() {
    super.initState();
    _transactions = _transactionMaps.map(TransactionModel.fromMap).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(153),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppTheme.separator,
                    thickness: 0.5,
                    height: 0,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    return _TransactionItem(transaction: _transactions[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      splashColor: AppTheme.primary.withAlpha(15),
      highlightColor: AppTheme.primary.withAlpha(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Category icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: transaction.categoryColor.withAlpha(38),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: transaction.categoryColor.withAlpha(51),
                  width: 0.5,
                ),
              ),
              child: Icon(
                transaction.categoryIcon,
                color: transaction.categoryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Merchant + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchantName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        transaction.category,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (transaction.recipientNote != null) ...[
                        Text(
                          ' · ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            transaction.recipientNote!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.amount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: transaction.isDebit
                        ? AppTheme.textPrimary
                        : AppTheme.success,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 5),
                    StatusBadgeWidget(status: transaction.status),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
