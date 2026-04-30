import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    // Delay 3 detik biar user sempet lihat desainnya
    _timer = Timer(const Duration(seconds: 3), () {
      // Pastikan route '/onboarding' atau '/login' ini sudah ada di main.dart kamu
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding-screen');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Gradient Midnight Premium persis seperti di desain Rocket
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon dengan efek Glowing Emerald Green
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF10B981).withAlpha((0.3 * 255).round()),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 80,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),

            // Teks Judul
            const Text(
              "NeoPay AI",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // Slogan
            const Text(
              "Smart Future Finance",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),

            // Loading Indicator Minimalis
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
