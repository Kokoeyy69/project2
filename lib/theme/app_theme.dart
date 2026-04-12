import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Palette ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0F14);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1A2340);
  static const Color surfaceElevated = Color(0xFF1E2D45);

  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryMuted = Color(0x4D3B82F6);
  static const Color primaryContainer = Color(0xFF1D3A6B);

  static const Color accent = Color(0xFF06B6D4);
  static const Color accentMuted = Color(0x3306B6D4);

  static const Color success = Color(0xFF10B981);
  static const Color successMuted = Color(0x2010B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningMuted = Color(0x20F59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorMuted = Color(0x20EF4444);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color separator = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassBackground = Color(0x0DFFFFFF);

  // ── Currency Card Gradients ───────────────────────────────────────────────
  static const List<Color> idrCardGradient = [
    Color(0xFF1E3A5F),
    Color(0xFF0D1F3C),
  ];
  static const List<Color> usdCardGradient = [
    Color(0xFF1A3340),
    Color(0xFF0A1A20),
  ];
  static const List<Color> cnyCardGradient = [
    Color(0xFF3D1A1A),
    Color(0xFF1A0A0A),
  ];

  // ── Light Theme (required by contract) ───────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: primary,
            primaryContainer: primaryContainer,
            secondary: accent,
            secondaryContainer: Color(0xFF0E3040),
            surface: surface,
            error: error,
            onPrimary: Color(0xFFFFFFFF),
            onSecondary: Color(0xFFFFFFFF),
            onSurface: textPrimary,
            onError: Color(0xFFFFFFFF),
            outline: Color(0xFF334155),
            outlineVariant: Color(0xFF1E293B),
            surfaceContainerHighest: surfaceVariant,
          )
        : ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.light,
          );

    final textTheme = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: isDark ? textPrimary : const Color(0xFF0D0F14),
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? textPrimary : const Color(0xFF0D0F14),
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? textPrimary : const Color(0xFF0D0F14),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? textPrimary : const Color(0xFF0D0F14),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? textPrimary : const Color(0xFF111827),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? textPrimary : const Color(0xFF111827),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? textPrimary : const Color(0xFF111827),
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? textSecondary : const Color(0xFF475569),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark ? textPrimary : const Color(0xFF1E293B),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? textSecondary : const Color(0xFF475569),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? textMuted : const Color(0xFF64748B),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? textPrimary : const Color(0xFF0D0F14),
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? textSecondary : const Color(0xFF475569),
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? textMuted : const Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? background : const Color(0xFFF8FAFC),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? textPrimary : const Color(0xFF0D0F14),
        ),
        iconTheme: IconThemeData(
          color: isDark ? textPrimary : const Color(0xFF0D0F14),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? surfaceVariant : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isDark ? glassBackground : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? glassBorder : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? glassBorder : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: isDark ? textSecondary : const Color(0xFF475569),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark ? textMuted : const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? separator : const Color(0xFFE2E8F0),
        thickness: 0.5,
        space: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
