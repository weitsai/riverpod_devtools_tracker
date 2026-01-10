/// Performance metrics for Riverpod DevTools Tracker
///
/// This file contains classes for tracking and analyzing the performance
/// impact of the tracker itself, including parsing times, serialization
/// times, and Provider update frequencies.
library;

/// Performance metrics for a single tracking operation
class TrackingMetrics {
  /// Time spent parsing stack trace
  final Duration stackTraceParsingTime;

  /// Time spent serializing values
  final Duration valueSerializationTime;

  /// Total time for the tracking operation
  final Duration totalTime;

  /// Depth of the call chain captured
  final int callChainDepth;

  /// Size of serialized value in characters
  final int valueSize;

  const TrackingMetrics({
    required this.stackTraceParsingTime,
    required this.valueSerializationTime,
    required this.totalTime,
    required this.callChainDepth,
    required this.valueSize,
  });

  /// Convert to JSON for transmission to DevTools
  Map<String, dynamic> toJson() => {
        'stackTraceParsingMs': stackTraceParsingTime.inMicroseconds / 1000,
        'valueSerializationMs': valueSerializationTime.inMicroseconds / 1000,
        'totalMs': totalTime.inMicroseconds / 1000,
        'callChainDepth': callChainDepth,
        'valueSize': valueSize,
      };
}

/// Aggregated performance statistics for a Provider
class ProviderPerformanceStats {
  /// Name of the provider
  final String providerName;

  /// Number of times this provider was updated
  int updateCount = 0;

  /// Total time spent tracking this provider (in microseconds)
  int totalTimeMicros = 0;

  /// Maximum time for a single tracking operation (in microseconds)
  int maxTimeMicros = 0;

  /// Minimum time for a single tracking operation (in microseconds)
  int minTimeMicros = double.maxFinite.toInt();

  /// Total stack trace parsing time (in microseconds)
  int totalStackTraceTimeMicros = 0;

  /// Total value serialization time (in microseconds)
  int totalSerializationTimeMicros = 0;

  ProviderPerformanceStats({required this.providerName});

  /// Average time per update in milliseconds
  double get averageTimeMs =>
      updateCount > 0 ? (totalTimeMicros / updateCount) / 1000 : 0.0;

  /// Maximum time in milliseconds
  double get maxTimeMs => maxTimeMicros / 1000;

  /// Minimum time in milliseconds
  double get minTimeMs =>
      minTimeMicros == double.maxFinite.toInt() ? 0 : minTimeMicros / 1000;

  /// Average stack trace parsing time in milliseconds
  double get averageStackTraceMs =>
      updateCount > 0 ? (totalStackTraceTimeMicros / updateCount) / 1000 : 0.0;

  /// Average serialization time in milliseconds
  double get averageSerializationMs =>
      updateCount > 0
          ? (totalSerializationTimeMicros / updateCount) / 1000
          : 0.0;

  /// Record a new tracking operation
  void recordUpdate(TrackingMetrics metrics) {
    updateCount++;
    final timeMicros = metrics.totalTime.inMicroseconds;
    totalTimeMicros += timeMicros;
    totalStackTraceTimeMicros += metrics.stackTraceParsingTime.inMicroseconds;
    totalSerializationTimeMicros +=
        metrics.valueSerializationTime.inMicroseconds;

    if (timeMicros > maxTimeMicros) {
      maxTimeMicros = timeMicros;
    }
    if (timeMicros < minTimeMicros) {
      minTimeMicros = timeMicros;
    }
  }

  /// Convert to JSON for transmission to DevTools
  Map<String, dynamic> toJson() => {
        'providerName': providerName,
        'updateCount': updateCount,
        'averageTimeMs': averageTimeMs,
        'maxTimeMs': maxTimeMs,
        'minTimeMs': minTimeMs,
        'averageStackTraceMs': averageStackTraceMs,
        'averageSerializationMs': averageSerializationMs,
        'totalTimeMs': totalTimeMicros / 1000,
      };
}

/// Overall performance statistics
class PerformanceStatistics {
  /// Performance stats for each provider
  final Map<String, ProviderPerformanceStats> providerStats = {};

  /// Total number of tracking operations
  int get totalOperations =>
      providerStats.values.fold(0, (sum, stats) => sum + stats.updateCount);

  /// Total time spent tracking (in milliseconds)
  double get totalTimeMs => providerStats.values
      .fold(0.0, (sum, stats) => sum + stats.totalTimeMicros / 1000);

  /// Average time per operation (in milliseconds)
  double get averageTimeMs =>
      totalOperations > 0 ? totalTimeMs / totalOperations : 0.0;

  /// Get or create stats for a provider
  ProviderPerformanceStats getOrCreateStats(String providerName) {
    return providerStats.putIfAbsent(
      providerName,
      () => ProviderPerformanceStats(providerName: providerName),
    );
  }

  /// Record a tracking operation
  void recordOperation(String providerName, TrackingMetrics metrics) {
    getOrCreateStats(providerName).recordUpdate(metrics);
  }

  /// Get top N providers by update count
  List<ProviderPerformanceStats> getTopByUpdateCount(int n) {
    final sorted = providerStats.values.toList()
      ..sort((a, b) => b.updateCount.compareTo(a.updateCount));
    return sorted.take(n).toList();
  }

  /// Get top N providers by average time
  List<ProviderPerformanceStats> getTopByAverageTime(int n) {
    final sorted = providerStats.values.toList()
      ..sort((a, b) => b.averageTimeMs.compareTo(a.averageTimeMs));
    return sorted.take(n).toList();
  }

  /// Clear all statistics
  void clear() {
    providerStats.clear();
  }

  /// Convert to JSON for transmission to DevTools
  Map<String, dynamic> toJson() => {
        'totalOperations': totalOperations,
        'totalTimeMs': totalTimeMs,
        'averageTimeMs': averageTimeMs,
        'providerStats':
            providerStats.values.map((stats) => stats.toJson()).toList(),
      };
}
