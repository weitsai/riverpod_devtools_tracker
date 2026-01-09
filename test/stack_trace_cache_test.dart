import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/src/stack_trace_parser.dart';
import 'package:riverpod_devtools_tracker/src/tracker_config.dart';

void main() {
  group('Stack Trace Parser Cache', () {
    late StackTraceParser parser;
    late TrackerConfig config;

    setUp(() {
      // Clear cache before each test
      StackTraceParser.clearCache();

      config = TrackerConfig.forPackage('test_app', enableConsoleOutput: false);
      parser = StackTraceParser(config);
    });

    tearDown(() {
      // Clean up after each test
      StackTraceParser.clearCache();
    });

    test('parseCallChain caches results', () {
      // Create a mock stack trace
      final stackTrace = StackTrace.fromString('''
#0      testFunction (package:test_app/test.dart:10:5)
#1      anotherFunction (package:test_app/another.dart:20:10)
#2      thirdFunction (package:test_app/third.dart:30:15)
''');

      // First call should parse and cache
      final result1 = parser.parseCallChain(stackTrace);
      final stats1 = StackTraceParser.getCacheStats();

      expect(result1.length, 3);
      expect(stats1['callChain'], 1);

      // Second call should return from cache
      final result2 = parser.parseCallChain(stackTrace);
      final stats2 = StackTraceParser.getCacheStats();

      expect(result2.length, 3);
      expect(stats2['callChain'], 1); // Still 1, not 2

      // Results should be identical (same list instance from cache)
      expect(identical(result1, result2), true);
    });

    test('findTriggerLocation caches results', () {
      final stackTrace = StackTrace.fromString('''
#0      testFunction (package:test_app/test.dart:10:5)
#1      providerFunction (package:test_app/providers/user_provider.dart:20:10)
#2      anotherFunction (package:test_app/another.dart:30:15)
''');

      // First call should parse and cache
      final result1 = parser.findTriggerLocation(stackTrace);
      final stats1 = StackTraceParser.getCacheStats();

      expect(result1, isNotNull);
      // Note: _shortenFilePath removes the package prefix
      expect(result1!.file, 'test.dart');
      expect(stats1['triggerLocation'], 1);

      // Second call should return from cache
      final result2 = parser.findTriggerLocation(stackTrace);
      final stats2 = StackTraceParser.getCacheStats();

      expect(result2, isNotNull);
      expect(stats2['triggerLocation'], 1); // Still 1, not 2

      // Results should be identical (same instance from cache)
      expect(identical(result1, result2), true);
    });

    test('cache handles different stack traces', () {
      final stackTrace1 = StackTrace.fromString('''
#0      function1 (package:test_app/file1.dart:10:5)
''');

      final stackTrace2 = StackTrace.fromString('''
#0      function2 (package:test_app/file2.dart:20:10)
''');

      // Parse both traces
      final result1 = parser.parseCallChain(stackTrace1);
      final result2 = parser.parseCallChain(stackTrace2);

      // Both should be cached
      final stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 2);

      // Results should be different
      expect(result1.length, 1);
      expect(result2.length, 1);
      // Note: _shortenFilePath removes the package prefix
      expect(result1.first.file, 'file1.dart');
      expect(result2.first.file, 'file2.dart');
    });

    test('cache clears when limit is exceeded', () {
      // Generate more than _maxCacheSize (500) stack traces
      for (int i = 0; i < 501; i++) {
        final stackTrace = StackTrace.fromString('''
#0      function$i (package:test_app/file$i.dart:10:5)
''');
        parser.parseCallChain(stackTrace);
      }

      // Cache should have been cleared and now has only 1 entry (the 501st)
      final stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 1);
    });

    test('clearCache empties both caches', () {
      final stackTrace = StackTrace.fromString('''
#0      testFunction (package:test_app/test.dart:10:5)
''');

      // Add entries to both caches
      parser.parseCallChain(stackTrace);
      parser.findTriggerLocation(stackTrace);

      var stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 1);
      expect(stats['triggerLocation'], 1);

      // Clear caches
      StackTraceParser.clearCache();

      stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 0);
      expect(stats['triggerLocation'], 0);
    });

    test('cache improves performance on repeated calls', () {
      final stackTrace = StackTrace.fromString('''
#0      function1 (package:test_app/file1.dart:10:5)
#1      function2 (package:test_app/file2.dart:20:10)
#2      function3 (package:test_app/file3.dart:30:15)
#3      function4 (package:test_app/file4.dart:40:20)
#4      function5 (package:test_app/file5.dart:50:25)
''');

      // First call (cold - will parse)
      final stopwatch1 = Stopwatch()..start();
      final result1 = parser.parseCallChain(stackTrace);
      stopwatch1.stop();
      final time1 = stopwatch1.elapsedMicroseconds;

      // Second call (hot - from cache)
      final stopwatch2 = Stopwatch()..start();
      final result2 = parser.parseCallChain(stackTrace);
      stopwatch2.stop();
      final time2 = stopwatch2.elapsedMicroseconds;

      // Cached call should be significantly faster
      // Note: This is a simple check; actual speedup depends on system
      expect(result1, equals(result2));
      expect(time2, lessThan(time1));

      // Print times for visibility in test output
      print('First call (cold): ${time1}μs');
      print('Second call (cached): ${time2}μs');
      print('Speedup: ${(time1 / time2).toStringAsFixed(2)}x');
    });

    test('cache handles null trigger location', () {
      // Stack trace with only framework code (will return null)
      final stackTrace = StackTrace.fromString('''
#0      frameworkFunction (package:flutter/lib.dart:10:5)
#1      anotherFrameworkFunction (dart:async/zone.dart:20:10)
''');

      // First call
      final result1 = parser.findTriggerLocation(stackTrace);
      expect(result1, isNull);

      // Second call (should be cached)
      final result2 = parser.findTriggerLocation(stackTrace);
      expect(result2, isNull);

      // Should still have cached the null result
      final stats = StackTraceParser.getCacheStats();
      expect(stats['triggerLocation'], 1);
    });

    test('cache handles empty call chain', () {
      // Stack trace that will be completely filtered out
      final stackTrace = StackTrace.fromString('''
#0      frameworkFunction (package:flutter/lib.dart:10:5)
''');

      // First call
      final result1 = parser.parseCallChain(stackTrace);
      expect(result1, isEmpty);

      // Second call (should be cached)
      final result2 = parser.parseCallChain(stackTrace);
      expect(result2, isEmpty);

      // Should have cached the empty result
      final stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 1);
    });

    test('getCacheStats returns correct counts', () {
      final trace1 = StackTrace.fromString('#0 f1 (package:test_app/f1.dart:1:1)');
      final trace2 = StackTrace.fromString('#0 f2 (package:test_app/f2.dart:1:1)');
      final trace3 = StackTrace.fromString('#0 f3 (package:test_app/f3.dart:1:1)');

      // Add to call chain cache
      parser.parseCallChain(trace1);
      parser.parseCallChain(trace2);

      // Add to trigger location cache
      // Note: findTriggerLocation internally calls parseCallChain, so trace3 will also be in callChain cache
      parser.findTriggerLocation(trace3);

      final stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 3); // All 3 traces are in call chain cache
      expect(stats['triggerLocation'], 1);
    });

    test('cache is shared across parser instances', () {
      final stackTrace = StackTrace.fromString('''
#0      testFunction (package:test_app/test.dart:10:5)
''');

      // First parser instance
      final parser1 = StackTraceParser(config);
      final result1 = parser1.parseCallChain(stackTrace);

      // Second parser instance should use same cache
      final parser2 = StackTraceParser(config);
      final result2 = parser2.parseCallChain(stackTrace);

      // Should return cached result
      expect(identical(result1, result2), true);

      // Cache should only have 1 entry
      final stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 1);
    });

    test('cache handles malformed stack traces', () {
      final invalidStackTrace = StackTrace.fromString('invalid stack trace format');

      // Should not crash, should return empty result
      final result = parser.parseCallChain(invalidStackTrace);
      expect(result, isEmpty);

      // Should still cache the result
      final stats = StackTraceParser.getCacheStats();
      expect(stats['callChain'], 1);

      // Second call should return same result from cache
      final result2 = parser.parseCallChain(invalidStackTrace);
      expect(result2, isEmpty);
      expect(identical(result, result2), true);
    });
  });
}
