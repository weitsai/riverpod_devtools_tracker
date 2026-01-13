import 'package:flutter/material.dart';

/// Performance statistics model for DevTools extension
///
/// This provides type-safe access to performance metrics data received
/// from the core tracker library via developer.postEvent().
class PerformanceStatsModel {
  final int totalOperations;
  final double totalTimeMs;
  final double averageTimeMs;
  final List<ProviderPerformanceModel> providerStats;

  const PerformanceStatsModel({
    required this.totalOperations,
    required this.totalTimeMs,
    required this.averageTimeMs,
    required this.providerStats,
  });

  /// Create from JSON data received from postEvent
  factory PerformanceStatsModel.fromJson(Map<String, dynamic> json) {
    final providerStatsJson = json['providerStats'] as List<dynamic>? ?? [];

    return PerformanceStatsModel(
      totalOperations: json['totalOperations'] as int? ?? 0,
      totalTimeMs: (json['totalTimeMs'] as num?)?.toDouble() ?? 0.0,
      averageTimeMs: (json['averageTimeMs'] as num?)?.toDouble() ?? 0.0,
      providerStats: providerStatsJson
          .map((item) => ProviderPerformanceModel.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }

  /// Check if statistics are empty (no operations recorded)
  bool get isEmpty => totalOperations == 0;
}

/// Performance statistics for a single provider
class ProviderPerformanceModel {
  final String providerName;
  final int updateCount;
  final double averageTimeMs;
  final double maxTimeMs;
  final double minTimeMs;
  final double averageStackTraceMs;
  final double averageSerializationMs;
  final double totalTimeMs;

  const ProviderPerformanceModel({
    required this.providerName,
    required this.updateCount,
    required this.averageTimeMs,
    required this.maxTimeMs,
    required this.minTimeMs,
    required this.averageStackTraceMs,
    required this.averageSerializationMs,
    required this.totalTimeMs,
  });

  /// Create from JSON data
  factory ProviderPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ProviderPerformanceModel(
      providerName: json['providerName'] as String? ?? 'Unknown',
      updateCount: json['updateCount'] as int? ?? 0,
      averageTimeMs: (json['averageTimeMs'] as num?)?.toDouble() ?? 0.0,
      maxTimeMs: (json['maxTimeMs'] as num?)?.toDouble() ?? 0.0,
      minTimeMs: (json['minTimeMs'] as num?)?.toDouble() ?? 0.0,
      averageStackTraceMs:
          (json['averageStackTraceMs'] as num?)?.toDouble() ?? 0.0,
      averageSerializationMs:
          (json['averageSerializationMs'] as num?)?.toDouble() ?? 0.0,
      totalTimeMs: (json['totalTimeMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Performance level based on average time
  PerformanceLevel get performanceLevel {
    if (averageTimeMs < PerformanceLevel.excellentThreshold) {
      return PerformanceLevel.excellent;
    } else if (averageTimeMs < PerformanceLevel.goodThreshold) {
      return PerformanceLevel.good;
    } else if (averageTimeMs < PerformanceLevel.fairThreshold) {
      return PerformanceLevel.fair;
    } else {
      return PerformanceLevel.slow;
    }
  }
}

/// Performance level classification
enum PerformanceLevel {
  excellent,
  good,
  fair,
  slow;

  /// Threshold for excellent performance (in milliseconds)
  static const double excellentThreshold = 1.0;

  /// Threshold for good performance (in milliseconds)
  static const double goodThreshold = 5.0;

  /// Threshold for fair performance (in milliseconds)
  static const double fairThreshold = 10.0;

  /// Human-readable label
  String get label {
    switch (this) {
      case PerformanceLevel.excellent:
        return 'Excellent';
      case PerformanceLevel.good:
        return 'Good';
      case PerformanceLevel.fair:
        return 'Fair';
      case PerformanceLevel.slow:
        return 'Slow';
    }
  }

  /// Color for UI display
  Color get color {
    switch (this) {
      case PerformanceLevel.excellent:
        return const Color(0xFF10B981); // Green
      case PerformanceLevel.good:
        return const Color(0xFF3B82F6); // Blue
      case PerformanceLevel.fair:
        return const Color(0xFFF59E0B); // Orange
      case PerformanceLevel.slow:
        return const Color(0xFFEF4444); // Red
    }
  }
}
