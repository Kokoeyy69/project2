import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class WalletCard {
  final String currency;
  final String currencySymbol;
  final String balance;
  final String cardNumber;
  final String holderName;
  final List<Color> gradientColors;
  final Color glowColor;
  final String flagEmoji;
  final String changePercent;
  final bool isPositiveChange;

  const WalletCard({
    required this.currency,
    required this.currencySymbol,
    required this.balance,
    required this.cardNumber,
    required this.holderName,
    required this.gradientColors,
    required this.glowColor,
    required this.flagEmoji,
    required this.changePercent,
    required this.isPositiveChange,
  });
}

class WalletCardCarouselWidget extends StatefulWidget {
  final ValueChanged<int> onCardChanged;

  const WalletCardCarouselWidget({super.key, required this.onCardChanged});

  @override
  State<WalletCardCarouselWidget> createState() =>
      _WalletCardCarouselWidgetState();
}

class _WalletCardCarouselWidgetState extends State<WalletCardCarouselWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentIndex = 0;

  static const List<WalletCard> _cards = [
    WalletCard(
      currency: 'IDR',
      currencySymbol: 'Rp',
      balance: '48.750.000',
      cardNumber: '•••• •••• •••• 4821',
      holderName: 'RANIA KUSUMA',
      gradientColors: [Color(0xFF1E3A5F), Color(0xFF0D1F3C)],
      glowColor: Color(0xFF3B82F6),
      flagEmoji: '🇮🇩',
      changePercent: '+2.4%',
      isPositiveChange: true,
    ),
    WalletCard(
      currency: 'USD',
      currencySymbol: '\$',
      balance: '3,182.50',
      cardNumber: '•••• •••• •••• 7293',
      holderName: 'RANIA KUSUMA',
      gradientColors: [Color(0xFF1A3340), Color(0xFF0A1A20)],
      glowColor: Color(0xFF06B6D4),
      flagEmoji: '🇺🇸',
      changePercent: '-0.8%',
      isPositiveChange: false,
    ),
    WalletCard(
      currency: 'CNY',
      currencySymbol: '¥',
      balance: '22,415.00',
      cardNumber: '•••• •••• •••• 5564',
      holderName: 'RANIA KUSUMA',
      gradientColors: [Color(0xFF3D1A1A), Color(0xFF1A0A0A)],
      glowColor: Color(0xFFEF4444),
      flagEmoji: '🇨🇳',
      changePercent: '+1.1%',
      isPositiveChange: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _cards.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onCardChanged(index);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageController.position.haveDimensions) {
                    double page = _pageController.page ?? index.toDouble();
                    scale = (1.0 - (page - index).abs() * 0.06).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: _WalletCardItem(card: _cards[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cards.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? _cards[index].glowColor
                    : AppTheme.textMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _WalletCardItem extends StatelessWidget {
  final WalletCard card;

  const _WalletCardItem({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  card.gradientColors[0].withAlpha(230),
                  card.gradientColors[1].withAlpha(242),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: card.glowColor.withAlpha(89), width: 1),
              boxShadow: [
                BoxShadow(
                  color: card.glowColor.withAlpha(46),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background circuit pattern
                Positioned(
                  right: -20,
                  top: -20,
                  child: _buildDecorativeCircle(card.glowColor, 120),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: _buildDecorativeCircle(card.glowColor, 90),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: currency flag + name + chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                card.flagEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                card.currency,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(230),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          // NFC chip icon
                          Container(
                            width: 32,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withAlpha(77),
                                  Colors.white.withAlpha(26),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withAlpha(51),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.contactless_rounded,
                              size: 14,
                              color: Colors.white.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Balance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            card.currencySymbol,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(179),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            card.balance,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Change indicator
                      Row(
                        children: [
                          Icon(
                            card.isPositiveChange
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: card.isPositiveChange
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${card.changePercent} today',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: card.isPositiveChange
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Bottom row: card number + holder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            card.cardNumber,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(128),
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            card.holderName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha(153),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(20), width: 1),
      ),
    );
  }
}
