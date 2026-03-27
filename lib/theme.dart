import 'package:flutter/material.dart';

const teal = Color(0xFF2EC8BE);
const blue = Color(0xFF2563EB);
const _bg = Color(0xFF060B14);
const _surface = Color(0xFF0C1525);
const _border = Color(0xFF1C2D45);
const _textPrimary = Color(0xFFE6EDF3);
const _textMuted = Color(0xFF8B949E);

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _bg,
  colorScheme: const ColorScheme.dark(
    primary: teal,
    secondary: blue,
    surface: _surface,
    onSurface: _textPrimary,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _textPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: _textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
    hintStyle: const TextStyle(color: _textMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: teal, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: teal),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
    selectedItemColor: teal,
    unselectedItemColor: _textMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  dividerColor: _border,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: _textPrimary),
    bodySmall: TextStyle(color: _textMuted),
    titleMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
  ),
);

BoxDecoration get cardDecoration => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.09),
      Colors.white.withValues(alpha: 0.03),
    ],
  ),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
);

const Color textMuted = _textMuted;
const Color textPrimary = _textPrimary;
const Color surfaceColor = _surface;
const Color borderColor = _border;
const Color bgColor = _bg;
