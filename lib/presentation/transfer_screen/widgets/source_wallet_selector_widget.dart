import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SourceWalletSelectorWidget extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SourceWalletSelectorWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<SourceWalletSelectorWidget> createState() =>
      _SourceWalletSelectorWidgetState();
}

class _SourceWalletSelectorWidgetState
    extends State<SourceWalletSelectorWidget> {
  double _balanceIdr = 0;
  double _balanceUsd = 0;
  double _balanceCny = 0;
  bool _isLoading = true;

  static const List<_WalletOption> _wallets = [
    _WalletOption(
      currency: 'IDR',
      flag: '🇮🇩',
      balance: 0,
      color: Color(0xFF3B82F6),
    ),
    _WalletOption(
      currency: 'USD',
      flag: '🇺🇸',
      balance: 0,
      color: Color(0xFF06B6D4),
    ),
    _WalletOption(
      currency: 'CNY',
      flag: '🇨🇳',
      balance: 0,
      color: Color(0xFFEF4444),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchBalances();
  }

  Future<void> _fetchBalances() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _balanceIdr = (doc.data()?['balance'] as num?)?.toDouble() ?? 0;
        _balanceUsd = (doc.data()?['balance_usd'] as num?)?.toDouble() ?? 0;
        _balanceCny = (doc.data()?['balance_cny'] as num?)?.toDouble() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBalance(double amount, String currency) {
    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    } else if (currency == 'CNY') {
      return '¥${amount.toStringAsFixed(0)}';
    } else {
      return 'Rp${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(153),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Source Wallet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  children: List.generate(_wallets.length, (index) {
                    final w = _wallets[index];
                    final isSelected = index == widget.selectedIndex;
                    final balances = [_balanceIdr, _balanceUsd, _balanceCny];
                    final displayBalance = _formatBalance(
                      balances[index],
                      w.currency,
                    );
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                            right: index < _wallets.length - 1 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? w.color.withAlpha(38)
                                : AppTheme.glassBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? w.color.withAlpha(128)
                                  : AppTheme.glassBorder,
                              width: isSelected ? 1 : 0.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: w.color.withAlpha(31),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                w.flag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                w.currency,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? w.color
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                displayBalance,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletOption {
  final String currency;
  final String flag;
  final double balance;
  final Color color;

  const _WalletOption({
    required this.currency,
    required this.flag,
    required this.balance,
    required this.color,
  });
}
