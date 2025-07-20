import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Main Colors - Updated to match website
  static const Color primaryDarkBlue = Color(0xFF0A1929);  // Dark navy background
  static const Color secondaryDarkBlue = Color(0xFF162840); // Slightly lighter navy for cards
  static const Color accentTeal = Color(0xFF26D0CE); // Bright teal for accents/buttons
  static const Color lightTeal = Color(0xFF4FD1C5); // Lighter teal for secondary elements
  static const Color white = Colors.white;
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFC107);

  // Light theme (keeping this as a fallback)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: accentTeal,
      secondary: lightTeal,
      tertiary: const Color(0xFF3B82F6), // Blue accent as seen in some buttons
      surface: Colors.white,
      onSurface: Colors.black87,
      error: errorColor,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: white,
      foregroundColor: primaryDarkBlue,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentTeal),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      fillColor: Colors.grey.shade50,
      filled: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      backgroundColor: Colors.white,
      selectedItemColor: accentTeal,
      unselectedItemColor: Colors.grey.shade600,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: accentTeal,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  // Dark theme - Updated to match website screenshot exactly
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryDarkBlue,
    colorScheme: const ColorScheme.dark(
      primary: accentTeal,
      secondary: lightTeal,
      tertiary: Color(0xFF3B82F6), // Blue accent from website
      surface: secondaryDarkBlue,
      onSurface: Colors.white,
      error: errorColor,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      displayMedium: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bodyLarge: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      bodyMedium: GoogleFonts.poppins(
        textStyle: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: primaryDarkBlue,
      foregroundColor: white,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: secondaryDarkBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentTeal,
        side: const BorderSide(color: accentTeal),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentTeal),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      fillColor: secondaryDarkBlue,
      filled: true,
      labelStyle: TextStyle(color: Colors.grey.shade300),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      backgroundColor: primaryDarkBlue,
      selectedItemColor: accentTeal,
      unselectedItemColor: Colors.grey.shade400,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: accentTeal,
      textTheme: ButtonTextTheme.primary,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade800,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: accentTeal,
      size: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: secondaryDarkBlue,
      disabledColor: Colors.grey.shade800,
      selectedColor: accentTeal,
      secondarySelectedColor: accentTeal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.dark,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentTeal,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: accentTeal,
      unselectedLabelColor: Colors.grey.shade400,
      indicatorColor: accentTeal,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: secondaryDarkBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
// Minor change for contribution