import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

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
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.signUpLoginScreen);
    } else {
      // If logged in, go to home (SecurityService will auto-overlay PIN if needed)
      Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
    }
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
