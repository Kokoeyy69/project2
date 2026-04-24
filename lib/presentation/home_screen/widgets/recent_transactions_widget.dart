import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Fungsi pintar buat ngerubah timestamp jadi teks ala sosmed (1h ago, Just now)
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                onPressed: () {
                  Navigator.pushNamed(context, '/activity');
                },
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
                
                // --- KITA GANTI LISTVIEW STATIS JADI STREAMBUILDER FIREBASE ---
                child: user == null
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text("Please login first", style: TextStyle(color: Colors.white))),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('transactions')
                            .where('userId', isEqualTo: user.uid)
                            .orderBy('timestamp', descending: true)
                            .limit(5) // Cuma ambil 5 transaksi terakhir biar hemat kuota
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(child: Text('Error loading history', style: GoogleFonts.inter(color: Colors.white))),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          // Kalau belum ada transaksi sama sekali
                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  "No recent transactions yet.",
                                  style: GoogleFonts.inter(color: AppTheme.textMuted),
                                ),
                              ),
                            );
                          }

                          // Render riwayat betulan
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => Divider(
                              color: AppTheme.separator,
                              thickness: 0.5,
                              height: 0,
                              indent: 72,
                            ),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              
                              // Racik datanya biar pas sama UI
                              final amountVal = (data['amount'] as num?)?.toDouble() ?? 0.0;
                              final currency = data['currency'] ?? 'IDR';
                              
                              // Format angka biar ada titiknya
                              String amountStr = amountVal.toStringAsFixed(0).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (m) => '${m[1]}.',
                              );

                              String prefix = currency == 'USD' ? '\$' : (currency == 'CNY' ? '¥ ' : 'Rp ');
                              
                              // Masukin data Firebase ke TransactionModel bawaanmu
                              final model = TransactionModel(
                                id: docs[index].id,
                                merchantName: data['recipientName'] ?? 'Unknown',
                                category: data['type'] == 'transfer_out' ? 'Transfer Out' : 'Transaction',
                                amount: '- $prefix$amountStr', // Kasih minus karena duit keluar
                                currency: currency,
                                time: _getTimeAgo(data['timestamp'] as Timestamp?),
                                isDebit: true, // Debit = duit keluar
                                status: TransactionModel._statusFromString(data['status'] ?? 'completed'),
                                categoryIcon: Icons.swap_horiz_rounded, // Pakai icon transfer
                                categoryColor: const Color(0xFF3B82F6), // Warna biru buat transfer
                                recipientNote: null,
                              );

                              return _TransactionItem(transaction: model);
                            },
                          );
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