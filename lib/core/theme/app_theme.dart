import 'package:flutter/material.dart';

/// Theme principal de l'application EmClaud Budget
class AppTheme {
  // Couleurs principales
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color paleOrange = Color(0xFFFFBE7D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF2F2F2);
  static const Color darkGrey = Color(0xFF333333);
  static const Color darkOrange = Color(0xFFE67300);
  static const Color accentBlue = Color(0xFF3498db);
  static const Color accentGreen = Color(0xFF2ecc71);
  static const Color accentRed = Color(0xFFe74c3c);

  // Thème clair
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Utilisation du Material 3 pour une apparence plus moderne
      colorScheme: ColorScheme.light(
        primary: primaryOrange,
        secondary: accentBlue,
        tertiary: accentGreen,
        error: accentRed,
        surface: white,
        background: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: darkGrey,
        onBackground: darkGrey,
      ),
      scaffoldBackgroundColor: lightGrey.withOpacity(0.3),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardTheme(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Thème de texte moderne avec une police standard mais élégante
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.bold, color: darkGrey, letterSpacing: -0.5),
        titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, letterSpacing: -0.3),
        titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w500, color: darkGrey, letterSpacing: -0.2),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: darkGrey, letterSpacing: 0.1),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: darkGrey, letterSpacing: 0.15),
        labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: primaryOrange, letterSpacing: 0.5),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryOrange,
        unselectedLabelColor: darkGrey,
        indicatorColor: primaryOrange,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryOrange,
        unselectedItemColor: darkGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Thème sombre
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryOrange,
        secondary: paleOrange,
        surface: darkGrey,
        background: const Color(0xFF121212),
        onPrimary: white,
        onSecondary: white,
        onSurface: white,
        onBackground: white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: paleOrange,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: white),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: white),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: white),
        bodyLarge: TextStyle(fontSize: 16, color: white),
        bodyMedium: TextStyle(fontSize: 14, color: white),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryOrange,
        unselectedLabelColor: lightGrey,
        indicatorColor: primaryOrange,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryOrange,
        unselectedItemColor: lightGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
