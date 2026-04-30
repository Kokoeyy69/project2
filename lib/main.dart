import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import '../core/app_export.dart';
import '../services/analytics_service.dart';
import '../services/firebase_analytics_provider.dart';
import '../widgets/custom_error_widget.dart';
// Note: AppRoutes is re-exported via app_export.dart
// Note: Pastikan AppRoutes sudah ter-import di dalam app_export.dart
// Kalau error merah di AppRoutes, tambahkan manual: import '../routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Initialize Firebase Analytics provider
  AnalyticsService.instance.setProvider(FirebaseAnalyticsProvider());

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'NeoPay AI',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          // UBAH INI: Paksa aplikasi pakai Dark Mode biar tema Midnight Premium-nya nyala!
          themeMode: ThemeMode.dark,

          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },

          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false, // Pita debug dihilangkan
          // SAMBUNGAN RUTE NAVIGASI
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,

          // TAMBAHAN: Biar fallback rute (kalau ada error salah panggil halaman) larinya ke Splash Screen
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
