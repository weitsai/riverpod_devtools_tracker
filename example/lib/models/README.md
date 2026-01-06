# Adding New Languages

This guide explains how to add support for additional languages to the example app.

## Steps to Add a New Language

### 1. Add Language to the Language Model

Edit `lib/models/language.dart` and add your new language constant:

```dart
class SupportedLanguages {
  // Existing languages
  static const english = Language(...);
  static const traditionalChinese = Language(...);

  // Add your new language here
  static const japanese = Language(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
  );

  // Update the all list
  static const List<Language> all = [
    english,
    traditionalChinese,
    japanese,  // Add here
  ];
}
```

### 2. Create ARB Translation Files

Create translation files in `lib/l10n/`:

- `app_ja.arb` for base Japanese
- `app_ja_JP.arb` for Japan-specific variant (if needed)

Copy `app_en.arb` as a template and translate all strings.

### 3. Update l10n.yaml (if needed)

The `l10n.yaml` file should automatically detect new ARB files. No changes needed unless you want to customize settings.

### 4. Run Code Generation

```bash
flutter pub get
```

This will automatically generate the localization files.

### 5. Test

Run the app and verify:
- The new language appears in the language selector
- All strings are properly translated
- The app switches correctly to the new language

## Language Code References

Common language codes:
- `en` - English
- `zh` - Chinese
  - `zh_CN` - Simplified Chinese
  - `zh_TW` - Traditional Chinese
  - `zh_HK` - Hong Kong Chinese
- `ja` - Japanese
- `ko` - Korean
- `es` - Spanish
- `fr` - French
- `de` - German
- `it` - Italian
- `pt` - Portuguese
- `ru` - Russian
- `ar` - Arabic
- `hi` - Hindi
- `th` - Thai
- `vi` - Vietnamese

## Example: Adding Japanese Support

1. Edit `lib/models/language.dart`:
```dart
static const japanese = Language(
  code: 'ja',
  nativeName: '日本語',
  englishName: 'Japanese',
);

static const List<Language> all = [
  english,
  traditionalChinese,
  japanese,  // Add here
];
```

2. Create `lib/l10n/app_ja.arb` with all translations

3. Run `flutter pub get`

4. The Japanese option will now appear in the language selector!

## Architecture Benefits

This design makes it easy to:
- Add new languages without modifying UI code
- Maintain a centralized list of supported languages
- Display language names in both native and English
- Show a checkmark for the currently selected language
- Future: Add language-specific features or formatting
