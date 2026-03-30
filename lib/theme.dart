import 'package:flutter/material.dart';

// ── Accent colors ─────────────────────────────────────────────────────────────
const teal = Color(0xFF00E5CC);
const blue = Color(0xFF4361EE);
const accentPurple = Color(0xFF7B2FBE);

const accentGradient = LinearGradient(
  colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ── Dark palette ──────────────────────────────────────────────────────────────
const _dBg      = Color(0xFF08080F);
const _dSurface = Color(0xFF13131F);
const _dBorder  = Color(0xFF1F1F32);
const _dText    = Color(0xFFF0F0FF);
const _dMuted   = Color(0xFF6B6B8A);

// ── Light palette ─────────────────────────────────────────────────────────────
const _lBg      = Color(0xFFF7F7FF);
const _lSurface = Color(0xFFFFFFFF);
const _lBorder  = Color(0xFFE4E4F0);
const _lText    = Color(0xFF0D0D1A);
const _lMuted   = Color(0xFF8888AA);

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
      : Colors.white.withValues(alpha: 0.90);

  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.06);

  Color get inputFill => isDark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.black.withValues(alpha: 0.04);

  Color get divider => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.08);

  BoxDecoration get cardDecoration => BoxDecoration(
    color: cardFill,
    gradient: isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.03),
            ],
          )
        : null,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: cardBorder, width: 1),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: teal.withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: -8,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
  );

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
      fontWeight: FontWeight.w800, letterSpacing: -1.0,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.transparent, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    labelStyle: const TextStyle(color: _dMuted, fontSize: 13),
    hintStyle: const TextStyle(color: _dMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: teal, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

// ── Light Theme ───────────────────────────────────────────────────────────────
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
      fontWeight: FontWeight.w800, letterSpacing: -1.0,
    ),
  ),
  cardTheme: CardThemeData(
    color: _lSurface, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    margin: EdgeInsets.zero,
    shadowColor: Colors.black.withValues(alpha: 0.06),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.04),
    labelStyle: const TextStyle(color: _lMuted, fontSize: 13),
    hintStyle: const TextStyle(color: _lMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: teal, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      Colors.white.withValues(alpha: 0.10),
      Colors.white.withValues(alpha: 0.03),
    ],
  ),
  borderRadius: BorderRadius.circular(28),
  border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
);
