import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/language.dart';

part 'locale_provider.g.dart';

/// Locale provider - manages app language selection
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    // Default to English
    return SupportedLanguages.english.locale;
  }

  /// Set locale using Language object
  void setLanguage(Language language) {
    state = language.locale;
  }

  /// Set locale directly
  void setLocale(Locale locale) {
    state = locale;
  }

  /// Get current language
  Language get currentLanguage => SupportedLanguages.fromLocale(state);
}

/// Provider for the list of supported languages
@riverpod
List<Language> supportedLanguages(Ref ref) {
  return SupportedLanguages.all;
}
