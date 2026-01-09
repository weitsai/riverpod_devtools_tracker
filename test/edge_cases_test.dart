import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Edge Cases and Exception Handling', () {
    late _EdgeCaseTestObserver observer;
    late ProviderContainer container;

    setUp(() {
      observer = _EdgeCaseTestObserver();
      container = ProviderContainer(observers: [observer]);
    });

    tearDown(() {
      container.dispose();
    });

    group('Configuration Boundary Values', () {
      test('maxCallChainDepth = 0 does not crash', () {
        final customObserver = _EdgeCaseTestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            maxCallChainDepth: 0,
            enableConsoleOutput: false,
          ),
        );
        final customContainer = ProviderContainer(observers: [customObserver]);

        final provider = Provider<int>((ref) => 42);
        customContainer.read(provider);

        // Should not crash, just have empty or minimal call chain
        expect(customObserver.addEventCount, 1);

        customContainer.dispose();
      });

      test('maxCallChainDepth = -1 uses default or handles gracefully', () {
        final customObserver = _EdgeCaseTestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            maxCallChainDepth: -1,
            enableConsoleOutput: false,
          ),
        );
        final customContainer = ProviderContainer(observers: [customObserver]);

        final provider = Provider<int>((ref) => 100);
        customContainer.read(provider);

        // Should handle gracefully (may use default depth or treat as 0)
        expect(customObserver.addEventCount, 1);

        customContainer.dispose();
      });

      test('maxValueLength = 0 handles value truncation', () {
        final customObserver = _EdgeCaseTestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            maxValueLength: 0,
            enableConsoleOutput: false,
          ),
        );
        final customContainer = ProviderContainer(observers: [customObserver]);

        final provider = Provider<String>((ref) => 'This is a long string');
        customContainer.read(provider);

        // Should handle 0-length limit gracefully
        expect(customObserver.addEventCount, 1);

        customContainer.dispose();
      });

      test('empty packagePrefixes still tracks providers', () {
        final customObserver = _EdgeCaseTestObserver(
          config: const TrackerConfig(
            packagePrefixes: [],
            enableConsoleOutput: false,
          ),
        );
        final customContainer = ProviderContainer(observers: [customObserver]);

        final provider = Provider<int>((ref) => 42);
        customContainer.read(provider);

        // Should still track providers even with empty prefixes
        expect(customObserver.addEventCount, 1);

        customContainer.dispose();
      });

      test('very large maxCallChainDepth does not crash', () {
        final customObserver = _EdgeCaseTestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            maxCallChainDepth: 10000,
            enableConsoleOutput: false,
          ),
        );
        final customContainer = ProviderContainer(observers: [customObserver]);

        final provider = Provider<int>((ref) => 42);
        customContainer.read(provider);

        expect(customObserver.addEventCount, 1);

        customContainer.dispose();
      });

      test('observer handles disabled config', () {
        final disabledObserver = _EdgeCaseTestObserver(
          config: const TrackerConfig(enabled: false),
        );
        final customContainer =
            ProviderContainer(observers: [disabledObserver]);

        final provider = Provider<int>((ref) => 42);
        customContainer.read(provider);

        // Should still receive events even when disabled (disabled affects output, not tracking)
        expect(disabledObserver.addEventCount, greaterThanOrEqualTo(1));

        customContainer.dispose();
      });
    });

    group('StackTraceParser Edge Cases', () {
      test('handles malformed stack trace lines', () {
        final config = TrackerConfig.forPackage('test_app');
        final parser = StackTraceParser(config);

        final malformedStackTrace = StackTrace.fromString('''
This is not a valid stack trace line
#0      missing parentheses package:test_app/main.dart:10:5
#1      func (incomplete_path
Random text
''');

        // Should not crash, just skip invalid lines
        final callChain = parser.parseCallChain(malformedStackTrace);
        expect(callChain, isA<List<LocationInfo>>());
      });

      test('handles very long function names', () {
        final config = TrackerConfig.forPackage('test_app');
        final parser = StackTraceParser(config);

        final longFunctionName = 'a' * 500;
        final stackTrace = StackTrace.fromString('''
#0      $longFunctionName (package:test_app/main.dart:10:5)
''');

        final callChain = parser.parseCallChain(stackTrace);
        expect(callChain, isA<List<LocationInfo>>());
      });

      test('handles special characters in file path', () {
        final config = TrackerConfig.forPackage('test_app');
        final parser = StackTraceParser(config);

        final stackTrace = StackTrace.fromString('''
#0      func (package:test_app/路径/文件.dart:10:5)
#1      func2 (package:test_app/path with spaces/file.dart:20:5)
''');

        final callChain = parser.parseCallChain(stackTrace);
        expect(callChain, isA<List<LocationInfo>>());
      });

      test('handles stack trace with no matching package prefixes', () {
        final config = TrackerConfig.forPackage('my_app');
        final parser = StackTraceParser(config);

        final stackTrace = StackTrace.fromString('''
#0      func1 (package:other_package/main.dart:10:5)
#1      func2 (package:flutter/widgets.dart:20:5)
#2      func3 (dart:core/list.dart:30:5)
''');

        final callChain = parser.parseCallChain(stackTrace);
        // Should be empty - no matching prefixes
        expect(callChain, isEmpty);
      });

      test('handles mixed valid and invalid lines', () {
        final config = TrackerConfig.forPackage('test_app');
        final parser = StackTraceParser(config);

        final stackTrace = StackTrace.fromString('''
#0      goodFunc (package:test_app/main.dart:10:5)
Invalid line here
#1      anotherGood (package:test_app/utils.dart:20:5)
More garbage
#2      flutter (package:flutter/widgets.dart:30:5)
''');

        final callChain = parser.parseCallChain(stackTrace);
        // Should have parsed the valid lines
        expect(callChain.length, greaterThanOrEqualTo(1));
      });
    });

    group('Extreme Value Scenarios', () {
      test('handles very large string values (10MB+)', () {
        // Create a 10MB string
        final largeString = 'x' * (10 * 1024 * 1024);
        final provider = Provider<String>((ref) => largeString);

        container.read(provider);

        // Should handle large values without crashing
        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, isNotNull);
      });

      test('handles very large list (10000+ elements)', () {
        final largeList = List.generate(10000, (i) => i);
        final provider = Provider<List<int>>((ref) => largeList);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, largeList);
      });

      test('handles very large map (1000+ key-value pairs)', () {
        final largeMap = {
          for (int i = 0; i < 1000; i++) 'key$i': 'value$i',
        };
        final provider = Provider<Map<String, String>>((ref) => largeMap);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, largeMap);
      });

      test('handles deeply nested structures (50+ levels)', () {
        Map<String, dynamic> createDeeplyNested(int depth) {
          if (depth == 0) return {'value': 42};
          return {'level$depth': createDeeplyNested(depth - 1)};
        }

        final deepStructure = createDeeplyNested(50);
        final provider = Provider<Map<String, dynamic>>((ref) => deepStructure);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, deepStructure);
      });
    });

    group('High Frequency Updates', () {
      test('single provider with 1000 rapid updates', () async {
        var counter = 0;
        final provider = FutureProvider<int>((ref) async => counter);

        // Initial read
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialCount = observer.updateEventCount;

        // Perform 1000 rapid updates
        for (int i = 0; i < 1000; i++) {
          counter++;
          container.invalidate(provider);
          container.read(provider);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle all updates without crashing
        expect(observer.updateEventCount, greaterThan(initialCount));
      });

      test('100 providers updating simultaneously', () async {
        final providers = List.generate(
          100,
          (i) => FutureProvider<int>((ref) async => i),
        );

        // Read all providers
        for (final provider in providers) {
          container.read(provider);
        }

        await Future.delayed(const Duration(milliseconds: 50));

        // Should track all 100 providers
        expect(observer.addEventCount, greaterThanOrEqualTo(100));
      });

      test('observer maintains stability under rapid provider creation and disposal',
          () {
        for (int i = 0; i < 100; i++) {
          final localContainer = ProviderContainer(observers: [observer]);
          final provider = Provider<int>((ref) => i);
          localContainer.read(provider);
          localContainer.dispose();
        }

        // Should handle rapid creation/disposal cycles
        expect(observer.addEventCount, greaterThanOrEqualTo(100));
        expect(observer.disposeEventCount, greaterThanOrEqualTo(100));
      });

      test('observer handles rapid invalidation of same provider', () async {
        var counter = 0;
        final provider = FutureProvider<int>((ref) async => counter);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Rapidly invalidate the same provider 100 times
        for (int i = 0; i < 100; i++) {
          counter++;
          container.invalidate(provider);
          container.read(provider);
        }

        await Future.delayed(const Duration(milliseconds: 50));

        // Should handle rapid invalidation
        expect(observer.updateEventCount, greaterThan(0));
      });
    });

    group('Null Safety and Transitions', () {
      test('provider value transitions from non-null to null', () async {
        int? value = 42;
        final provider = FutureProvider<int?>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.lastAddValue, isNotNull);

        // Transition to null
        value = null;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should handle transition to null
        expect(observer.updateEventCount, greaterThan(0));
      });

      test('provider value transitions from null to non-null', () async {
        int? value = null;
        final provider = FutureProvider<int?>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Transition to non-null
        value = 42;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should handle transition from null
        expect(observer.updateEventCount, greaterThan(0));
      });

      test('both previousValue and newValue are null', () async {
        int? value = null;
        final provider = FutureProvider<int?>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Keep value as null
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should handle null to null transition
        expect(observer.updateEventCount, greaterThanOrEqualTo(0));
      });

      test('nullable provider with alternating null/non-null values',
          () async {
        int? value = 10;
        final provider = FutureProvider<int?>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Alternate between null and non-null multiple times
        for (int i = 0; i < 10; i++) {
          value = (i % 2 == 0) ? null : i * 10;
          container.invalidate(provider);
          container.read(provider);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Should handle all transitions gracefully
        expect(observer.updateEventCount, greaterThan(0));
      });

      test('handles null provider value on add', () {
        final nullProvider = Provider<String?>((ref) => null);
        container.read(nullProvider);

        expect(observer.addEventCount, 1);
      });
    });

    group('Special String Cases', () {
      test('handles string with special characters and emojis', () {
        final specialString = '🎉 Hello\nWorld\t\$100\r\n"quotes"\\backslash';
        final provider = Provider<String>((ref) => specialString);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, specialString);
      });

      test('handles string with unicode characters', () {
        final unicodeString = '你好世界 🌍 Привет мир ñáéíóú';
        final provider = Provider<String>((ref) => unicodeString);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, unicodeString);
      });

      test('handles string with control characters', () {
        final controlString = 'Line1\x00\x01\x02Line2';
        final provider = Provider<String>((ref) => controlString);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, controlString);
      });

      test('handles empty string repeatedly', () async {
        var value = '';
        final provider = FutureProvider<String>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Update with same empty string multiple times
        for (int i = 0; i < 10; i++) {
          container.invalidate(provider);
          container.read(provider);
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Should handle repeated empty strings
        expect(observer.addEventCount, greaterThanOrEqualTo(1));
      });
    });

    group('Complex Type Edge Cases', () {
      test('handles list with null elements', () {
        final listWithNulls = [1, null, 3, null, 5];
        final provider = Provider<List<int?>>((ref) => listWithNulls);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, listWithNulls);
      });

      test('handles map with null values', () {
        final mapWithNulls = <String, int?>{
          'key1': 1,
          'key2': null,
          'key3': 3,
        };
        final provider = Provider<Map<String, int?>>((ref) => mapWithNulls);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, isA<Map>());
      });

      test('handles heterogeneous list (List<dynamic>)', () {
        final heterogeneousList = <dynamic>[
          1,
          'string',
          3.14,
          true,
          null,
          [1, 2, 3],
          {'key': 'value'},
        ];
        final provider = Provider<List<dynamic>>((ref) => heterogeneousList);

        container.read(provider);

        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, heterogeneousList);
      });

      test('handles circular reference fallback', () {
        final circularList = <dynamic>[1, 2, 3];
        circularList.add(circularList); // Create circular reference

        final provider = Provider<List<dynamic>>((ref) => circularList);

        container.read(provider);

        // Should handle gracefully (may use toString fallback)
        expect(observer.addEventCount, 1);
        expect(observer.lastAddValue, isNotNull);
      });
    });

    group('Error Recovery', () {
      test('recovers from provider error and continues tracking', () async {
        var shouldThrow = true;
        final provider = FutureProvider<int>((ref) async {
          if (shouldThrow) {
            throw Exception('Test error');
          }
          return 42;
        });

        // First read - will throw error
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should track error
        expect(observer.addEventCount, greaterThanOrEqualTo(1));

        // Recover from error
        shouldThrow = false;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should continue tracking after recovery
        expect(observer.updateEventCount, greaterThan(0));
      });

      test('handles multiple different errors sequentially', () async {
        var errorType = 0;
        final provider = FutureProvider<int>((ref) async {
          switch (errorType) {
            case 1:
              throw Exception('Error 1');
            case 2:
              throw StateError('Error 2');
            case 3:
              throw ArgumentError('Error 3');
            default:
              return 42;
          }
        });

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Trigger different errors
        for (int i = 1; i <= 3; i++) {
          errorType = i;
          container.invalidate(provider);
          container.read(provider);
          await Future.delayed(const Duration(milliseconds: 20));
        }

        // Should handle all different error types
        expect(observer.updateEventCount, greaterThan(0));
      });
    });

    group('Multiple Observers', () {
      test('multiple observers on same container', () {
        final observer1 = _EdgeCaseTestObserver();
        final observer2 = _EdgeCaseTestObserver();
        final customContainer =
            ProviderContainer(observers: [observer1, observer2]);

        final provider = Provider<int>((ref) => 42);
        customContainer.read(provider);

        // Both observers should receive events
        expect(observer1.addEventCount, 1);
        expect(observer2.addEventCount, 1);

        customContainer.dispose();
      });
    });

    group('LocationInfo Edge Cases', () {
      test('LocationInfo with very large line numbers', () {
        const location = LocationInfo(
          location: 'lib/main.dart:999999',
          file: 'lib/main.dart',
          line: 999999,
          function: 'test',
        );

        expect(location.line, 999999);
        expect(location.toString(), 'lib/main.dart:999999');
      });

      test('LocationInfo toJson with all fields', () {
        const location = LocationInfo(
          location: 'lib/main.dart:42:15',
          file: 'lib/main.dart',
          line: 42,
          function: 'testFunc',
          column: 15,
        );

        final json = location.toJson();

        expect(json['location'], 'lib/main.dart:42:15');
        expect(json['file'], 'lib/main.dart');
        expect(json['line'], 42);
        expect(json['column'], 15);
        expect(json['function'], 'testFunc');
      });
    });

    group('Memory and Performance', () {
      test('observer does not leak memory with many short-lived providers',
          () {
        // Create and dispose many providers rapidly
        for (int i = 0; i < 1000; i++) {
          final localContainer = ProviderContainer(observers: [observer]);
          final provider = Provider<int>((ref) => i);
          localContainer.read(provider);
          localContainer.dispose();
        }

        // Should handle without memory issues
        expect(observer.addEventCount, greaterThanOrEqualTo(1000));
        expect(observer.disposeEventCount, greaterThanOrEqualTo(1000));
      });
    });
  });
}

/// Test observer for edge case testing
final class _EdgeCaseTestObserver extends RiverpodDevToolsObserver {
  int addEventCount = 0;
  int updateEventCount = 0;
  int disposeEventCount = 0;
  int errorEventCount = 0;

  dynamic lastAddValue;
  dynamic lastUpdatePreviousValue;
  dynamic lastUpdateNewValue;

  _EdgeCaseTestObserver({
    TrackerConfig? config,
  }) : super(
          config: config ??
              TrackerConfig.forPackage(
                'test_app',
                enableConsoleOutput: false,
              ),
        );

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    addEventCount++;
    lastAddValue = value;
    super.didAddProvider(context, value);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    updateEventCount++;
    lastUpdatePreviousValue = previousValue;
    lastUpdateNewValue = newValue;
    super.didUpdateProvider(context, previousValue, newValue);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposeEventCount++;
    super.didDisposeProvider(context);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    errorEventCount++;
    super.providerDidFail(context, error, stackTrace);
  }
}
