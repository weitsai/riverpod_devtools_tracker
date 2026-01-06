import 'package:flutter/material.dart';

/// Represents a supported language in the app
class Language {
  final String code;
  final String? countryCode;
  final String nativeName;
  final String englishName;

  const Language({
    required this.code,
    this.countryCode,
    required this.nativeName,
    required this.englishName,
  });

  Locale get locale => Locale(code, countryCode ?? '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          countryCode == other.countryCode;

  @override
  int get hashCode => code.hashCode ^ countryCode.hashCode;
}

/// Supported languages in the app
class SupportedLanguages {
  static const english = Language(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
  );

  static const traditionalChinese = Language(
    code: 'zh',
    countryCode: 'TW',
    nativeName: '繁體中文',
    englishName: 'Traditional Chinese',
  );

  /// List of all supported languages
  /// Add new languages here to expand support
  static const List<Language> all = [
    english,
    traditionalChinese,
    // Add more languages here in the future:
    // simplifiedChinese,
    // japanese,
    // korean,
    // etc.
  ];

  /// Get language by locale
  static Language fromLocale(Locale locale) {
    return all.firstWhere(
      (lang) => lang.code == locale.languageCode &&
                lang.countryCode == locale.countryCode,
      orElse: () => english,
    );
  }

  /// Get language by code
  static Language? fromCode(String code, [String? countryCode]) {
    try {
      return all.firstWhere(
        (lang) => lang.code == code && lang.countryCode == countryCode,
      );
    } catch (e) {
      return null;
    }
  }
}
