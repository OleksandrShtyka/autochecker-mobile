import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService._();
  static final instance = LocaleService._();

  final ValueNotifier<String> langCode = ValueNotifier('en');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('lang') ?? 'en';
    langCode.value = stored;
  }

  Future<void> setLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
    langCode.value = code;
  }

  Locale get locale => Locale(langCode.value);
}
