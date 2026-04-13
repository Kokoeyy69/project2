import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

// Model data ditaruh di sini agar file ini mandiri
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
  final List<dynamic>? balances;
  final ValueChanged<int> onCardChanged;

  const WalletCardCarouselWidget({
    super.key,
    this.balances,
    required this.onCardChanged,
  });

  @override
  State<WalletCardCarouselWidget> createState() =>
      _WalletCardCarouselWidgetState();
}

class _WalletCardCarouselWidgetState extends State<WalletCardCarouselWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentIndex = 0;
  List<WalletCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _buildCards();
  }

  @override
  void didUpdateWidget(covariant WalletCardCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.balances != oldWidget.balances) {
      _buildCards();
    }
  }

  void _buildCards() {
    if (widget.balances == null || widget.balances!.length < 3) return;

    final idrFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final usdFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
    final cnyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2);

    setState(() {
      _cards = [
        WalletCard(
          currency: 'IDR',
          currencySymbol: 'Rp',
          balance: idrFormat.format(widget.balances![0]),
          cardNumber: '•••• •••• •••• 4821',
          holderName: 'RANIA KUSUMA',
          gradientColors: [const Color(0xFF1E3A5F), const Color(0xFF0D1F3C)],
          glowColor: const Color(0xFF3B82F6),
          flagEmoji: '🇮🇩',
          changePercent: '+2.4%',
          isPositiveChange: true,
        ),
        WalletCard(
          currency: 'USD',
          currencySymbol: '\$',
          balance: usdFormat.format(widget.balances![1]),
          cardNumber: '•••• •••• •••• 7293',
          holderName: 'RANIA KUSUMA',
          gradientColors: [const Color(0xFF1A3340), const Color(0xFF0A1A20)],
          glowColor: const Color(0xFF06B6D4),
          flagEmoji: '🇺🇸',
          changePercent: '-0.8%',
          isPositiveChange: false,
        ),
        WalletCard(
          currency: 'CNY',
          currencySymbol: '¥',
          balance: cnyFormat.format(widget.balances![2]),
          cardNumber: '•••• •••• •••• 5564',
          holderName: 'RANIA KUSUMA',
          gradientColors: [const Color(0xFF3D1A1A), const Color(0xFF1A0A0A)],
          glowColor: const Color(0xFFEF4444),
          flagEmoji: '🇨🇳',
          changePercent: '+1.1%',
          isPositiveChange: true,
        ),
      ];
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cards.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentIndex == index ? _cards[index].glowColor : const Color(0xFF94A3B8),
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
                  card.gradientColors[0].withOpacity(0.9),
                  card.gradientColors[1].withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: card.glowColor.withOpacity(0.35), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(card.flagEmoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(card.currency, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                      const Icon(Icons.contactless_rounded, size: 20, color: Colors.white54),
                    ],
                  ),
                  const Spacer(),
                  Text(card.currencySymbol, style: GoogleFonts.inter(fontSize: 16, color: Colors.white70)),
                  Text(card.balance, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(card.cardNumber, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, letterSpacing: 1.2)),
                      Text(card.holderName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}