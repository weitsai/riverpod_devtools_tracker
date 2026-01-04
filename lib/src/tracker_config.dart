/// Configuration for Riverpod DevTools Tracker
class TrackerConfig {
  /// Whether tracking is enabled
  final bool enabled;

  /// Package prefixes for your app, used to filter stack traces
  /// Example: ['package:my_app/', 'package:my_common/']
  final List<String> packagePrefixes;

  /// Whether to output tracking info to console
  final bool enableConsoleOutput;

  /// Whether to use pretty formatted console output (with box characters)
  final bool prettyConsoleOutput;

  /// Maximum call chain depth
  final int maxCallChainDepth;

  /// Maximum value display length
  final int maxValueLength;

  /// Package prefixes to ignore
  final List<String> ignoredPackagePrefixes;

  /// File patterns to ignore (partial match)
  final List<String> ignoredFilePatterns;

  const TrackerConfig({
    this.enabled = true,
    this.packagePrefixes = const [],
    this.enableConsoleOutput = true,
    this.prettyConsoleOutput = true,
    this.maxCallChainDepth = 10,
    this.maxValueLength = 200,
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

  /// Copy and modify config
  TrackerConfig copyWith({
    bool? enabled,
    List<String>? packagePrefixes,
    bool? enableConsoleOutput,
    bool? prettyConsoleOutput,
    int? maxCallChainDepth,
    int? maxValueLength,
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
      ignoredPackagePrefixes:
          ignoredPackagePrefixes ?? this.ignoredPackagePrefixes,
      ignoredFilePatterns: ignoredFilePatterns ?? this.ignoredFilePatterns,
    );
  }
}




