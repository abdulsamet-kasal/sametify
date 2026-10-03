import 'package:flutter/material.dart';

class AppTheme {
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color backgroundBlack = Color(0xFF121212);
  static const Color surfaceBlack = Color(0xFF181818);
  static const Color cardBlack = Color(0xFF282828);
  static const Color textGrey = Color(0xFFB3B3B3);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundBlack,
    primaryColor: spotifyGreen,
    colorScheme: const ColorScheme.dark(
      primary: spotifyGreen,
      surface: surfaceBlack,
      onSurface: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: cardBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundBlack,
      selectedItemColor: Colors.white,
      unselectedItemColor: textGrey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundBlack,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
