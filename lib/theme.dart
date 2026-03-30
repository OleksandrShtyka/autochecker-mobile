import 'package:flutter/material.dart';

const teal = Color(0xFF2EC8BE);
const blue = Color(0xFF2563EB);

// ── Dark palette ──────────────────────────────────────────────────────────────
const _dBg      = Color(0xFF060B14);
const _dSurface = Color(0xFF0C1525);
const _dBorder  = Color(0xFF1C2D45);
const _dText    = Color(0xFFE6EDF3);
const _dMuted   = Color(0xFF8B949E);

// ── Light palette (iOS) ───────────────────────────────────────────────────────
const _lBg      = Color(0xFFF2F2F7);
const _lSurface = Color(0xFFFFFFFF);
const _lBorder  = Color(0xFFE5E5EA);
const _lText    = Color(0xFF1C1C1E);
const _lMuted   = Color(0xFF8E8E93);

// ── Backwards-compat exports (dark) ──────────────────────────────────────────
const Color textPrimary  = _dText;
const Color textMuted    = _dMuted;
const Color surfaceColor = _dSurface;
const Color borderColor  = _dBorder;
const Color bgColor      = _dBg;

// ── AppColors — theme-aware helper ───────────────────────────────────────────
class AppColors {
  final Color bg;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final bool isDark;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.isDark,
  });

  static AppColors of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? _darkColors : _lightColors;
  }

  Color get cardFill => isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.white.withValues(alpha: 0.85);

  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.06);

  Color get inputFill => isDark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.black.withValues(alpha: 0.04);

  Color get divider => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.08);

  static const _darkColors = AppColors(
    bg: _dBg, surface: _dSurface, border: _dBorder,
    text: _dText, muted: _dMuted, isDark: true,
  );
  static const _lightColors = AppColors(
    bg: _lBg, surface: _lSurface, border: _lBorder,
    text: _lText, muted: _lMuted, isDark: false,
  );
}

// ── Dark Theme ────────────────────────────────────────────────────────────────
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _dBg,
  colorScheme: const ColorScheme.dark(
    primary: teal,
    secondary: blue,
    surface: _dSurface,
    onSurface: _dText,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _dText,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: _dText, fontSize: 18,
      fontWeight: FontWeight.w700, letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.transparent, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    labelStyle: const TextStyle(color: _dMuted, fontSize: 13),
    hintStyle: const TextStyle(color: _dMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: teal, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: teal, foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: teal),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? teal : _dMuted),
    trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? teal.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.1)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
    selectedItemColor: teal,
    unselectedItemColor: _dMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  dividerColor: _dBorder,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: _dText),
    bodySmall: TextStyle(color: _dMuted),
    titleMedium: TextStyle(color: _dText, fontWeight: FontWeight.w600),
  ),
);

// ── Light Theme (iOS) ─────────────────────────────────────────────────────────
final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: _lBg,
  colorScheme: const ColorScheme.light(
    primary: teal,
    secondary: blue,
    surface: _lSurface,
    onSurface: _lText,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _lText,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: _lText, fontSize: 18,
      fontWeight: FontWeight.w700, letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardThemeData(
    color: _lSurface, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: EdgeInsets.zero,
    shadowColor: Colors.black.withValues(alpha: 0.06),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.04),
    labelStyle: const TextStyle(color: _lMuted, fontSize: 13),
    hintStyle: const TextStyle(color: _lMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: teal, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: teal, foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: teal),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? teal : _lMuted),
    trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? teal.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.1)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
    selectedItemColor: teal,
    unselectedItemColor: _lMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  dividerColor: _lBorder,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: _lText),
    bodySmall: TextStyle(color: _lMuted),
    titleMedium: TextStyle(color: _lText, fontWeight: FontWeight.w600),
  ),
);

// ── Legacy compat ─────────────────────────────────────────────────────────────
final appTheme = darkTheme;

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
