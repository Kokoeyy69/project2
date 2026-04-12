import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _glowController;
  late AnimationController _floatController;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Global Currency',
      subtitle:
          'Exchange & transfer across 150+ currencies with real-time AI-powered rates',
      gradient: [const Color(0xFF1E3A5F), const Color(0xFF0D1F3C)],
      accentColor: AppTheme.primary,
      iconType: _IconType.globe,
    ),
    _OnboardingData(
      title: 'AI Smart Command',
      subtitle:
          'Ask anything about your finances. Our AI understands context and delivers instant insights',
      gradient: [const Color(0xFF1A2A40), const Color(0xFF0A1525)],
      accentColor: AppTheme.accent,
      iconType: _IconType.chat,
    ),
    _OnboardingData(
      title: 'Enterprise Security',
      subtitle:
          'Bank-grade biometric authentication and end-to-end encryption protect every transaction',
      gradient: [const Color(0xFF1A2A1A), const Color(0xFF0A150A)],
      accentColor: AppTheme.success,
      iconType: _IconType.shield,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signUpLoginScreen,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background particles
          ..._buildBackgroundParticles(),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _buildPage(_pages[index], index),
                ),
              ),
              _buildBottomSection(),
            ],
          ),
          // Skip button
          Positioned(
            top: 56,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.signUpLoginScreen,
                (_) => false,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.glassBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundParticles() {
    final rng = math.Random(42);
    return List.generate(12, (i) {
      final x = rng.nextDouble();
      final y = rng.nextDouble();
      final size = 2.0 + rng.nextDouble() * 3;
      return Positioned(
        left:
            x *
            MediaQueryData.fromView(
              WidgetsBinding.instance.platformDispatcher.views.first,
            ).size.width,
        top:
            y *
            MediaQueryData.fromView(
              WidgetsBinding.instance.platformDispatcher.views.first,
            ).size.height,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) => Opacity(
            opacity: _glowAnimation.value * 0.4,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentPage].accentColor,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPage(_OnboardingData data, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(
        children: [
          const Spacer(),
          // Icon card
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            ),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withAlpha(
                        (80 * _glowAnimation.value).round(),
                      ),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: child,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: data.gradient,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: data.accentColor.withAlpha(80),
                        width: 1,
                      ),
                    ),
                    child: _buildIcon(data),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Text content
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.glassBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: data.accentColor.withAlpha(40),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Accent line
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            data.accentColor,
                            data.accentColor.withAlpha(0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data.title,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildIcon(_OnboardingData data) {
    switch (data.iconType) {
      case _IconType.globe:
        return _GlobeIcon(color: data.accentColor);
      case _IconType.chat:
        return _ChatBubbleIcon(color: data.accentColor);
      case _IconType.shield:
        return _BiometricShieldIcon(color: data.accentColor);
    }
  }

  Widget _buildBottomSection() {
    final isLast = _currentPage == _pages.length - 1;
    final accentColor = _pages[_currentPage].accentColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentPage ? accentColor : AppTheme.glassBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          // CTA button
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLast
                      ? [accentColor, accentColor.withAlpha(200)]
                      : [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(80),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Icon Widgets ──────────────────────────────────────────────────────────────

class _GlobeIcon extends StatefulWidget {
  final Color color;
  const _GlobeIcon({required this.color});

  @override
  State<_GlobeIcon> createState() => _GlobeIconState();
}

class _GlobeIconState extends State<_GlobeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            // Globe body
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    widget.color.withAlpha(200),
                    widget.color.withAlpha(80),
                    widget.color.withAlpha(40),
                  ],
                ),
                border: Border.all(
                  color: widget.color.withAlpha(120),
                  width: 1.5,
                ),
              ),
            ),
            // Latitude lines
            Transform.rotate(
              angle: _rotateController.value * 2 * math.pi * 0.1,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: _GlobeLinePainter(color: widget.color),
              ),
            ),
            // Center dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(color: widget.color.withAlpha(150), blurRadius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobeLinePainter extends CustomPainter {
  final Color color;
  _GlobeLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(60)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Equator
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 0.5),
      paint,
    );
    // Meridian
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 0.5, height: r * 2),
      paint,
    );
    // Outer circle
    canvas.drawCircle(Offset(cx, cy), r - 1, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatBubbleIcon extends StatefulWidget {
  final Color color;
  const _ChatBubbleIcon({required this.color});

  @override
  State<_ChatBubbleIcon> createState() => _ChatBubbleIconState();
}

class _ChatBubbleIconState extends State<_ChatBubbleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _pulseAnimation.value, child: child),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withAlpha(20),
              ),
            ),
            // Chat bubble
            Container(
              width: 68,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.color, widget.color.withAlpha(180)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withAlpha(100),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricShieldIcon extends StatefulWidget {
  final Color color;
  const _BiometricShieldIcon({required this.color});

  @override
  State<_BiometricShieldIcon> createState() => _BiometricShieldIconState();
}

class _BiometricShieldIconState extends State<_BiometricShieldIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shield
          CustomPaint(
            size: const Size(80, 90),
            painter: _ShieldPainter(color: widget.color),
          ),
          // Scan line
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              final y = -20.0 + _scanAnimation.value * 40;
              return ClipPath(
                clipper: _ShieldClipper(),
                child: Container(
                  width: 60,
                  height: 80,
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, y + 20),
                    child: Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withAlpha(0),
                            widget.color,
                            widget.color.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Fingerprint icon
          Icon(Icons.fingerprint_rounded, color: widget.color, size: 36),
        ],
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color color;
  _ShieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color.withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width / 2,
      size.height,
    );
    path.quadraticBezierTo(0, size.height, 0, size.height * 0.6);
    path.lineTo(0, size.height * 0.2);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width / 2,
      size.height,
    );
    path.quadraticBezierTo(0, size.height, 0, size.height * 0.6);
    path.lineTo(0, size.height * 0.2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Data Model ────────────────────────────────────────────────────────────────

enum _IconType { globe, chat, shield }

class _OnboardingData {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final _IconType iconType;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.iconType,
  });
}
