import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AmountInputWidget extends StatefulWidget {
  final int selectedWalletIndex;
  final ValueChanged<double> onAmountChanged;

  const AmountInputWidget({
    super.key,
    required this.selectedWalletIndex,
    required this.onAmountChanged,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;

  static const List<_CurrencyConfig> _configs = [
    _CurrencyConfig(
      symbol: 'Rp',
      currency: 'IDR',
      hint: '0',
      convertLabel: '≈ \$0.00 USD',
      color: Color(0xFF3B82F6),
      quickAmounts: ['100K', '500K', '1Jt', '5Jt'],
      quickValues: [100000, 500000, 1000000, 5000000],
    ),
    _CurrencyConfig(
      symbol: '\$',
      currency: 'USD',
      hint: '0.00',
      convertLabel: '≈ Rp 0 IDR',
      color: Color(0xFF06B6D4),
      quickAmounts: ['\$10', '\$50', '\$100', '\$500'],
      quickValues: [10, 50, 100, 500],
    ),
    _CurrencyConfig(
      symbol: '¥',
      currency: 'CNY',
      hint: '0.00',
      convertLabel: '≈ Rp 0 IDR',
      color: Color(0xFFEF4444),
      quickAmounts: ['¥50', '¥100', '¥500', '¥1000'],
      quickValues: [50, 100, 500, 1000],
    ),
  ];

  String _getConvertedLabel(String raw) {
    final value = double.tryParse(raw.replaceAll(',', '')) ?? 0;
    final config = _configs[widget.selectedWalletIndex];
    switch (widget.selectedWalletIndex) {
      case 0: // IDR → USD
        final usd = value / 15750;
        return '≈ \$${usd.toStringAsFixed(2)} USD';
      case 1: // USD → IDR
        final idr = value * 15750;
        return '≈ Rp ${_formatIdr(idr)} IDR';
      case 2: // CNY → IDR
        final idr = value * 2215;
        return '≈ Rp ${_formatIdr(idr)} IDR';
      default:
        return config.convertLabel;
    }
  }

  String _formatIdr(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _configs[widget.selectedWalletIndex];

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Large amount input
              Focus(
                onFocusChange: (v) => setState(() => _isFocused = v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isFocused
                          ? config.color.withAlpha(153)
                          : AppTheme.glassBorder,
                      width: _isFocused ? 1.2 : 0.5,
                    ),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: config.color.withAlpha(26),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        config.symbol,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: config.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d,.]'),
                            ),
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: InputDecoration(
                            hintText: config.hint,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            final parsed =
                                double.tryParse(v.replaceAll(',', '')) ?? 0.0;
                            widget.onAmountChanged(parsed);
                            setState(() {});
                          },
                        ),
                      ),
                      Text(
                        config.currency,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Conversion preview
              if (_controller.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getConvertedLabel(_controller.text),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '@ live rate',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Quick amount chips
              Wrap(
                spacing: 8,
                children: List.generate(config.quickAmounts.length, (i) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = config.quickValues[i].toString();
                      widget.onAmountChanged(config.quickValues[i].toDouble());
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: config.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: config.color.withAlpha(64),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        config.quickAmounts[i],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: config.color,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              // Note field
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                ),
                child: TextField(
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyConfig {
  final String symbol;
  final String currency;
  final String hint;
  final String convertLabel;
  final Color color;
  final List<String> quickAmounts;
  final List<num> quickValues;

  const _CurrencyConfig({
    required this.symbol,
    required this.currency,
    required this.hint,
    required this.convertLabel,
    required this.color,
    required this.quickAmounts,
    required this.quickValues,
  });
}
