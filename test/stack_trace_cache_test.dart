import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/src/stack_trace_parser.dart';
import 'package:riverpod_devtools_tracker/src/tracker_config.dart';

void main() {
  group('Stack Trace Cache', () {
    test('cache is enabled by default', () {
      final config = TrackerConfig.forPackage('test_app');
      expect(config.enableStackTraceCache, true);
      expect(config.maxStackTraceCacheSize, 500);
    });

    test('cache can be disabled', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enableStackTraceCache: false,
      );
      expect(config.enableStackTraceCache, false);
    });

    test('cache size can be configured', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        maxStackTraceCacheSize: 100,
      );
      expect(config.maxStackTraceCacheSize, 100);
    });

    test('parseCallChain caches results when enabled', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enableStackTraceCache: true,
      );
      final parser = StackTraceParser(config);

      // Create a mock stack trace
      final stackTrace = StackTrace.current;

      // First call - cache miss
      final result1 = parser.parseCallChain(stackTrace);

      // Second call - should be cache hit
      final result2 = parser.parseCallChain(stackTrace);

      // Results should be identical (same instance)
      expect(identical(result1, result2), true);
    });

    test('parseCallChain does not cache when disabled', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enableStackTraceCache: false,
      );
      final parser = StackTraceParser(config);

      final stackTrace = StackTrace.current;

      // First call
      final result1 = parser.parseCallChain(stackTrace);

      // Second call
      final result2 = parser.parseCallChain(stackTrace);

      // Results should not be identical (different instances)
      expect(identical(result1, result2), false);
    });

    test('findTriggerLocation caches results when enabled', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enableStackTraceCache: true,
      );
      final parser = StackTraceParser(config);

      final stackTrace = StackTrace.current;

      // First call - cache miss
      final result1 = parser.findTriggerLocation(stackTrace);

      // Second call - should be cache hit
      final result2 = parser.findTriggerLocation(stackTrace);

      // Results should be identical (same instance)
      if (result1 != null && result2 != null) {
        expect(identical(result1, result2), true);
      }
    });

    test('cache evicts LRU entries when size limit exceeded', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enableStackTraceCache: true,
        maxStackTraceCacheSize: 2, // Small cache size for testing
      );
      final parser = StackTraceParser(config);

      // Use custom stack traces with unique content to ensure different hashes
      final trace1 = StackTrace.fromString(
        '#0 function1 (package:test_app/file1.dart:10:5)\n'
        '#1 function2 (package:test_app/file2.dart:20:5)',
      );
      final trace2 = StackTrace.fromString(
        '#0 function3 (package:test_app/file3.dart:30:5)\n'
        '#1 function4 (package:test_app/file4.dart:40:5)',
      );
      final trace3 = StackTrace.fromString(
        '#0 function5 (package:test_app/file5.dart:50:5)\n'
        '#1 function6 (package:test_app/file6.dart:60:5)',
      );

      // Parse first 2 traces - cache is full (size=2)
      final result1First = parser.parseCallChain(trace1);
      final result2First = parser.parseCallChain(trace2);

      // Both should be cached
      expect(identical(result1First, parser.parseCallChain(trace1)), true);
      expect(identical(result2First, parser.parseCallChain(trace2)), true);

      // Parse 3rd trace - should evict trace1 (oldest)
      final result3First = parser.parseCallChain(trace3);

      // Trace 1 should be evicted (cache miss)
      final result1Second = parser.parseCallChain(trace1);
      expect(identical(result1First, result1Second), false);

      // Trace 2 and 3 should still be cached
      // Note: trace1 was just re-parsed, which evicted trace2
      // So now cache has trace3 and trace1
      expect(identical(result3First, parser.parseCallChain(trace3)), true);
    });

    test('cache respects LRU access time updates', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enableStackTraceCache: true,
        maxStackTraceCacheSize: 2, // Very small cache for testing
      );
      final parser = StackTraceParser(config);

      // Use custom stack traces with unique content
      final trace1 = StackTrace.fromString(
        '#0 functionA (package:test_app/fileA.dart:11:5)\n'
        '#1 functionB (package:test_app/fileB.dart:21:5)',
      );
      final trace2 = StackTrace.fromString(
        '#0 functionC (package:test_app/fileC.dart:31:5)\n'
        '#1 functionD (package:test_app/fileD.dart:41:5)',
      );
      final trace3 = StackTrace.fromString(
        '#0 functionE (package:test_app/fileE.dart:51:5)\n'
        '#1 functionF (package:test_app/fileF.dart:61:5)',
      );

      // Parse traces 1 and 2 - both cached
      final result1First = parser.parseCallChain(trace1);
      final result2First = parser.parseCallChain(trace2);

      // Access trace 1 again to update its access time
      parser.parseCallChain(trace1);

      // Parse trace 3 - should evict trace 2 (not trace 1, since we just accessed it)
      parser.parseCallChain(trace3);

      // Re-parse trace 1 - should still be cached
      final result1Second = parser.parseCallChain(trace1);
      expect(identical(result1First, result1Second), true);

      // Re-parse trace 2 - should be evicted (new instance)
      final result2Second = parser.parseCallChain(trace2);
      expect(identical(result2First, result2Second), false);
    });

    test('copyWith preserves cache configuration', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enableStackTraceCache: true,
        maxStackTraceCacheSize: 100,
      );

      final modified = config.copyWith(
        enableConsoleOutput: false,
      );

      expect(modified.enableStackTraceCache, true);
      expect(modified.maxStackTraceCacheSize, 100);
    });

    test('copyWith can modify cache configuration', () {
      final config = TrackerConfig.forPackage('test_app');

      final modified = config.copyWith(
        enableStackTraceCache: false,
        maxStackTraceCacheSize: 200,
      );

      expect(modified.enableStackTraceCache, false);
      expect(modified.maxStackTraceCacheSize, 200);
    });
  });
}
