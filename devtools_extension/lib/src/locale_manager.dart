import 'package:flutter/material.dart';

/// Manages the locale for the DevTools extension
class LocaleManager extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Switch to English
  void setEnglish() {
    _locale = const Locale('en');
    notifyListeners();
  }

  /// Switch to Traditional Chinese
  void setChinese() {
    _locale = const Locale('zh');
    notifyListeners();
  }

  /// Toggle between English and Chinese
  void toggleLocale() {
    if (_locale.languageCode == 'en') {
      setChinese();
    } else {
      setEnglish();
    }
  }
}
