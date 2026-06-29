import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide locale, persisted across launches. Urdu ('ur') is right-to-left;
/// MaterialApp applies RTL automatically from the active locale.
class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _key = 'careattend-lang';
  static const supported = <Locale>[
    Locale('en'),
    Locale('cy'),
    Locale('ur'),
    Locale('pl'),
  ];
  static const names = <String, String>{
    'en': 'English',
    'cy': 'Cymraeg',
    'ur': 'اردو',
    'pl': 'Polski',
  };

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && names.containsKey(code)) {
        locale.value = Locale(code);
      }
    } catch (_) {
      // Locale persistence is best-effort. The app must still boot if browser
      // storage or a platform plugin is unavailable.
    }
  }

  Future<void> set(String code) async {
    if (!names.containsKey(code)) return;
    locale.value = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {
      // Keep the in-memory language change even when persistence is unavailable.
    }
  }
}
