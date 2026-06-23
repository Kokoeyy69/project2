import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import '../core/app_export.dart';
import '../core/di/locator.dart';
import '../core/providers/ai_provider.dart';
import '../core/providers/currency_provider.dart';
import '../core/services/security_service.dart';
import '../presentation/security/pin_entry_screen.dart';
import '../services/analytics_service.dart';
import '../services/firebase_analytics_provider.dart';
import '../services/hive_cache_service.dart';
import '../widgets/custom_error_widget.dart';
// Note: AppRoutes is re-exported via app_export.dart
// Note: Pastikan AppRoutes sudah ter-import di dalam app_export.dart
// Kalau error merah di AppRoutes, tambahkan manual: import '../routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await HiveCacheService.init();
  setupLocator();

  // Initialize Currency Service for exchange rates
  // This runs silently in background - rates are cached for 12 hours
  final currencyProvider = CurrencyProvider();
  // Fire and forget - don't await to avoid blocking app startup
  currencyProvider.init().catchError((e) {
    debugPrint('CurrencyProvider initialization error: $e');
  });

  // Initialize AI Provider for smart transfer functionality
  final aiProvider = AIProvider();
  // Initialize with currency provider for conversion support
  aiProvider.init(currencyProvider: currencyProvider).catchError((e) {
    debugPrint('AIProvider initialization error: $e');
  });

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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Pass the already-initialized providers to avoid double initialization
  runApp(MyApp(
    currencyProvider: currencyProvider,
    aiProvider: aiProvider,
  ));
}

class MyApp extends StatefulWidget {
  final CurrencyProvider currencyProvider;
  final AIProvider aiProvider;

  const MyApp({
    super.key,
    required this.currencyProvider,
    required this.aiProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SecurityService _security = SecurityService.instance;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _security.onAppBackground();
      setState(() => _isLocked = true);
    } else if (state == AppLifecycleState.resumed) {
      _checkLockAndRates();
    }
  }

  Future<void> _checkLockAndRates() async {
    // Auto-refresh currency rates if stale
    await widget.currencyProvider.refreshIfStale();

    // Check if we need to show PIN/biometric
    final isAuth = await _security.onAppResume();
    final autoLock = await _security.autoLockEnabled;
    
    // Add a slight delay before showing the lock screen to prevent UI freeze on app resume
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      if (!isAuth && autoLock) {
        setState(() => _isLocked = true);
      } else {
        setState(() => _isLocked = false);
      }
    }
  }

  void _unlock() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrencyProvider>.value(value: widget.currencyProvider),
        ChangeNotifierProvider<AIProvider>.value(value: widget.aiProvider),
      ],
      child: Sizer(
        builder: (context, orientation, screenType) {
          return MaterialApp(
            title: 'NeoPay AI',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: Stack(
                  children: [
                    child!,
                    if (_isLocked)
                      _PrivacyScreen(
                        onUnlock: _unlock,
                      ),
                  ],
                ),
              );
            },
            debugShowCheckedModeBanner: false,
            routes: AppRoutes.routes,
            initialRoute: AppRoutes.initial,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}

class _PrivacyScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _PrivacyScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
return Material(
  color: AppTheme.background,
  child: PinEntryScreen(
    title: 'App Locked',
  ),
);
  }
}
