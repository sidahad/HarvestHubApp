import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app languages
enum AppLanguage { english, urdu }

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _prefKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  Locale get currentLocale {
    switch (_currentLanguage) {
      case AppLanguage.urdu:
        return const Locale('ur', 'PK');
      case AppLanguage.english:
        return const Locale('en', 'US');
    }
  }

  /// Human-readable name for the current language
  String get currentLanguageName {
    switch (_currentLanguage) {
      case AppLanguage.urdu:
        return 'اردو';
      case AppLanguage.english:
        return 'English';
    }
  }

  /// Is the current language RTL?
  bool get isRTL => _currentLanguage == AppLanguage.urdu;

  /// Load saved language preference from SharedPreferences
  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        _currentLanguage = _fromString(saved);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LanguageService: failed to load saved language: $e');
    }
  }

  /// Change language and persist to SharedPreferences
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _toString(language));
    } catch (e) {
      debugPrint('LanguageService: failed to save language: $e');
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  static String _toString(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.urdu:
        return 'ur';
      case AppLanguage.english:
        return 'en';
    }
  }

  static AppLanguage _fromString(String code) {
    switch (code) {
      case 'ur':
        return AppLanguage.urdu;
      default:
        return AppLanguage.english;
    }
  }

  /// All languages with display metadata — used in the picker UI
  static List<LanguageOption> get allLanguages => [
    LanguageOption(
      language: AppLanguage.english,
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      locale: const Locale('en', 'US'),
    ),
    LanguageOption(
      language: AppLanguage.urdu,
      name: 'Urdu',
      nativeName: 'اردو',
      flag: '🇵🇰',
      locale: const Locale('ur', 'PK'),
    ),
  ];
}

/// Data class for a single language option shown in the picker
class LanguageOption {
  final AppLanguage language;
  final String name;
  final String nativeName;
  final String flag;
  final Locale locale;

  const LanguageOption({
    required this.language,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.locale,
  });
}
