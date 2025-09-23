import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  // Singleton instance
  static final AppLocalizations _instance = AppLocalizations._internal();
  factory AppLocalizations() => _instance;
  AppLocalizations._internal();

  // Initialize localization
  static Future<void> init() async {
    // Get saved language from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');

    // Default to English if no language is saved
    if (savedLanguage != null) {
      await EasyLocalization.ensureInitialized();
    }
  }

  // Get current locale
  static Locale? getCurrentLocale(BuildContext context) {
    return context.locale;
  }

  // Change language
  static Future<void> changeLanguage(BuildContext context,
   String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    await context.setLocale(Locale(languageCode));
  }
}