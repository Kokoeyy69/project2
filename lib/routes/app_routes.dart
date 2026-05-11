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
import '../presentation/ai_chat/ai_chat_screen.dart';
import '../presentation/ai_assistant/ai_chat_screen.dart';
import '../presentation/security/pin_entry_screen.dart';
import '../presentation/security/reset_pin_screen.dart';
import '../presentation/ocr/ocr_scanner_screen.dart';
import '../presentation/analytics/analytics_screen.dart';

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
  static const String aiChatScreen = '/ai-chat';
  static const String aiAssistantScreen = '/ai-assistant';
  static const String pinEntryScreen = '/pin-entry';
  static const String resetPinScreen = '/reset-pin';
  static const String ocrScannerScreen = '/ocr-scanner';
  static const String analyticsScreen = '/analytics';
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
    aiChatScreen: (context) => const AiChatScreen(),
    aiAssistantScreen: (context) => const AIChatScreen(),
    ocrScannerScreen: (context) => const OcrScannerScreen(),
    analyticsScreen: (context) => const AnalyticsScreen(),
    resetPinScreen: (context) => const ResetPinScreen(),
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
      case aiChatScreen:
        return _buildElegantPageRoute(const AiChatScreen(), settings);
      case aiAssistantScreen:
        return _buildPageRoute(const AIChatScreen(), settings);
      case ocrScannerScreen:
        return _buildPageRoute(const OcrScannerScreen(), settings);
      case analyticsScreen:
        return _buildPageRoute(const AnalyticsScreen(), settings);
      case resetPinScreen:
        return _buildPageRoute(const ResetPinScreen(), settings);
      case onboardingScreen:
        return _buildPageRoute(const OnboardingScreen(), settings);
      default:
        // Default-nya juga dikembalikan ke Splash Screen buat keamanan
        return _buildPageRoute(SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _buildPageRoute(Widget page, RouteSettings settings) {
    // Main tabs that should use snap-fast fade transitions
    final List<String> mainTabs = [
      homeScreen,
      transferKeypadScreen,
      activityScreen,
      profileScreen,
    ];

    // Use snap-fast fade for main tabs, slide+fade for others
    if (mainTabs.contains(settings.name)) {
      return PageRouteBuilder(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      );
    }

    // Default: Slide + Fade for non-main routes
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

  /// Elegant page transition for AI Chat Screen - slide up from bottom with fade
  static PageRouteBuilder _buildElegantPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(0.0, 1.0); // Start from bottom
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
    );
  }
}
