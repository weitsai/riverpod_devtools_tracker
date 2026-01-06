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
  ];

  /// The title of the DevTools extension
  ///
  /// In en, this message translates to:
  /// **'Riverpod State Inspector'**
  String get appTitle;

  /// Connection status - connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Connection status - disconnected
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Button to clear state change history
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// Placeholder text for filter input
  ///
  /// In en, this message translates to:
  /// **'Filter Providers...'**
  String get filterProviders;

  /// Filter chip label for showing all history
  ///
  /// In en, this message translates to:
  /// **'All History'**
  String get allHistory;

  /// Filter chip label for showing latest changes only
  ///
  /// In en, this message translates to:
  /// **'Latest Only'**
  String get latestOnly;

  /// Header for change type filter menu
  ///
  /// In en, this message translates to:
  /// **'Filter Change Types'**
  String get filterChangeTypes;

  /// Change type - add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get changeTypeAdd;

  /// Change type - update
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get changeTypeUpdate;

  /// Change type - dispose
  ///
  /// In en, this message translates to:
  /// **'Dispose'**
  String get changeTypeDispose;

  /// Change type - error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get changeTypeError;

  /// Number of state changes
  ///
  /// In en, this message translates to:
  /// **'{count} changes'**
  String changesCount(int count);

  /// Loading message when connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting to application...'**
  String get connectingToApp;

  /// Instruction message for connection
  ///
  /// In en, this message translates to:
  /// **'Make sure your app is running with RiverpodDevToolsObserver'**
  String get makeSureAppRunning;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No state changes yet'**
  String get noStateChangesYet;

  /// Empty state description
  ///
  /// In en, this message translates to:
  /// **'Provider state changes will appear here'**
  String get providerStateChangesWillAppearHere;

  /// Message when no provider is selected
  ///
  /// In en, this message translates to:
  /// **'Select a provider to view details'**
  String get selectProviderToViewDetails;

  /// Section title for change source location
  ///
  /// In en, this message translates to:
  /// **'Change Source'**
  String get changeSource;

  /// Section title for call chain
  ///
  /// In en, this message translates to:
  /// **'Call Chain'**
  String get callChain;

  /// Section title for stack trace
  ///
  /// In en, this message translates to:
  /// **'Stack Trace'**
  String get stackTrace;

  /// Section title for state change comparison
  ///
  /// In en, this message translates to:
  /// **'State Change'**
  String get stateChange;

  /// Label for previous state value
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// Label for current state value
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// Button to expand collapsed content
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// Button to collapse expanded content
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Tooltip for copy location button
  ///
  /// In en, this message translates to:
  /// **'Copy location'**
  String get copyLocation;

  /// Number of items in a list
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// Header for provider selection menu
  ///
  /// In en, this message translates to:
  /// **'Select Providers'**
  String get selectProviders;

  /// Button to clear all selections
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Tooltip for clearing all filters
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// Toggle label to show auto-computed updates
  ///
  /// In en, this message translates to:
  /// **'Show auto-computed'**
  String get showAutoComputed;

  /// Toggle label to hide auto-computed updates
  ///
  /// In en, this message translates to:
  /// **'Hide auto-computed'**
  String get hideAutoComputed;

  /// Description for auto-computed toggle
  ///
  /// In en, this message translates to:
  /// **'Derived provider updates'**
  String get derivedProviderUpdates;

  /// Label for auto-computed provider updates
  ///
  /// In en, this message translates to:
  /// **'auto-computed'**
  String get autoComputed;

  /// Hint text to expand collapsed value
  ///
  /// In en, this message translates to:
  /// **'Click to expand full content...'**
  String get clickToExpandFullContent;
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
