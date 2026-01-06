// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Riverpod State Inspector';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get filterProviders => 'Filter Providers...';

  @override
  String get allHistory => 'All History';

  @override
  String get latestOnly => 'Latest Only';

  @override
  String get filterChangeTypes => 'Filter Change Types';

  @override
  String get changeTypeAdd => 'Add';

  @override
  String get changeTypeUpdate => 'Update';

  @override
  String get changeTypeDispose => 'Dispose';

  @override
  String get changeTypeError => 'Error';

  @override
  String changesCount(int count) {
    return '$count changes';
  }

  @override
  String get connectingToApp => 'Connecting to application...';

  @override
  String get makeSureAppRunning =>
      'Make sure your app is running with RiverpodDevToolsObserver';

  @override
  String get noStateChangesYet => 'No state changes yet';

  @override
  String get providerStateChangesWillAppearHere =>
      'Provider state changes will appear here';

  @override
  String get selectProviderToViewDetails => 'Select a provider to view details';

  @override
  String get changeSource => 'Change Source';

  @override
  String get callChain => 'Call Chain';

  @override
  String get stackTrace => 'Stack Trace';

  @override
  String get stateChange => 'State Change';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get copyLocation => 'Copy location';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get selectProviders => 'Select Providers';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String get showAutoComputed => 'Show auto-computed';

  @override
  String get hideAutoComputed => 'Hide auto-computed';

  @override
  String get derivedProviderUpdates => 'Derived provider updates';

  @override
  String get autoComputed => 'auto-computed';

  @override
  String get clickToExpandFullContent => 'Click to expand full content...';
}
