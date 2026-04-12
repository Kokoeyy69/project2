import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Aku hapus import activity_screen yang error/typo dari Rocket

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/transfer_screen/transfer_screen.dart';
import '../presentation/transfer_screen/transfer_keypad_screen.dart';
import '../presentation/transfer_screen/transfer_success_screen.dart';
import '../presentation/activity_screen/activity_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen'; // <-- Aku tambahin ini
  static const String homeScreen = '/home-screen';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String transferScreen = '/transfer-screen';
  static const String transferKeypadScreen = '/transfer-keypad-screen';
  static const String transferSuccessScreen = '/transfer-success-screen';
  static const String activityScreen = '/activity-screen';
  static const String profileScreen = '/profile-screen';
  static const String onboardingScreen = '/onboarding-screen';

  static Map<String, WidgetBuilder> routes = {
    // Sekarang aplikasi buka Splash Screen duluan, bukan Onboarding
    initial: (context) => SplashScreen(), 
    splashScreen: (context) => SplashScreen(),
    homeScreen: (context) => const HomeScreen(),
    signUpLoginScreen: (context) => const SignUpLoginScreen(),
    transferScreen: (context) => const TransferScreen(),
    transferKeypadScreen: (context) => const TransferKeypadScreen(),
    transferSuccessScreen: (context) => const TransferSuccessScreen(),
    activityScreen: (context) => const ActivityScreen(),
    profileScreen: (context) => const ProfileScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashScreen:
        return _buildPageRoute(SplashScreen(), settings);
      case homeScreen:
        return _buildPageRoute(const HomeScreen(), settings);
      case signUpLoginScreen:
        return _buildPageRoute(const SignUpLoginScreen(), settings);
      case transferScreen:
        return _buildPageRoute(const TransferScreen(), settings);
      case transferKeypadScreen:
        return _buildPageRoute(const TransferKeypadScreen(), settings);
      case transferSuccessScreen:
        return _buildPageRoute(const TransferSuccessScreen(), settings);
      case activityScreen:
        return _buildPageRoute(const ActivityScreen(), settings);
      case profileScreen:
        return _buildPageRoute(const ProfileScreen(), settings);
      case onboardingScreen:
        return _buildPageRoute(const OnboardingScreen(), settings);
      default:
        // Default-nya juga dikembalikan ke Splash Screen buat keamanan
        return _buildPageRoute(SplashScreen(), settings); 
    }
  }

  static PageRouteBuilder _buildPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}