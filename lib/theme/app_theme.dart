import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette
  static const Color bgMidnight = Color(0xFF090D16);
  static const Color bgAbyss = Color(0xFF0F1524);
  static const Color surfaceElevated = Color(0xFF161F36);
  static const Color surfaceCard = Color(0xFF1B2642);
  static const Color surfaceCardBorder = Color(0xFF283659);

  // Sacred Gold & Warm Light
  static const Color primaryGold = Color(0xFFE5B352);
  static const Color brightGold = Color(0xFFFFD369);
  static const Color paleGold = Color(0xFFFBE7B5);
  static const Color darkGold = Color(0xFF9E782F);
  static const Color goldGlow = Color(0x4DFFD369);
  static const Color amberAccent = Color(0xFFFF9F1C);

  // Celestial Accents
  static const Color celestialCyan = Color(0xFF4EA8DE);
  static const Color sereneIndigo = Color(0xFF6366F1);
  static const Color livingGreen = Color(0xFF10B981);
  static const Color pulseRed = Color(0xFFEF4444);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textGold = Color(0xFFF6DE9C);

  // Gradients
  static const LinearGradient deepSpaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF070A12),
      Color(0xFF0E1424),
      Color(0xFF090D18),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient goldShimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFDF7D),
      Color(0xFFE5B352),
      Color(0xFFC78B2B),
    ],
  );

  static const LinearGradient activeMicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFDF7D),
      Color(0xFFFFA834),
      Color(0xFFE5B352),
    ],
  );

  static const LinearGradient listeningHaloGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x66FFD369),
      Color(0x334EA8DE),
      Color(0x666366F1),
    ],
  );

  static const LinearGradient scriptureCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF18223C),
      Color(0xFF131B30),
    ],
  );

  // Box Shadows
  static List<BoxShadow> get goldOrbGlow => [
    BoxShadow(
      color: primaryGold.withValues(alpha: 0.35),
      blurRadius: 28,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: celestialCyan.withValues(alpha: 0.20),
      blurRadius: 40,
      spreadRadius: 8,
    ),
  ];

  static List<BoxShadow> get activePulseGlow => [
    BoxShadow(
      color: primaryGold.withValues(alpha: 0.5),
      blurRadius: 36,
      spreadRadius: 8,
    ),
    BoxShadow(
      color: amberAccent.withValues(alpha: 0.3),
      blurRadius: 60,
      spreadRadius: 14,
    ),
  ];

  // ThemeData
  static ThemeData get themeData {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgMidnight,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: celestialCyan,
        surface: surfaceElevated,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.cinzel(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.cinzel(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
        headlineSmall: GoogleFonts.cinzel(
          color: textGold,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      cardColor: surfaceCard,
    );
  }
}
