import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AiCommandBarWidget extends StatefulWidget {
  const AiCommandBarWidget({super.key});

  @override
  State<AiCommandBarWidget> createState() => _AiCommandBarWidgetState();
}

class _AiCommandBarWidgetState extends State<AiCommandBarWidget>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _suggestions = [
    'Best time to convert IDR to USD?',
    'Summarize my spending this week',
    'Send \$50 to Ahmad Fauzi',
    'Show exchange rate trends',
  ];
  int _suggestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Cycle suggestions
    Future.delayed(const Duration(seconds: 3), _cycleSuggestion);
  }

  void _cycleSuggestion() {
    if (!mounted) return;
    setState(() {
      _suggestionIndex = (_suggestionIndex + 1) % _suggestions.length;
    });
    Future.delayed(const Duration(seconds: 3), _cycleSuggestion);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: GestureDetector(
            onTap: () {
              // TODO: Navigate to AI chat screen
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.primaryMuted.withAlpha(38),
                    AppTheme.accentMuted.withAlpha(26),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withAlpha(64),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // Wave animation icon
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _WaveIconPainter(
                            progress: _waveController.value,
                            color: AppTheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cycling suggestion text
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _suggestions[_suggestionIndex],
                        key: ValueKey(_suggestionIndex),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // AI badge
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveIconPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveIconPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final barCount = 5;
    final barWidth = size.width / (barCount * 2 - 1);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final phase = (progress + i * 0.15) % 1.0;
      final heightFactor = math.sin(phase * 2 * math.pi).abs();
      final barHeight = 4.0 + heightFactor * (size.height * 0.55 - 4.0);
      final opacity = 0.4 + heightFactor * 0.6;

      paint.color = color.withOpacity(opacity);

      final x = i * barWidth * 2 + barWidth / 2;
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveIconPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
