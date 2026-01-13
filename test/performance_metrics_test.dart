import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/src/performance_metrics.dart';

void main() {
  group('TrackingMetrics', () {
    test('creates metrics with correct values', () {
      final metrics = TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 1500),
        callChainDepth: 5,
        valueSize: 100,
      );

      expect(metrics.stackTraceParsingTime.inMicroseconds, 1000);
      expect(metrics.valueSerializationTime.inMicroseconds, 500);
      expect(metrics.totalTime.inMicroseconds, 1500);
      expect(metrics.callChainDepth, 5);
      expect(metrics.valueSize, 100);
    });

    test('toJson converts microseconds to milliseconds correctly', () {
      final metrics = TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 1500),
        callChainDepth: 5,
        valueSize: 100,
      );

      final json = metrics.toJson();

      expect(json['stackTraceParsingMs'], 1.0);
      expect(json['valueSerializationMs'], 0.5);
      expect(json['totalMs'], 1.5);
      expect(json['callChainDepth'], 5);
      expect(json['valueSize'], 100);
    });

    test('toJson handles zero duration', () {
      final metrics = TrackingMetrics(
        stackTraceParsingTime: Duration.zero,
        valueSerializationTime: Duration.zero,
        totalTime: Duration.zero,
        callChainDepth: 0,
        valueSize: 0,
      );

      final json = metrics.toJson();

      expect(json['stackTraceParsingMs'], 0.0);
      expect(json['valueSerializationMs'], 0.0);
      expect(json['totalMs'], 0.0);
    });
  });

  group('ProviderPerformanceStats', () {
    test('initializes with zero values', () {
      final stats = ProviderPerformanceStats(providerName: 'testProvider');

      expect(stats.providerName, 'testProvider');
      expect(stats.updateCount, 0);
      expect(stats.totalTimeMicros, 0);
      expect(stats.maxTimeMicros, 0);
      expect(stats.minTimeMicros, double.maxFinite.toInt());
      expect(stats.averageTimeMs, 0.0);
      expect(stats.maxTimeMs, 0.0);
      expect(stats.minTimeMs, 0.0);
    });

    test('recordUpdate accumulates metrics correctly', () {
      final stats = ProviderPerformanceStats(providerName: 'testProvider');

      final metrics1 = TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      );

      stats.recordUpdate(metrics1);

      expect(stats.updateCount, 1);
      expect(stats.totalTimeMicros, 2000);
      expect(stats.maxTimeMicros, 2000);
      expect(stats.minTimeMicros, 2000);
      expect(stats.averageTimeMs, 2.0);
    });

    test('recordUpdate tracks min and max correctly', () {
      final stats = ProviderPerformanceStats(providerName: 'testProvider');

      // Add first metric (2000 microseconds)
      stats.recordUpdate(TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      // Add faster metric (1000 microseconds)
      stats.recordUpdate(TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 500),
        valueSerializationTime: Duration(microseconds: 300),
        totalTime: Duration(microseconds: 1000),
        callChainDepth: 3,
        valueSize: 50,
      ));

      // Add slower metric (3000 microseconds)
      stats.recordUpdate(TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1500),
        valueSerializationTime: Duration(microseconds: 800),
        totalTime: Duration(microseconds: 3000),
        callChainDepth: 7,
        valueSize: 150,
      ));

      expect(stats.updateCount, 3);
      expect(stats.minTimeMicros, 1000);
      expect(stats.maxTimeMicros, 3000);
      expect(stats.minTimeMs, 1.0);
      expect(stats.maxTimeMs, 3.0);
    });

    test('calculates average times correctly', () {
      final stats = ProviderPerformanceStats(providerName: 'testProvider');

      stats.recordUpdate(TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      stats.recordUpdate(TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 2000),
        valueSerializationTime: Duration(microseconds: 1000),
        totalTime: Duration(microseconds: 4000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      // Average: (2000 + 4000) / 2 = 3000 microseconds = 3.0 ms
      expect(stats.averageTimeMs, 3.0);

      // Average stack trace: (1000 + 2000) / 2 = 1500 microseconds = 1.5 ms
      expect(stats.averageStackTraceMs, 1.5);

      // Average serialization: (500 + 1000) / 2 = 750 microseconds = 0.75 ms
      expect(stats.averageSerializationMs, 0.75);
    });

    test('toJson includes all metrics', () {
      final stats = ProviderPerformanceStats(providerName: 'testProvider');

      stats.recordUpdate(TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      final json = stats.toJson();

      expect(json['providerName'], 'testProvider');
      expect(json['updateCount'], 1);
      expect(json['averageTimeMs'], 2.0);
      expect(json['maxTimeMs'], 2.0);
      expect(json['minTimeMs'], 2.0);
      expect(json['averageStackTraceMs'], 1.0);
      expect(json['averageSerializationMs'], 0.5);
      expect(json['totalTimeMs'], 2.0);
    });
  });

  group('PerformanceStatistics', () {
    test('initializes with empty stats', () {
      final stats = PerformanceStatistics();

      expect(stats.providerStats, isEmpty);
      expect(stats.totalOperations, 0);
      expect(stats.totalTimeMs, 0.0);
      expect(stats.averageTimeMs, 0.0);
    });

    test('getOrCreateStats creates new stats on first call', () {
      final stats = PerformanceStatistics();

      final providerStats = stats.getOrCreateStats('testProvider');

      expect(providerStats.providerName, 'testProvider');
      expect(stats.providerStats.length, 1);
    });

    test('getOrCreateStats returns existing stats on subsequent calls', () {
      final stats = PerformanceStatistics();

      final providerStats1 = stats.getOrCreateStats('testProvider');
      final providerStats2 = stats.getOrCreateStats('testProvider');

      expect(identical(providerStats1, providerStats2), true);
      expect(stats.providerStats.length, 1);
    });

    test('recordOperation accumulates metrics across providers', () {
      final stats = PerformanceStatistics();

      final metrics1 = TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      );

      final metrics2 = TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1500),
        valueSerializationTime: Duration(microseconds: 800),
        totalTime: Duration(microseconds: 3000),
        callChainDepth: 7,
        valueSize: 150,
      );

      stats.recordOperation('provider1', metrics1);
      stats.recordOperation('provider2', metrics2);

      expect(stats.providerStats.length, 2);
      expect(stats.totalOperations, 2);
      expect(stats.totalTimeMs, 5.0); // 2.0 + 3.0
      expect(stats.averageTimeMs, 2.5); // 5.0 / 2
    });

    test('recordOperation accumulates multiple metrics for same provider', () {
      final stats = PerformanceStatistics();

      final metrics1 = TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      );

      final metrics2 = TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1500),
        valueSerializationTime: Duration(microseconds: 800),
        totalTime: Duration(microseconds: 4000),
        callChainDepth: 7,
        valueSize: 150,
      );

      stats.recordOperation('provider1', metrics1);
      stats.recordOperation('provider1', metrics2);

      expect(stats.providerStats.length, 1);
      expect(stats.totalOperations, 2);
      expect(stats.totalTimeMs, 6.0); // 2.0 + 4.0
    });

    test('getTopByUpdateCount returns providers sorted by update count', () {
      final stats = PerformanceStatistics();

      // Provider1: 3 updates
      stats.recordOperation('provider1', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));
      stats.recordOperation('provider1', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));
      stats.recordOperation('provider1', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      // Provider2: 1 update
      stats.recordOperation('provider2', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      // Provider3: 2 updates
      stats.recordOperation('provider3', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));
      stats.recordOperation('provider3', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      final top = stats.getTopByUpdateCount(2);

      expect(top.length, 2);
      expect(top[0].providerName, 'provider1');
      expect(top[0].updateCount, 3);
      expect(top[1].providerName, 'provider3');
      expect(top[1].updateCount, 2);
    });

    test('getTopByAverageTime returns providers sorted by average time', () {
      final stats = PerformanceStatistics();

      // Provider1: average 2ms
      stats.recordOperation('provider1', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      // Provider2: average 5ms
      stats.recordOperation('provider2', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 2500),
        valueSerializationTime: Duration(microseconds: 2000),
        totalTime: Duration(microseconds: 5000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      // Provider3: average 3ms
      stats.recordOperation('provider3', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1500),
        valueSerializationTime: Duration(microseconds: 1000),
        totalTime: Duration(microseconds: 3000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      final top = stats.getTopByAverageTime(2);

      expect(top.length, 2);
      expect(top[0].providerName, 'provider2');
      expect(top[0].averageTimeMs, 5.0);
      expect(top[1].providerName, 'provider3');
      expect(top[1].averageTimeMs, 3.0);
    });

    test('getTopByUpdateCount returns all providers when n is larger', () {
      final stats = PerformanceStatistics();

      stats.recordOperation('provider1', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      stats.recordOperation('provider2', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      final top = stats.getTopByUpdateCount(10);

      expect(top.length, 2);
    });

    test('clear removes all statistics', () {
      final stats = PerformanceStatistics();

      stats.recordOperation('provider1', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      stats.recordOperation('provider2', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      expect(stats.providerStats.length, 2);
      expect(stats.totalOperations, 2);

      stats.clear();

      expect(stats.providerStats, isEmpty);
      expect(stats.totalOperations, 0);
      expect(stats.totalTimeMs, 0.0);
      expect(stats.averageTimeMs, 0.0);
    });

    test('toJson includes all statistics', () {
      final stats = PerformanceStatistics();

      stats.recordOperation('provider1', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1000),
        valueSerializationTime: Duration(microseconds: 500),
        totalTime: Duration(microseconds: 2000),
        callChainDepth: 5,
        valueSize: 100,
      ));

      stats.recordOperation('provider2', TrackingMetrics(
        stackTraceParsingTime: Duration(microseconds: 1500),
        valueSerializationTime: Duration(microseconds: 800),
        totalTime: Duration(microseconds: 3000),
        callChainDepth: 7,
        valueSize: 150,
      ));

      final json = stats.toJson();

      expect(json['totalOperations'], 2);
      expect(json['totalTimeMs'], 5.0);
      expect(json['averageTimeMs'], 2.5);
      expect(json['providerStats'], hasLength(2));
      expect(json['providerStats'][0]['providerName'], isA<String>());
    });
  });
}
