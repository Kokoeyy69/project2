import 'dart:math';
import 'package:flutter/material.dart';

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
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            _updateParticles();
          })
          ..repeat();

    for (int i = 0; i < 20; i++) {
      _particles.add(
        _Particle(
          position: Offset(
            _random.nextDouble() * 400,
            _random.nextDouble() * 800,
          ),
          velocity: Offset(
            _random.nextDouble() * 2 - 1,
            _random.nextDouble() * 2 - 1,
          ),
          radius: _random.nextDouble() * 4 + 2,
          opacity: _random.nextDouble() * 0.4 + 0.1,
        ),
      );
    }
  }

  void _updateParticles() {
    // Using CustomPainter for performance; animation rebuilds through AnimatedBuilder.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  double radius;
  double opacity;

  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Update position based on velocity and animation
      particle.position += particle.velocity;

      // Wrap around edges
      if (particle.position.dx < 0) {
        particle.position = Offset(size.width, particle.position.dy);
      }
      if (particle.position.dx > size.width) {
        particle.position = Offset(0, particle.position.dy);
      }
      if (particle.position.dy < 0) {
        particle.position = Offset(particle.position.dx, size.height);
      }
      if (particle.position.dy > size.height) {
        particle.position = Offset(particle.position.dx, 0);
      }

      paint.color = Colors.blue.withValues(alpha: particle.opacity);
      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
