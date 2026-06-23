import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../routes/app_routes.dart';
import '../../../repositories/transactions_repository.dart';
import '../../../repositories/firestore_transactions_repository.dart';
import '../../../core/di/locator.dart';
import '../../../repositories/in_memory_transactions_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import 'package:neopay_ai/services/analytics_service.dart';
import '../../../models/transaction_model.dart';

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
  bool _isTopLoading = true;
  String? _errorMessage;
  dynamic _cursor;
  StreamSubscription<TransactionModel?>? _topRealtimeSub;
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
      _repository = locator<FirestoreTransactionsRepository>();
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (_) {}

    // If tests ask to disable network access, skip Firestore/Auth work.
    if (widget.disableNetwork) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTopLoading = false;
          _hasMore = false;
        });
      }
      return;
    }

    // Fetch first page from network
    await _fetchPage(reset: true);

    // Subscribe to top transaction updates
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _topRealtimeSub = _repository.watchTopTransaction(uid).listen((
      TransactionModel? model,
    ) {
      if (model == null) {
        // Show shimmer while loading
        if (mounted) setState(() => _isTopLoading = true);
        return;
      }

      final idx = _items.indexWhere((m) => m.id == model.id);
      if (idx == -1) {
        _items.insert(0, model);
      } else {
        _items[idx] = model;
      }
      if (mounted) {
        setState(() {
          _isTopLoading = false;
        });
      }
    });
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

    if (mounted) {
      setState(() {
        if (_items.isEmpty) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });
    }

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
      final errorStr = e.toString();
      if (errorStr.contains('permission-denied') ||
          errorStr.contains('PERMISSION_DENIED')) {
        // Silently treat permission errors as 'no data' to avoid scary red screens for new/restricted users
        _errorMessage = null;
      } else {
        _errorMessage = errorStr;
        AnalyticsService.instance.logEvent(
          'recent_transactions_error',
          params: {'error': _errorMessage},
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
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
                      Navigator.pushNamed(context, AppRoutes.activityScreen);
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
                  color: Colors.red.withValues(alpha: 0.92),
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
                    : (_isLoading || _isTopLoading)
                    ? _buildTransactionShimmer()
                    : _items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: 0.15,
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 72,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Belum ada transaksi",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
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
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
        ],
      ),
    );
  }

  Widget _buildTransactionShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E293B),
      highlightColor: const Color(0xFF334155),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  /// Check if this transaction is an expense for the current user
  bool get _isExpense {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return transaction.isDebit;
      return currentUid == transaction.senderUid;
    } catch (_) {
      return transaction.isDebit;
    }
  }

  /// Get the display name based on current user's role in the transaction
  String _getDisplayName() {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return transaction.merchantName;

      // If current user is the sender, show recipient name
      if (currentUid == transaction.senderUid) {
        return transaction.recipientName;
      }
      // If current user is the recipient, show sender name
      if (currentUid == transaction.recipientUid) {
        return transaction.senderName;
      }
    } catch (_) {}

    // Fallback to merchant name
    return transaction.merchantName;
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = TransactionModel.statusToString(transaction.status);
    final displayName = _getDisplayName();
    final isExpense = _isExpense;
    final amountColor = isExpense ? AppTheme.error : AppTheme.success;
    final amountIcon = isExpense
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final amountPrefix = isExpense ? '- ' : '+ ';
    final semanticsLabel =
        'Transaction $displayName, $amountPrefix${transaction.amount}, status $statusLabel';

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            AppRoutes.transactionDetailScreen,
            arguments: transaction,
          );
        },
        splashColor: AppTheme.primary.withValues(alpha: 15 / 255),
        highlightColor: AppTheme.primary.withValues(alpha: 8 / 255),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Hero(
                tag: 'tx_icon_${transaction.id}',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 38 / 255),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: amountColor.withValues(alpha: 51 / 255),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(amountIcon, color: amountColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
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
                    '$amountPrefix${transaction.amount}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
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
