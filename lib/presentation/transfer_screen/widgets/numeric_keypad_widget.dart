import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../transfer_view_model.dart';

class NumericKeypadWidget extends StatelessWidget {
  const NumericKeypadWidget({super.key, required void Function(String key) onKeyTap, required void Function() onBackspace, required String displayAmount, required void Function() onClear});

  @override
  Widget build(BuildContext context) {
    final transferViewModel = context.read<TransferViewModel>();

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
                            onTap: () => transferViewModel.onKeyPress('$num'),
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
                    child: _KeyButton(label: '.', onTap: () {}),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      label: '0',
                      onTap: () => transferViewModel.onKeyPress('0'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      icon: Icons.backspace_outlined,
                      onTap: () => transferViewModel.onKeyPress('backspace'),
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
        child: label != null
            ? Text(
                label!,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
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
