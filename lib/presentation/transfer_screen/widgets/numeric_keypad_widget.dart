import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class NumericKeypadWidget extends StatelessWidget {
  final String displayAmount;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const NumericKeypadWidget({
    super.key,
    required this.displayAmount,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Column(
            children: [
              // Amount display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(120),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayAmount.isEmpty ? '0' : displayAmount,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: displayAmount.isEmpty
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: onBackspace,
                      onLongPress: onClear,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Keypad grid
              ...List.generate(3, (row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: List.generate(3, (col) {
                      final num = row * 3 + col + 1;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: col == 0 ? 0 : 4,
                            right: col == 2 ? 0 : 4,
                          ),
                          child: _KeyButton(
                            label: '$num',
                            onTap: () => onKeyTap('$num'),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
              // Bottom row: . 0 backspace
              Row(
                children: [
                  Expanded(
                    child: _KeyButton(label: '.', onTap: () => onKeyTap('.')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(label: '0', onTap: () => onKeyTap('0')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      label: '000',
                      onTap: () => onKeyTap('000'),
                    ),
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

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withAlpha(180),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
