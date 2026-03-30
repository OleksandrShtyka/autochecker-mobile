import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final instance = ThemeService._();
  ThemeService._();

  final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('theme_dark') ?? true;
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final next = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    mode.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', next == ThemeMode.dark);
  }

  bool get isDark => mode.value == ThemeMode.dark;
}
