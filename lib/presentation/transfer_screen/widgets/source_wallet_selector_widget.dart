import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SourceWalletSelectorWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SourceWalletSelectorWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const List<_WalletOption> _wallets = [
    _WalletOption(
      currency: 'IDR',
      flag: '🇮🇩',
      balance: 'Rp 48.750.000',
      color: Color(0xFF3B82F6),
    ),
    _WalletOption(
      currency: 'USD',
      flag: '🇺🇸',
      balance: '\$3,182.50',
      color: Color(0xFF06B6D4),
    ),
    _WalletOption(
      currency: 'CNY',
      flag: '🇨🇳',
      balance: '¥22,415',
      color: Color(0xFFEF4444),
    ),
  ];

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
              Row(
                children: List.generate(_wallets.length, (index) {
                  final w = _wallets[index];
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelected(index),
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
                            Text(w.flag, style: const TextStyle(fontSize: 20)),
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
                              w.balance,
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
  final String balance;
  final Color color;

  const _WalletOption({
    required this.currency,
    required this.flag,
    required this.balance,
    required this.color,
  });
}
