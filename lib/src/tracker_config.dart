/// Configuration for Riverpod DevTools Tracker
///
/// This class controls how the tracker behaves and what information it collects.
/// Use [TrackerConfig.forPackage] for a quick setup with sensible defaults.
///
/// Example:
/// ```dart
/// // Simple setup - just provide your package name
/// RiverpodDevToolsObserver(
///   config: TrackerConfig.forPackage('my_app'),
/// )
///
/// // Advanced setup with custom configuration
/// RiverpodDevToolsObserver(
///   config: TrackerConfig(
///     packagePrefixes: ['package:my_app/'],
///     enableConsoleOutput: false, // Disable for production
///     maxCallChainDepth: 15,
///   ),
/// )
/// ```
class TrackerConfig {
  /// Whether tracking is enabled
  ///
  /// Set to false to completely disable the tracker. Useful for conditional
  /// enabling in different environments (e.g., only in debug mode).
  final bool enabled;

  /// Package prefixes for your app, used to filter stack traces
  ///
  /// Only stack traces from code in these packages will be shown.
  /// This helps filter out framework code and focus on your application code.
  ///
  /// Example: `['package:my_app/', 'package:my_common/']`
  final List<String> packagePrefixes;

  /// Whether to output tracking info to console
  ///
  /// When enabled, provider changes will be logged to the console.
  /// Set to false in production for better performance.
  final bool enableConsoleOutput;

  /// Whether to use pretty formatted console output (with box characters)
  ///
  /// When true, uses formatted output with emojis and boxes.
  /// When false, uses simple one-line format.
  final bool prettyConsoleOutput;

  /// Maximum call chain depth to capture
  ///
  /// Limits how many stack frames are captured and displayed.
  /// Lower values improve performance but may miss deep call chains.
  /// Recommended: 10-15 for most apps.
  final int maxCallChainDepth;

  /// Maximum value display length in console output
  ///
  /// Values longer than this will be truncated in console output.
  /// Note: Full values are always sent to DevTools extension.
  final int maxValueLength;

  /// Package prefixes to ignore in stack traces
  ///
  /// Stack frames from these packages will be filtered out.
  /// By default, includes Flutter and Riverpod framework packages.
  final List<String> ignoredPackagePrefixes;

  /// File patterns to ignore (partial match)
  ///
  /// Files matching these patterns will be filtered from stack traces.
  /// Useful for ignoring generated files like `.g.dart`.
  final List<String> ignoredFilePatterns;

  /// Whether to skip provider updates where the value hasn't changed
  ///
  /// When enabled, updates where previousValue and newValue are deeply equal
  /// (same JSON serialization) will be filtered out. This reduces noise in
  /// DevTools when providers update but the actual value remains the same.
  ///
  /// Comparison uses JSON serialization for deep equality check.
  /// Default: true (filtering enabled)
  final bool skipUnchangedValues;

  const TrackerConfig({
    this.enabled = true,
    this.packagePrefixes = const [],
    this.enableConsoleOutput = true,
    this.prettyConsoleOutput = true,
    this.maxCallChainDepth = 10,
    this.maxValueLength = 200,
    this.skipUnchangedValues = true,
    this.ignoredPackagePrefixes = const [
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:riverpod/',
      'package:riverpod_annotation/',
      'package:riverpod_devtools_tracker/',
      'dart:',
    ],
    this.ignoredFilePatterns = const [],
  });

  /// Create a config for a specific package
  factory TrackerConfig.forPackage(
    String packageName, {
    bool enabled = true,
    bool enableConsoleOutput = true,
    bool prettyConsoleOutput = true,
    int maxCallChainDepth = 10,
    int maxValueLength = 200,
    bool skipUnchangedValues = true,
    List<String> additionalPackages = const [],
    List<String> additionalIgnored = const [],
    List<String> ignoredFilePatterns = const [],
  }) {
    return TrackerConfig(
      enabled: enabled,
      packagePrefixes: ['package:$packageName/', ...additionalPackages],
      enableConsoleOutput: enableConsoleOutput,
      prettyConsoleOutput: prettyConsoleOutput,
      maxCallChainDepth: maxCallChainDepth,
      maxValueLength: maxValueLength,
      skipUnchangedValues: skipUnchangedValues,
      ignoredPackagePrefixes: [
        'package:flutter/',
        'package:flutter_riverpod/',
        'package:riverpod/',
        'package:riverpod_annotation/',
        'package:riverpod_devtools_tracker/',
        'dart:',
        ...additionalIgnored,
      ],
      ignoredFilePatterns: ignoredFilePatterns,
    );
  }

  /// Creates a copy of this config with the given fields replaced
  ///
  /// Returns a new [TrackerConfig] instance with the specified fields
  /// updated while keeping all other fields unchanged.
  ///
  /// Example:
  /// ```dart
  /// final config = TrackerConfig.forPackage('my_app');
  /// final prodConfig = config.copyWith(
  ///   enableConsoleOutput: false,
  ///   maxCallChainDepth: 5,
  /// );
  /// ```
  TrackerConfig copyWith({
    bool? enabled,
    List<String>? packagePrefixes,
    bool? enableConsoleOutput,
    bool? prettyConsoleOutput,
    int? maxCallChainDepth,
    int? maxValueLength,
    bool? skipUnchangedValues,
    List<String>? ignoredPackagePrefixes,
    List<String>? ignoredFilePatterns,
  }) {
    return TrackerConfig(
      enabled: enabled ?? this.enabled,
      packagePrefixes: packagePrefixes ?? this.packagePrefixes,
      enableConsoleOutput: enableConsoleOutput ?? this.enableConsoleOutput,
      prettyConsoleOutput: prettyConsoleOutput ?? this.prettyConsoleOutput,
      maxCallChainDepth: maxCallChainDepth ?? this.maxCallChainDepth,
      maxValueLength: maxValueLength ?? this.maxValueLength,
      skipUnchangedValues: skipUnchangedValues ?? this.skipUnchangedValues,
      ignoredPackagePrefixes:
          ignoredPackagePrefixes ?? this.ignoredPackagePrefixes,
      ignoredFilePatterns: ignoredFilePatterns ?? this.ignoredFilePatterns,
    );
  }
}
