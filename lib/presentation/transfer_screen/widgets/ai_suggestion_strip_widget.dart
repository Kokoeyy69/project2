import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AiSuggestionStripWidget extends StatelessWidget {
  final int selectedWalletIndex;

  const AiSuggestionStripWidget({super.key, required this.selectedWalletIndex});

  static const List<_AiSuggestion> _suggestions = [
    _AiSuggestion(
      message:
          'IDR/USD rate is 0.8% above 7-day average. Good time to convert.',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF10B981),
      label: 'Optimal Timing',
    ),
    _AiSuggestion(
      message:
          'USD rate slightly below weekly average. Consider waiting 2–4 hours.',
      icon: Icons.access_time_rounded,
      color: Color(0xFFF59E0B),
      label: 'Wait Suggested',
    ),
    _AiSuggestion(
      message:
          'CNY rate stable. No significant movement expected in 24h window.',
      icon: Icons.horizontal_rule_rounded,
      color: Color(0xFF3B82F6),
      label: 'Rate Stable',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestions[selectedWalletIndex];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: suggestion.color.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: suggestion.color.withAlpha(64),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Insight · ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: suggestion.color.withAlpha(38),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                suggestion.icon,
                                size: 10,
                                color: suggestion.color,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                suggestion.label,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: suggestion.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      suggestion.message,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSuggestion {
  final String message;
  final IconData icon;
  final Color color;
  final String label;

  const _AiSuggestion({
    required this.message,
    required this.icon,
    required this.color,
    required this.label,
  });
}
