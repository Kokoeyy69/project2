import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class NumericKeypadWidget extends StatelessWidget {
  // 1. Simpan parameternya di sini biar gak ilang
  final Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final String displayAmount;

  const NumericKeypadWidget({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onClear,
    required this.displayAmount,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Provider udah dihapus, kita murni pakai parameter lemparan dari atas

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
                            // 3. Panggil fungsi onKeyTap
                            onTap: () => onKeyTap('$num'),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
              // Bottom row: C 0 backspace
              Row(
                children: [
                  Expanded(
                    // Tombol titik (.) diubah jadi C (Clear)
                    child: _KeyButton(
                      label: 'C', 
                      onTap: onClear,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      label: '0',
                      onTap: () => onKeyTap('0'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      icon: Icons.backspace_outlined,
                      onTap: onBackspace,
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
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeyButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Biar tombol C warnanya merah dikit
    final isClearBtn = label == 'C';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withAlpha(180),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isClearBtn ? AppTheme.error.withAlpha(100) : AppTheme.glassBorder, 
            width: 0.5
          ),
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(
                label!,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isClearBtn ? AppTheme.error : AppTheme.textPrimary,
                ),
              )
            : Icon(
                icon,
                size: 20,
                color: AppTheme.textPrimary,
              ),
      ),
    );
  }
}