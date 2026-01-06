import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Riverpod DevTools Tracker Demo'**
  String get appTitle;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Riverpod DevTools Tracker Example'**
  String get homeTitle;

  /// Usage instructions header
  ///
  /// In en, this message translates to:
  /// **'🔍 Usage Instructions'**
  String get usageInstructions;

  /// First instruction
  ///
  /// In en, this message translates to:
  /// **'1. Click the example cards below to enter each demo page'**
  String get instruction1;

  /// Second instruction
  ///
  /// In en, this message translates to:
  /// **'2. Interact with UI components to trigger state changes'**
  String get instruction2;

  /// Third instruction
  ///
  /// In en, this message translates to:
  /// **'3. Open DevTools extension to view detailed state change tracking'**
  String get instruction3;

  /// Fourth instruction
  ///
  /// In en, this message translates to:
  /// **'4. You can see the exact code location and call stack that triggered the change'**
  String get instruction4;

  /// Counter example card title
  ///
  /// In en, this message translates to:
  /// **'Counter Example'**
  String get counterExampleTitle;

  /// Counter example card description
  ///
  /// In en, this message translates to:
  /// **'Demonstrates basic state change tracking\nIncludes counter and its derived states'**
  String get counterExampleDesc;

  /// User example card title
  ///
  /// In en, this message translates to:
  /// **'User Data Example'**
  String get userExampleTitle;

  /// User example card description
  ///
  /// In en, this message translates to:
  /// **'Demonstrates complex object state changes\nTracks login status and profile updates'**
  String get userExampleDesc;

  /// Async example card title
  ///
  /// In en, this message translates to:
  /// **'Async Data Example'**
  String get asyncExampleTitle;

  /// Async example card description
  ///
  /// In en, this message translates to:
  /// **'Demonstrates AsyncValue state tracking\nIncludes loading, success, and error states'**
  String get asyncExampleDesc;

  /// Todo example card title
  ///
  /// In en, this message translates to:
  /// **'Todo List Example'**
  String get todoExampleTitle;

  /// Todo example card description
  ///
  /// In en, this message translates to:
  /// **'Demonstrates list CRUD operation tracking\nComplete CRUD operations demonstration'**
  String get todoExampleDesc;

  /// Counter screen title
  ///
  /// In en, this message translates to:
  /// **'Counter Example'**
  String get counterScreenTitle;

  /// Current count label
  ///
  /// In en, this message translates to:
  /// **'Current Count:'**
  String get currentCount;

  /// Double value label
  ///
  /// In en, this message translates to:
  /// **'Double Value'**
  String get doubleValue;

  /// Is even label
  ///
  /// In en, this message translates to:
  /// **'Is Even'**
  String get isEven;

  /// Yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Decrease button tooltip
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// Increase button tooltip
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// Reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// User screen title
  ///
  /// In en, this message translates to:
  /// **'User Data Example'**
  String get userScreenTitle;

  /// Logged in status
  ///
  /// In en, this message translates to:
  /// **'Logged In'**
  String get loggedIn;

  /// Not logged in status
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedIn;

  /// Name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Age label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Change name button
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changeName;

  /// Increase age button
  ///
  /// In en, this message translates to:
  /// **'Increase Age'**
  String get increaseAge;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Change name dialog title
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changeNameDialogTitle;

  /// New name input label
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newName;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Async screen title
  ///
  /// In en, this message translates to:
  /// **'Async Data Example'**
  String get asyncScreenTitle;

  /// FutureProvider section title
  ///
  /// In en, this message translates to:
  /// **'FutureProvider Example'**
  String get futureProviderExample;

  /// Loading success status
  ///
  /// In en, this message translates to:
  /// **'Loading Success'**
  String get loadingSuccess;

  /// Loading status
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Loading failed status
  ///
  /// In en, this message translates to:
  /// **'Loading Failed'**
  String get loadingFailed;

  /// Reload button for FutureProvider
  ///
  /// In en, this message translates to:
  /// **'Reload (invalidate)'**
  String get reloadInvalidate;

  /// StateNotifier section title
  ///
  /// In en, this message translates to:
  /// **'StateNotifier + AsyncValue Example'**
  String get stateNotifierAsyncExample;

  /// Refresh data button
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// Todo screen title
  ///
  /// In en, this message translates to:
  /// **'Todo List Example'**
  String get todoScreenTitle;

  /// Empty todos message
  ///
  /// In en, this message translates to:
  /// **'No todos yet\nClick the button below to add'**
  String get noTodosMessage;

  /// Clear completed button
  ///
  /// In en, this message translates to:
  /// **'Clear Completed'**
  String get clearCompleted;

  /// Add todo button tooltip
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get addTodo;

  /// Pending todos label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Completed todos label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Add todo dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get addTodoDialogTitle;

  /// Todo content input label
  ///
  /// In en, this message translates to:
  /// **'Todo Content'**
  String get todoContent;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Default user name for demo
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get defaultUserName;

  /// Language selector tooltip
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSelector;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Traditional Chinese language name
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get languageTraditionalChinese;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
