import 'package:flutter/material.dart';

class C {
  // Brand — light green
  static const primary = Color(0xFF4CAF50);
  static const primaryLight = Color(0xFF81C784);
  static const primaryDark = Color(0xFF2E7D32);
  static const accent = Color(0xFF66BB6A);

  // Status
  static const approved = Color(0xFF43A047);
  static const approvedBg = Color(0xFFE8F5E9);
  static const declined = Color(0xFFE53935);
  static const declinedBg = Color(0xFFFFEBEE);
  static const stips = Color(0xFFFFA726);
  static const stipsBg = Color(0xFFFFF3E0);
  static const pending = Color(0xFF9E9E9E);
  static const pendingBg = Color(0xFFF5F5F5);

  // Neutral — white & light grey
  static const bg = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1B1B1F);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFFADB5BD);
  static const border = Color(0xFFE8ECF0);
  static const divider = Color(0xFFF1F3F5);
  static const grey50 = Color(0xFFF8F9FA);
  static const grey100 = Color(0xFFF1F3F5);
  static const grey200 = Color(0xFFE9ECEF);

  // Dark
  static const darkBg = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkText = Color(0xFFF1F5F9);
  static const darkTextSec = Color(0xFF94A3B8);
  static const darkBorder = Color(0xFF2C2C2C);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: C.primary,
        scaffoldBackgroundColor: C.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: C.surface,
          foregroundColor: C.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: C.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: C.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: C.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: C.grey50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: C.textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: C.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: C.primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: C.surface,
          selectedItemColor: C.primary,
          unselectedItemColor: C.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        dividerColor: C.divider,
        tabBarTheme: const TabBarThemeData(
          labelColor: C.primary,
          unselectedLabelColor: C.textTertiary,
          indicatorColor: C.primary,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: C.primary,
        scaffoldBackgroundColor: C.darkBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: C.darkSurface,
          foregroundColor: C.darkText,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: C.darkText,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: C.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: C.darkBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: C.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.primaryLight, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: C.primaryLight,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: C.darkSurface,
          selectedItemColor: C.primaryLight,
          unselectedItemColor: C.darkTextSec,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        dividerColor: C.darkBorder,
      );
}
