import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class _Particle {
  Offset position;
  Offset velocity;
  double radius;
  double opacity;
  Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.opacity,
    required this.color,
  });
}

class AuthParticleBackgroundWidget extends StatefulWidget {
  const AuthParticleBackgroundWidget({super.key});

  @override
  State<AuthParticleBackgroundWidget> createState() =>
      _AuthParticleBackgroundWidgetState();
}

class _AuthParticleBackgroundWidgetState
    extends State<AuthParticleBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _controller.addListener(_updateParticles);
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    _screenSize = size;
    for (int i = 0; i < 45; i++) {
      _particles.add(_createParticle(size));
    }
  }

  _Particle _createParticle(Size size) {
    final colors = [AppTheme.primary, AppTheme.accent, Colors.white];
    return _Particle(
      position: Offset(
        _random.nextDouble() * size.width,
        _random.nextDouble() * size.height,
      ),
      velocity: Offset(
        (_random.nextDouble() - 0.5) * 0.4,
        (_random.nextDouble() - 0.5) * 0.4,
      ),
      radius: _random.nextDouble() * 2.5 + 0.5,
      opacity: _random.nextDouble() * 0.25 + 0.05,
      color: colors[_random.nextInt(colors.length)],
    );
  }

  void _updateParticles() {
    if (_screenSize == Size.zero) return;
    for (final p in _particles) {
      p.position = Offset(
        (p.position.dx + p.velocity.dx) % _screenSize.width,
        (p.position.dy + p.velocity.dy) % _screenSize.height,
      );
      if (p.position.dx < 0) {
        p.position = Offset(_screenSize.width, p.position.dy);
      }
      if (p.position.dy < 0) {
        p.position = Offset(p.position.dx, _screenSize.height);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initParticles(size);
        return CustomPaint(
          painter: _ParticlePainter(particles: _particles),
          size: size,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
