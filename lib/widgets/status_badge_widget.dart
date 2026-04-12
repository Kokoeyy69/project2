import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum TransactionStatus { completed, pending, processing, failed, refunded }

class StatusBadgeWidget extends StatelessWidget {
  final TransactionStatus status;
  final double? fontSize;

  const StatusBadgeWidget({super.key, required this.status, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.borderColor, width: 0.5),
      ),
      child: Text(
        config.label,
        style: GoogleFonts.inter(
          fontSize: fontSize ?? 10,
          fontWeight: FontWeight.w600,
          color: config.textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _StatusConfig _getConfig(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return _StatusConfig(
          label: 'Completed',
          textColor: AppTheme.success,
          backgroundColor: AppTheme.successMuted,
          borderColor: AppTheme.success.withAlpha(77),
        );
      case TransactionStatus.pending:
        return _StatusConfig(
          label: 'Pending',
          textColor: AppTheme.warning,
          backgroundColor: AppTheme.warningMuted,
          borderColor: AppTheme.warning.withAlpha(77),
        );
      case TransactionStatus.processing:
        return _StatusConfig(
          label: 'Processing',
          textColor: AppTheme.primary,
          backgroundColor: AppTheme.primaryMuted,
          borderColor: AppTheme.primary.withAlpha(77),
        );
      case TransactionStatus.failed:
        return _StatusConfig(
          label: 'Failed',
          textColor: AppTheme.error,
          backgroundColor: AppTheme.errorMuted,
          borderColor: AppTheme.error.withAlpha(77),
        );
      case TransactionStatus.refunded:
        return _StatusConfig(
          label: 'Refunded',
          textColor: AppTheme.accent,
          backgroundColor: AppTheme.accentMuted,
          borderColor: AppTheme.accent.withAlpha(77),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  _StatusConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
