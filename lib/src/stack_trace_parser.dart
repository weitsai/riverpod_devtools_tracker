import 'tracker_config.dart';

/// Represents a code location in a stack trace.
///
/// Contains information about where in the code a particular
/// event occurred, including file path, line number, and function name.
///
/// This is used to display the exact location where a provider
/// state change was triggered.
///
/// Example:
/// ```dart
/// const location = LocationInfo(
///   location: 'lib/main.dart:42',
///   file: 'lib/main.dart',
///   line: 42,
///   function: 'main',
/// );
/// ```
class LocationInfo {
  /// Full location description (file:line in function)
  final String location;

  /// File path
  final String file;

  /// Line number
  final int line;

  /// Function name
  final String function;

  /// Column (if available)
  final int? column;

  const LocationInfo({
    required this.location,
    required this.file,
    required this.line,
    required this.function,
    this.column,
  });

  /// Converts this location to a JSON-serializable map
  ///
  /// The map includes all location information that can be sent
  /// to the DevTools extension or logged to console.
  Map<String, dynamic> toJson() => {
    'location': location,
    'file': file,
    'line': line,
    'function': function,
    if (column != null) 'column': column,
  };

  /// Returns the string representation of this location
  ///
  /// This returns the [location] field which contains the formatted
  /// location string (e.g., "lib/main.dart:42").
  @override
  String toString() => location;
}

/// Parses Dart stack traces to extract code location information.
///
/// This parser analyzes stack traces to identify where provider
/// state changes originated in your code, filtering out framework
/// code to show only relevant application code.
///
/// The parser uses [TrackerConfig] to determine which code locations
/// should be included or filtered out based on package prefixes and
/// file patterns.
///
/// Example:
/// ```dart
/// final parser = StackTraceParser(
///   TrackerConfig.forPackage('my_app'),
/// );
///
/// final stackTrace = StackTrace.current;
/// final callChain = parser.parseCallChain(stackTrace);
/// final triggerLocation = parser.findTriggerLocation(stackTrace);
/// ```
class StackTraceParser {
  final TrackerConfig config;

  /// Regex for parsing stack trace lines
  /// Matches format: #0 FunctionName (package:path/file.dart:123:45)
  static final _stackLineRegex = RegExp(
    r'#(\d+)\s+(.+?)\s+\((.+?):(\d+)(?::(\d+))?\)',
  );

  StackTraceParser(this.config);

  /// Parses a complete call chain from a stack trace
  ///
  /// Extracts a list of [LocationInfo] representing the call stack,
  /// filtered according to the [TrackerConfig] settings. Only includes
  /// locations from your application code, excluding framework code.
  ///
  /// The list is ordered from most recent call to oldest, and is limited
  /// to [TrackerConfig.maxCallChainDepth] entries.
  ///
  /// Example:
  /// ```dart
  /// final parser = StackTraceParser(config);
  /// final callChain = parser.parseCallChain(StackTrace.current);
  /// for (final location in callChain) {
  ///   print('${location.function} at ${location.file}:${location.line}');
  /// }
  /// ```
  List<LocationInfo> parseCallChain(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final chain = <LocationInfo>[];

    for (final line in lines) {
      if (chain.length >= config.maxCallChainDepth) break;

      final match = _stackLineRegex.firstMatch(line);
      if (match == null) continue;

      final function = match.group(2)?.trim() ?? '';
      final file = match.group(3) ?? '';
      final lineNum = int.tryParse(match.group(4) ?? '') ?? 0;
      final column = int.tryParse(match.group(5) ?? '');

      // Check if should be ignored
      if (_shouldIgnore(file)) continue;

      // Shorten file path
      final shortFile = _shortenFilePath(file);

      chain.add(
        LocationInfo(
          location: '$shortFile:$lineNum',
          file: shortFile,
          line: lineNum,
          function: function,
          column: column,
        ),
      );
    }

    return chain;
  }

  /// Finds the most relevant user code location that triggered a state change
  ///
  /// Analyzes the stack trace to identify the first location in your
  /// application code that triggered the provider change. This filters
  /// out provider definition files and framework code to find the actual
  /// user code that caused the state change.
  ///
  /// Returns `null` if no suitable location is found.
  ///
  /// Example:
  /// ```dart
  /// final parser = StackTraceParser(config);
  /// final trigger = parser.findTriggerLocation(StackTrace.current);
  /// if (trigger != null) {
  ///   print('Change triggered at: ${trigger.location}');
  /// }
  /// ```
  LocationInfo? findTriggerLocation(StackTrace stackTrace) {
    final callChain = parseCallChain(stackTrace);

    if (callChain.isEmpty) return null;

    // Strategy: find the first location that's not a provider file
    // Since provider files are usually intermediate layers
    for (final loc in callChain) {
      if (!_isProviderFile(loc.file)) {
        return loc;
      }
    }

    // If all are provider files, return the first one
    return callChain.first;
  }

  /// Check if this file should be ignored
  bool _shouldIgnore(String file) {
    // Check ignored package prefixes
    for (final prefix in config.ignoredPackagePrefixes) {
      if (file.startsWith(prefix)) return true;
    }

    // Check ignored file patterns
    for (final pattern in config.ignoredFilePatterns) {
      if (file.contains(pattern)) return true;
    }

    // If package prefixes are set, only keep code from those packages
    if (config.packagePrefixes.isNotEmpty) {
      bool matchesAny = false;
      for (final prefix in config.packagePrefixes) {
        if (file.startsWith(prefix)) {
          matchesAny = true;
          break;
        }
      }
      if (!matchesAny) return true;
    }

    return false;
  }

  /// Shorten file path
  String _shortenFilePath(String file) {
    for (final prefix in config.packagePrefixes) {
      if (file.startsWith(prefix)) {
        return file.substring(prefix.length);
      }
    }
    // Remove package: prefix for readability
    if (file.startsWith('package:')) {
      final parts = file.split('/');
      if (parts.length > 1) {
        return parts.sublist(1).join('/');
      }
    }
    return file;
  }

  /// Check if it's a provider file
  bool _isProviderFile(String file) {
    return file.contains('_provider.dart') ||
        file.contains('/providers/') ||
        file.endsWith('.g.dart');
  }
}
