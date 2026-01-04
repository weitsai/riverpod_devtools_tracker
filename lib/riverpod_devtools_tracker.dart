/// Riverpod DevTools Tracker
///
/// A powerful tracking tool for Riverpod state changes with automatic
/// code location detection.
///
/// ## Usage
///
/// ```dart
/// import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';
///
/// void main() {
///   runApp(
///     ProviderScope(
///       observers: [
///         RiverpodDevToolsObserver(
///           config: TrackerConfig.forPackage('your_app'),
///         ),
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
library riverpod_devtools_tracker;

export 'src/riverpod_devtools_observer.dart';
export 'src/tracker_config.dart';
export 'src/stack_trace_parser.dart' show LocationInfo;
