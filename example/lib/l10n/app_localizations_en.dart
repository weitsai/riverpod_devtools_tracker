// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Riverpod DevTools Tracker Demo';

  @override
  String get homeTitle => 'Riverpod DevTools Tracker Example';

  @override
  String get usageInstructions => '🔍 Usage Instructions';

  @override
  String get instruction1 =>
      '1. Click the example cards below to enter each demo page';

  @override
  String get instruction2 =>
      '2. Interact with UI components to trigger state changes';

  @override
  String get instruction3 =>
      '3. Open DevTools extension to view detailed state change tracking';

  @override
  String get instruction4 =>
      '4. You can see the exact code location and call stack that triggered the change';

  @override
  String get counterExampleTitle => 'Counter Example';

  @override
  String get counterExampleDesc =>
      'Demonstrates basic state change tracking\nIncludes counter and its derived states';

  @override
  String get userExampleTitle => 'User Data Example';

  @override
  String get userExampleDesc =>
      'Demonstrates complex object state changes\nTracks login status and profile updates';

  @override
  String get asyncExampleTitle => 'Async Data Example';

  @override
  String get asyncExampleDesc =>
      'Demonstrates AsyncValue state tracking\nIncludes loading, success, and error states';

  @override
  String get todoExampleTitle => 'Todo List Example';

  @override
  String get todoExampleDesc =>
      'Demonstrates list CRUD operation tracking\nComplete CRUD operations demonstration';

  @override
  String get counterScreenTitle => 'Counter Example';

  @override
  String get currentCount => 'Current Count:';

  @override
  String get doubleValue => 'Double Value';

  @override
  String get isEven => 'Is Even';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get reset => 'Reset';

  @override
  String get userScreenTitle => 'User Data Example';

  @override
  String get loggedIn => 'Logged In';

  @override
  String get notLoggedIn => 'Not Logged In';

  @override
  String get name => 'Name';

  @override
  String get age => 'Age';

  @override
  String get email => 'Email';

  @override
  String get login => 'Login';

  @override
  String get changeName => 'Change Name';

  @override
  String get increaseAge => 'Increase Age';

  @override
  String get logout => 'Logout';

  @override
  String get changeNameDialogTitle => 'Change Name';

  @override
  String get newName => 'New Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get asyncScreenTitle => 'Async Data Example';

  @override
  String get futureProviderExample => 'FutureProvider Example';

  @override
  String get loadingSuccess => 'Loading Success';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingFailed => 'Loading Failed';

  @override
  String get reloadInvalidate => 'Reload (invalidate)';

  @override
  String get stateNotifierAsyncExample => 'StateNotifier + AsyncValue Example';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get todoScreenTitle => 'Todo List Example';

  @override
  String get noTodosMessage => 'No todos yet\nClick the button below to add';

  @override
  String get clearCompleted => 'Clear Completed';

  @override
  String get addTodo => 'Add Todo';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get addTodoDialogTitle => 'Add Todo';

  @override
  String get todoContent => 'Todo Content';

  @override
  String get add => 'Add';

  @override
  String get defaultUserName => 'John Doe';
}
