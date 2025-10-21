import 'package:flutter/material.dart';

final lightColorScheme = ColorScheme.light(
  primary: Color(0xFF1565C0), // Deep royal blue - trust & finance
  onPrimary: Colors.white,
  secondary: Color(0xFFFFA000), // Warm amber - highlights and actions
  onSecondary: Colors.black,
  tertiary: Color(0xFF2E7D32), // Success green - income/positive
  onTertiary: Colors.white,
  error: Color(0xFFD32F2F), // Strong red - errors/expenses
  onError: Colors.white,
  background: Color(0xFFF9FAFB), // Soft gray-white background
  onBackground: Color(0xFF1A1A1A),
  surface: Color(0xFFFFFFFF), // Card/dialog background
  onSurface: Color(0xFF1F1F1F),
  surfaceVariant: Color(0xFFE8EDF2), // Soft blue-gray for secondary surfaces
  outline: Color(0xFFB0BEC5), // Borders and dividers
  inverseSurface: Color(0xFF2C2C2C),
  inversePrimary: Color(0xFF90CAF9),
  shadow: Colors.black12,
);

final darkColorScheme = ColorScheme.dark(
  primary: Color(0xFF90CAF9), // Soft light blue for brand in dark mode
  onPrimary: Color(0xFF0D47A1),
  secondary: Color(0xFFFFC107), // Warm accent
  onSecondary: Colors.black,
  tertiary: Color(0xFF81C784), // Calm green for positive values
  onTertiary: Colors.black,
  error: Color(0xFFEF5350), // Bright red for visibility on dark
  onError: Colors.black,
  background: Color(0xFF121212), // Deep dark background
  onBackground: Color(0xFFECECEC),
  surface: Color(0xFF1E1E1E), // Cards, dialogs
  onSurface: Color(0xFFEAEAEA),
  surfaceVariant: Color(0xFF2C2C2C), // Secondary surfaces
  outline: Color(0xFF5A5A5A), // Subtle dividers
  inverseSurface: Color(0xFFF5F5F5),
  inversePrimary: Color(0xFF1565C0),
  shadow: Colors.black54,
);

ThemeData lightTheme = ThemeData(
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
  useMaterial3: true,
);

ThemeData darkTheme = ThemeData(
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  useMaterial3: true,
);
