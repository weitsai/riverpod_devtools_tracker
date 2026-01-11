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
///
/// // Use provider references for type-safe filtering
/// RiverpodDevToolsObserver(
///   config: TrackerConfig.forPackage(
///     'my_app',
///     // Blacklist: ignore these providers
///     ignoredProviders: [debugProvider, tempProvider],
///     // Or use whitelist: only track these providers
///     // trackedProviders: [counterProvider, userProvider],
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

  /// Whitelist of Provider names to track (if not empty, only these will be tracked)
  ///
  /// When this set is not empty, ONLY providers whose names are in this set
  /// will be tracked. This is useful for focusing on specific providers in
  /// large applications.
  ///
  /// This stores the extracted names from provider references passed to the constructor.
  /// Use [TrackerConfig.forPackage] with `trackedProviders` parameter to specify
  /// which providers to track.
  ///
  /// Note: If both [trackedProviders] and [ignoredProviders] are set,
  /// [trackedProviders] takes precedence (whitelist before blacklist).
  final Set<String> _trackedProviderNames;

  /// Blacklist of Provider names to ignore
  ///
  /// Providers whose names are in this set will NOT be tracked.
  /// This is useful for ignoring noisy or uninteresting providers.
  ///
  /// This stores the extracted names from provider references passed to the constructor.
  /// Use [TrackerConfig.forPackage] with `ignoredProviders` parameter to specify
  /// which providers to ignore.
  final Set<String> _ignoredProviderNames;

  /// Custom filter function for providers
  ///
  /// If provided, this function will be called for each provider to determine
  /// whether it should be tracked. The function receives the provider name
  /// and type, and should return true if the provider should be tracked.
  ///
  /// This allows for more complex filtering logic, such as:
  /// - Filtering by provider type (e.g., only StateProvider)
  /// - Pattern matching on provider names (e.g., names ending with 'Store')
  /// - Combining multiple conditions
  ///
  /// Example:
  /// ```dart
  /// providerFilter: (name, type) {
  ///   // Only track StateProvider and StateNotifierProvider
  ///   return type.contains('State');
  /// }
  /// ```
  ///
  /// Note: This filter is applied AFTER [trackedProviders] and [ignoredProviders].
  final bool Function(String providerName, String providerType)? providerFilter;

  /// Internal helper to extract provider names from provider references
  ///
  /// This method extracts the name property from Riverpod providers using
  /// dynamic dispatch. Works with any Riverpod provider type (Provider,
  /// NotifierProvider, FutureProvider, etc.).
  ///
  /// Falls back to runtime type name if the name property is not accessible.
  static Set<String> _extractProviderNames(Iterable<Object> providers) {
    return providers.map((p) {
      // Try to access the 'name' property that all Riverpod providers have
      try {
        final dynamic provider = p;
        final String? name = provider.name as String?;
        if (name != null && name.isNotEmpty) {
          return name;
        }
      } catch (e) {
        // In debug mode, warn about extraction failures
        assert(() {
          // ignore: avoid_print
          print('Warning: Unable to extract name from provider $p: $e');
          return true;
        }());
      }
      // Fall back to runtimeType without generic parameters
      return p.runtimeType.toString().replaceAll(RegExp(r'<.*>'), '');
    }).toSet();
  }

  /// Getter for tracked provider names (for internal use by observer)
  Set<String> get trackedProviders => _trackedProviderNames;

  /// Getter for ignored provider names (for internal use by observer)
  Set<String> get ignoredProviders => _ignoredProviderNames;

  /// Whether to enable stack trace parsing cache
  ///
  /// When enabled, parsed stack traces are cached to avoid redundant parsing
  /// of the same stack trace. This significantly improves performance for
  /// frequently updated providers, especially async providers.
  ///
  /// Performance impact: 80-90% reduction in parsing time for repeated traces.
  /// Default: true (caching enabled)
  final bool enableStackTraceCache;

  /// Maximum number of stack traces to cache
  ///
  /// When the cache exceeds this size, the oldest (least recently used)
  /// entries are removed. Higher values provide better cache hit rates but
  /// use more memory.
  ///
  /// Typical memory usage: ~100-500 bytes per cached entry.
  /// Default: 500 entries
  final int maxStackTraceCacheSize;

  /// Whether to enable periodic memory cleanup
  ///
  /// When enabled, a timer periodically removes expired stack traces
  /// from the cache to prevent memory buildup. This helps maintain
  /// stable memory usage during long debugging sessions.
  ///
  /// Default: true (enabled for automatic memory management)
  final bool enablePeriodicCleanup;

  /// Interval between automatic cleanup operations
  ///
  /// Determines how often the cleanup timer runs to remove expired
  /// stack traces from memory. More frequent cleanup uses slightly
  /// more CPU but keeps memory footprint smaller.
  ///
  /// Default: Duration(seconds: 30)
  final Duration cleanupInterval;

  /// How long stack traces are kept before being considered expired
  ///
  /// Stack traces older than this duration will be removed during
  /// cleanup. Longer durations keep more history but use more memory.
  ///
  /// Default: Duration(seconds: 60)
  final Duration stackExpirationDuration;

  /// Maximum number of stack traces to keep in cache
  ///
  /// When this limit is exceeded, the oldest stack traces are removed
  /// even if they haven't expired yet. This provides a hard limit on
  /// memory usage.
  ///
  /// Default: 100 stack traces
  final int maxStackCacheSize;

  /// Whether to collect performance metrics
  ///
  /// When enabled, the tracker will collect detailed performance metrics
  /// including parsing times, serialization times, and update frequencies.
  /// These metrics can be viewed in the DevTools extension's Performance panel.
  ///
  /// Recommended: false for production, true for development/debugging
  final bool collectPerformanceMetrics;

  /// Whether to enable persistent storage of event history
  ///
  /// When enabled, provider events are saved to local storage and can be
  /// restored when DevTools reconnects. This allows debugging across sessions.
  ///
  /// Events are stored as JSON Lines in the application documents directory.
  /// The storage file is automatically managed (max 10 MB).
  ///
  /// Note: Requires path_provider package to be added to dependencies.
  /// Default: false (disabled for backwards compatibility)
  final bool enablePersistence;

  /// Maximum number of events to persist
  ///
  /// Limits the number of events loaded from storage to prevent memory issues.
  /// When loading events, only the most recent [maxPersistedEvents] will be
  /// restored to DevTools.
  ///
  /// Default: 1000 events
  final int maxPersistedEvents;

  /// Whether to clear persisted events when the app starts
  ///
  /// When true, all previously stored events will be cleared when the
  /// observer is initialized. This ensures you only see events from the
  /// current session.
  ///
  /// When false, events from previous sessions will be preserved and
  /// loaded when DevTools connects.
  ///
  /// Only applies when [enablePersistence] is true.
  /// Default: true (clear on start for cleaner debugging experience)
  final bool clearOnStart;

  const TrackerConfig({
    this.enabled = true,
    this.packagePrefixes = const [],
    this.enableConsoleOutput = true,
    this.prettyConsoleOutput = true,
    this.maxCallChainDepth = 10,
    this.maxValueLength = 200,
    this.skipUnchangedValues = true,
    Set<String> trackedProviders = const {},
    Set<String> ignoredProviders = const {},
    this.providerFilter,
    this.enableStackTraceCache = true,
    this.maxStackTraceCacheSize = 500,
    this.enablePeriodicCleanup = true,
    this.cleanupInterval = const Duration(seconds: 30),
    this.stackExpirationDuration = const Duration(seconds: 60),
    this.maxStackCacheSize = 100,
    this.collectPerformanceMetrics = false,
    this.enablePersistence = false,
    this.maxPersistedEvents = 1000,
    this.clearOnStart = true,
    this.ignoredPackagePrefixes = const [
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:riverpod/',
      'package:riverpod_annotation/',
      'package:riverpod_devtools_tracker/',
      'dart:',
    ],
    this.ignoredFilePatterns = const [],
  })  : _trackedProviderNames = trackedProviders,
        _ignoredProviderNames = ignoredProviders;

  /// Create a config for a specific package
  ///
  /// Use provider references for type-safe filtering with IDE auto-completion:
  ///
  /// ```dart
  /// TrackerConfig.forPackage(
  ///   'my_app',
  ///   // Whitelist: only track these providers
  ///   trackedProviders: [counterProvider, userProvider],
  ///
  ///   // Blacklist: ignore these providers
  ///   ignoredProviders: [debugProvider, tempProvider],
  ///
  ///   // Custom filter for advanced logic
  ///   providerFilter: (name, type) => type.contains('State'),
  /// )
  /// ```
  factory TrackerConfig.forPackage(
    String packageName, {
    bool enabled = true,
    bool enableConsoleOutput = true,
    bool prettyConsoleOutput = true,
    int maxCallChainDepth = 10,
    int maxValueLength = 200,
    bool skipUnchangedValues = true,

    /// Provider references to track (whitelist)
    ///
    /// Pass actual provider instances for compile-time safety and IDE auto-completion.
    /// When specified, ONLY these providers will be tracked.
    ///
    /// Example: `[counterProvider, userProvider, authProvider]`
    Iterable<Object>? trackedProviders,

    /// Provider references to ignore (blacklist)
    ///
    /// Pass actual provider instances for compile-time safety and IDE auto-completion.
    /// These providers will NOT be tracked.
    ///
    /// Example: `[debugProvider, tempProvider]`
    Iterable<Object>? ignoredProviders,
    bool Function(String providerName, String providerType)? providerFilter,
    bool enableStackTraceCache = true,
    int maxStackTraceCacheSize = 500,
    bool enablePeriodicCleanup = true,
    Duration cleanupInterval = const Duration(seconds: 30),
    Duration stackExpirationDuration = const Duration(seconds: 60),
    int maxStackCacheSize = 100,
    bool collectPerformanceMetrics = false,
    bool enablePersistence = false,
    int maxPersistedEvents = 1000,
    bool clearOnStart = true,
    List<String> additionalPackages = const [],
    List<String> additionalIgnored = const [],
    List<String> ignoredFilePatterns = const [],
  }) {
    // Extract provider names from references
    final trackedNames = trackedProviders != null
        ? _extractProviderNames(trackedProviders)
        : const <String>{};
    final ignoredNames = ignoredProviders != null
        ? _extractProviderNames(ignoredProviders)
        : const <String>{};

    return TrackerConfig(
      enabled: enabled,
      packagePrefixes: ['package:$packageName/', ...additionalPackages],
      enableConsoleOutput: enableConsoleOutput,
      prettyConsoleOutput: prettyConsoleOutput,
      maxCallChainDepth: maxCallChainDepth,
      maxValueLength: maxValueLength,
      skipUnchangedValues: skipUnchangedValues,
      trackedProviders: trackedNames,
      ignoredProviders: ignoredNames,
      providerFilter: providerFilter,
      enableStackTraceCache: enableStackTraceCache,
      maxStackTraceCacheSize: maxStackTraceCacheSize,
      enablePeriodicCleanup: enablePeriodicCleanup,
      cleanupInterval: cleanupInterval,
      stackExpirationDuration: stackExpirationDuration,
      maxStackCacheSize: maxStackCacheSize,
      collectPerformanceMetrics: collectPerformanceMetrics,
      enablePersistence: enablePersistence,
      maxPersistedEvents: maxPersistedEvents,
      clearOnStart: clearOnStart,
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
    Set<String>? trackedProviders,
    Set<String>? ignoredProviders,
    bool Function(String providerName, String providerType)? providerFilter,
    bool? enableStackTraceCache,
    int? maxStackTraceCacheSize,
    bool? enablePeriodicCleanup,
    Duration? cleanupInterval,
    Duration? stackExpirationDuration,
    int? maxStackCacheSize,
    bool? collectPerformanceMetrics,
    bool? enablePersistence,
    int? maxPersistedEvents,
    bool? clearOnStart,
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
      trackedProviders: trackedProviders ?? this.trackedProviders,
      ignoredProviders: ignoredProviders ?? this.ignoredProviders,
      providerFilter: providerFilter ?? this.providerFilter,
      enableStackTraceCache:
          enableStackTraceCache ?? this.enableStackTraceCache,
      maxStackTraceCacheSize:
          maxStackTraceCacheSize ?? this.maxStackTraceCacheSize,
      enablePeriodicCleanup:
          enablePeriodicCleanup ?? this.enablePeriodicCleanup,
      cleanupInterval: cleanupInterval ?? this.cleanupInterval,
      stackExpirationDuration:
          stackExpirationDuration ?? this.stackExpirationDuration,
      maxStackCacheSize: maxStackCacheSize ?? this.maxStackCacheSize,
      collectPerformanceMetrics:
          collectPerformanceMetrics ?? this.collectPerformanceMetrics,
      enablePersistence: enablePersistence ?? this.enablePersistence,
      maxPersistedEvents: maxPersistedEvents ?? this.maxPersistedEvents,
      clearOnStart: clearOnStart ?? this.clearOnStart,
      ignoredPackagePrefixes:
          ignoredPackagePrefixes ?? this.ignoredPackagePrefixes,
      ignoredFilePatterns: ignoredFilePatterns ?? this.ignoredFilePatterns,
    );
  }
}
