import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../repositories/transactions_repository.dart';
import '../../../repositories/firestore_transactions_repository.dart';
import '../../../repositories/in_memory_transactions_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import 'package:neopay_ai/services/analytics_service.dart';

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
      status: statusFromString(map['status'] as String),
      categoryIcon: iconFromString(map['categoryIcon'] as String),
      categoryColor: Color(map['categoryColor'] as int),
      recipientNote: map['recipientNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantName': merchantName,
      'category': category,
      'amount': amount,
      'currency': currency,
      'time': time,
      'isDebit': isDebit,
      'status': statusToString(status),
      'categoryIconCodePoint': categoryIcon.codePoint,
      'categoryColor': categoryColor.toARGB32(),
      'recipientNote': recipientNote,
    };
  }

  static TransactionModel fromJson(Map<String, dynamic> json) {
    final iconCode = json['categoryIconCodePoint'] as int?;
    final icon = iconCode != null
        ? IconData(iconCode, fontFamily: 'MaterialIcons')
        : Icons.receipt_outlined;
    return TransactionModel(
      id: json['id'] as String,
      merchantName: json['merchantName'] as String,
      category: json['category'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      time: json['time'] as String,
      isDebit: json['isDebit'] as bool,
      status: statusFromString(json['status'] as String),
      categoryIcon: icon,
      categoryColor: Color(json['categoryColor'] as int),
      recipientNote: json['recipientNote'] as String?,
    );
  }

  static TransactionStatus statusFromString(String v) {
    switch (v) {
      case 'completed':
        return TransactionStatus.completed;
      case 'pending':
        return TransactionStatus.pending;
      case 'processing':
        return TransactionStatus.processing;
      case 'failed':
        return TransactionStatus.failed;
      case 'refunded':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.completed;
    }
  }

  static String statusToString(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.processing:
        return 'processing';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.refunded:
        return 'refunded';
    }
  }

  static IconData iconFromString(String v) {
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
  final bool disableNetwork;
  final TransactionsRepository? repository;
  const RecentTransactionsWidget({
    super.key,
    this.disableNetwork = false,
    this.repository,
  });

  @override
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  static const int _pageSize = 5;
  final List<TransactionModel> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  dynamic _cursor;
  StreamSubscription<TransactionModel>? _topRealtimeSub;
  late TransactionsRepository _repository;

  @override
  void initState() {
    super.initState();
    // Prefer explicit repository (injected). If none provided, pick an
    // implementation depending on whether network is disabled. This avoids
    // constructing Firestore-backed repos during widget tests (no Firebase
    // initialized).
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else if (widget.disableNetwork) {
      _repository = InMemoryTransactionsRepository();
    } else {
      // Default to Firestore repo in production; constructing it may still
      // touch Firebase instances, which is expected in app runtime.
      _repository = FirestoreTransactionsRepository();
    }

    _init();
  }

  Future<void> _init() async {
    // Load cached transactions first
    try {
      final cached = await _repository.loadCachedTransactions();
      if (cached.isNotEmpty) {
        _items.clear();
        _items.addAll(cached);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {}

    // If tests ask to disable network access, skip Firestore/Auth work.
    if (widget.disableNetwork) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    // Fetch first page from network
    await _fetchPage(reset: true);

    // Subscribe to top transaction updates
    _topRealtimeSub = _repository.watchTopTransaction().listen((model) {
      final idx = _items.indexWhere((m) => m.id == model.id);
      setState(() {
        if (idx == -1) {
          _items.insert(0, model);
        } else {
          _items[idx] = model;
        }
      });
      _saveCache();
    });
    _topRealtimeSub = _topRealtimeSub;
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime dt;
    if (timestamp is DateTime) {
      dt = timestamp;
    } else if (timestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return timestamp;
    } else if (timestamp is Map && timestamp['seconds'] != null) {
      final seconds = timestamp['seconds'] as int?;
      if (seconds != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else {
        return 'Just now';
      }
    } else {
      return 'Just now';
    }

    final diff = DateTime.now().difference(dt);
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

  Future<void> _fetchPage({bool reset = false}) async {
    if (widget.disableNetwork) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
      });
      return;
    }
    if (reset) {
      _items.clear();
      _cursor = null;
      _hasMore = true;
    }
    if (!_hasMore) return;
    if (_isLoadingMore) return;

    setState(() {
      if (_items.isEmpty) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final result = await _repository.fetchPage(
        pageSize: _pageSize,
        cursor: _cursor,
      );

      _items.addAll(result.items);
      _cursor = result.cursor;
      _hasMore = result.hasMore;

      if (result.items.isNotEmpty) {
        await _saveCache();
      }
    } catch (e) {
      _hasMore = false;
      _errorMessage = e.toString();
      AnalyticsService.instance.logEvent(
        'recent_transactions_error',
        params: {'error': _errorMessage},
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _saveCache() async {
    try {
      await _repository.saveCachedTransactions(_items);
    } catch (_) {}
  }

  @override
  void dispose() {
    _topRealtimeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If repository is explicitly provided (e.g., in tests), assume it handles
    // auth internally. If disableNetwork, don't check Firebase. Otherwise,
    // check if we have an auth user or cached items.
    final hasRepository = widget.repository != null;
    final hasUser = widget.disableNetwork
        ? true
        : (hasRepository
              ? true
              : (FirebaseAuth.instance.currentUser != null ||
                    _items.isNotEmpty));

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      AnalyticsService.instance.logEvent(
                        'recent_transactions_see_all',
                      );
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
                  IconButton(
                    onPressed: () {
                      AnalyticsService.instance.logEvent(
                        'recent_transactions_refresh',
                      );
                      _fetchPage(reset: true);
                    },
                    icon: const Icon(Icons.refresh),
                    color: AppTheme.primary,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Failed to load transactions. ${_errorMessage!.length > 120 ? '${_errorMessage!.substring(0, 120)}...' : _errorMessage}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        _fetchPage(reset: true);
                      },
                      child: Text(
                        'Retry',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                child: !hasUser
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            "Please login first",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              )
                            : _items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    "No recent transactions yet.",
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _items.length + (_hasMore ? 1 : 0),
                                separatorBuilder: (_, __) => Divider(
                                  color: AppTheme.separator,
                                  thickness: 0.5,
                                  height: 0,
                                  indent: 72,
                                ),
                                itemBuilder: (context, index) {
                                  if (index >= _items.length) {
                                    if (_isLoadingMore) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Center(
                                        child: TextButton(
                                          onPressed: () {
                                            AnalyticsService.instance.logEvent(
                                              'recent_transactions_load_more',
                                            );
                                            _fetchPage();
                                          },
                                          child: Text(
                                            'Load more',
                                            style: GoogleFonts.inter(
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final model = _items[index];
                                  return _TransactionItem(transaction: model);
                                },
                              ),
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
    final statusLabel = TransactionModel.statusToString(transaction.status);
    final semanticsLabel =
        'Transaction ${transaction.merchantName}, ${transaction.amount}, status $statusLabel';

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: () {},
        splashColor: AppTheme.primary.withAlpha(15),
        highlightColor: AppTheme.primary.withAlpha(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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
      ),
    );
  }
}
