import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class TransferFeeBreakdownWidget extends StatelessWidget {
  final double amount;
  final int selectedWalletIndex;

  const TransferFeeBreakdownWidget({
    super.key,
    required this.amount,
    required this.selectedWalletIndex,
  });

  static const List<_WalletFeeConfig> _feeConfigs = [
    _WalletFeeConfig(
      currency: 'IDR',
      symbol: 'Rp',
      feeRate: 0.005,
      minFee: 2500,
      maxFee: 25000,
      exchangeRate: 'Rp 15,750 / USD',
      feeLabel: 'Transfer fee (0.5%)',
    ),
    _WalletFeeConfig(
      currency: 'USD',
      symbol: '\$',
      feeRate: 0.008,
      minFee: 0.5,
      maxFee: 15,
      exchangeRate: '\$1 = Rp 15,750',
      feeLabel: 'Transfer fee (0.8%)',
    ),
    _WalletFeeConfig(
      currency: 'CNY',
      symbol: '¥',
      feeRate: 0.006,
      minFee: 3,
      maxFee: 80,
      exchangeRate: '¥1 = Rp 2,215',
      feeLabel: 'Transfer fee (0.6%)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final config = _feeConfigs[selectedWalletIndex];
    final fee = (amount * config.feeRate).clamp(config.minFee, config.maxFee);
    final total = amount + fee;
    final hasAmount = amount > 0;

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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Fee Breakdown',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Transparent pricing',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildRow(
                'You send',
                hasAmount ? '${config.symbol} ${_fmt(amount, config)}' : '—',
                AppTheme.textPrimary,
              ),
              const SizedBox(height: 10),
              _buildRow(
                config.feeLabel,
                hasAmount ? '${config.symbol} ${_fmt(fee, config)}' : '—',
                AppTheme.warning,
              ),
              const SizedBox(height: 10),
              _buildRow(
                'Exchange rate',
                config.exchangeRate,
                AppTheme.textSecondary,
                isMono: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(height: 0.5, color: AppTheme.separator),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total debit',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    hasAmount ? '${config.symbol} ${_fmt(total, config)}' : '—',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (hasAmount) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMuted.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(38),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Protected by NeoPay AI fraud detection',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double value, _WalletFeeConfig config) {
    if (config.currency == 'IDR') {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(2)} Jt';
      }
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Widget _buildRow(
    String label,
    String value,
    Color valueColor, {
    bool isMono = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _WalletFeeConfig {
  final String currency;
  final String symbol;
  final double feeRate;
  final double minFee;
  final double maxFee;
  final String exchangeRate;
  final String feeLabel;

  const _WalletFeeConfig({
    required this.currency,
    required this.symbol,
    required this.feeRate,
    required this.minFee,
    required this.maxFee,
    required this.exchangeRate,
    required this.feeLabel,
  });
}
