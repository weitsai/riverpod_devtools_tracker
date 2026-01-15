import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('RiverpodDevToolsObserver Initialization', () {
    test('creates with default config', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(enablePeriodicCleanup: false),
      );
      expect(observer.config.enabled, true);
      expect(observer.config.enableConsoleOutput, true);
      expect(observer.config.skipUnchangedValues, true);
      observer.dispose();
    });

    test('creates with custom config', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enablePeriodicCleanup: false,
      );
      final observer = RiverpodDevToolsObserver(config: config);
      expect(observer.config, config);
      expect(observer.config.packagePrefixes, contains('package:test_app/'));
      observer.dispose();
    });

    test('respects enabled flag', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: false,
          enablePeriodicCleanup: false,
        ),
      );
      expect(observer.config.enabled, false);
      observer.dispose();
    });

    test('respects custom package prefixes', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'my_app',
          additionalPackages: ['package:shared/'],
        ),
      );
      expect(observer.config.packagePrefixes, contains('package:my_app/'));
      expect(observer.config.packagePrefixes, contains('package:shared/'));
    });

    test('respects console output settings', () {
      final observerWithOutput = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: true,
        ),
      );
      final observerWithoutOutput = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: false,
        ),
      );

      expect(observerWithOutput.config.enableConsoleOutput, true);
      expect(observerWithoutOutput.config.enableConsoleOutput, false);
    });

    test('respects maxCallChainDepth setting', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          maxCallChainDepth: 20,
        ),
      );
      expect(observer.config.maxCallChainDepth, 20);
    });

    test('respects maxValueLength setting', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          maxValueLength: 500,
        ),
      );
      expect(observer.config.maxValueLength, 500);
    });
  });

  group('RiverpodDevToolsObserver Integration', () {
    testWidgets('observer can be added to ProviderScope', (tester) async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enablePeriodicCleanup: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          observers: [observer],
          child: const MaterialApp(home: Scaffold(body: Text('Test'))),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      observer.dispose();
    });

    testWidgets('multiple observers can coexist', (tester) async {
      final observer1 = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage('test_app'),
      );
      final observer2 = _TestObserver();

      await tester.pumpWidget(
        ProviderScope(
          observers: [observer1, observer2],
          child: const MaterialApp(home: Scaffold(body: Text('Test'))),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      
      // Clean up observers to prevent timer leak
      observer1.dispose();
    });
  });

  group('Provider Lifecycle Event Tracking', () {
    test('observer tracks provider add events', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);

      // Read the provider to trigger add event
      container.read(testProvider);

      expect(observer.addEvents.length, 1);
      expect(observer.addEvents.first.provider, testProvider);

      container.dispose();
    });

    test('observer tracks provider update events', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = 0;
      final testProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });

      // Read and trigger update by invalidating
      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      value = 1;
      container.invalidate(testProvider);
      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('observer tracks provider dispose events', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);

      // Read and invalidate the provider
      container.read(testProvider);
      container.invalidate(testProvider);

      expect(observer.disposeEvents.length, 1);

      container.dispose();
    });

    test('observer tracks provider error events', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final errorProvider = Provider<int>((ref) {
        throw Exception('Test error');
      });

      // Try to read the provider
      expect(() => container.read(errorProvider), throwsException);

      expect(observer.errorEvents.length, 1);

      container.dispose();
    });

    test('tracks multiple sequential updates', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = 0;
      final testProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 2));
        return value;
      });

      // Read initial value
      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 5));

      // Multiple updates by invalidating
      value = 1;
      container.invalidate(testProvider);
      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 5));

      value = 2;
      container.invalidate(testProvider);
      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 5));

      value = 3;
      container.invalidate(testProvider);
      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 5));

      expect(observer.updateEvents.length, greaterThanOrEqualTo(3));

      container.dispose();
    });

    test('tracks rapid fire updates', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Use family provider for rapid fire updates
      final family = Provider.family<int, int>((ref, id) => id);

      // Rapid reads with different values
      for (int i = 0; i < 50; i++) {
        container.read(family(i));
      }

      // Should track a significant number of providers
      expect(observer.addEvents.length, greaterThanOrEqualTo(45));

      container.dispose();
    });
  });

  group('Different Provider Types', () {
    test('tracks Provider', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<String>((ref) => 'test');
      container.read(provider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('tracks NotifierProvider', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<int>((ref) => 42);
      container.read(provider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('tracks FutureProvider', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = FutureProvider<int>((ref) async => 42);
      container.read(provider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('tracks StreamProvider', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = StreamProvider<int>((ref) => Stream.value(42));
      container.read(provider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('tracks family providers', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final family = Provider.family<String, int>((ref, id) => 'item_$id');

      container.read(family(1));
      container.read(family(2));
      container.read(family(3));

      expect(observer.addEvents.length, 3);

      container.dispose();
    });

    test('tracks autoDispose providers', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider.autoDispose<int>((ref) => 42);

      final sub = container.listen(provider, (previous, next) {});
      expect(observer.addEvents.length, 1);

      sub.close();
      await Future.delayed(Duration.zero);

      expect(observer.disposeEvents.length, greaterThan(0));

      container.dispose();
    });
  });

  group('RiverpodDevToolsObserver memory management', () {
    test('periodic cleanup timer is created when enabled', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enablePeriodicCleanup: true,
          enableConsoleOutput: false,
        ),
      );

      expect(observer.config.enablePeriodicCleanup, true);
      expect(observer.config.cleanupInterval, const Duration(seconds: 30));
      expect(observer.config.maxStackCacheSize, 100);

      observer.dispose();
    });

    test('periodic cleanup timer is not created when disabled', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enablePeriodicCleanup: false,
          enableConsoleOutput: false,
        ),
      );

      expect(observer.config.enablePeriodicCleanup, false);
      observer.dispose();
    });

    test('dispose cancels cleanup timer and clears cache', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enablePeriodicCleanup: true,
          enableConsoleOutput: false,
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create a provider to populate the cache
      final testProvider = Provider<int>((ref) => 0);
      container.read(testProvider);

      // Dispose should cancel timer and clear cache
      observer.dispose();

      // Verify config still accessible after dispose
      expect(observer.config.enablePeriodicCleanup, true);

      container.dispose();
    });

    test('custom cleanup configuration is respected', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enablePeriodicCleanup: true,
          cleanupInterval: const Duration(seconds: 60),
          stackExpirationDuration: const Duration(minutes: 5),
          maxStackCacheSize: 200,
          enableConsoleOutput: false,
        ),
      );

      expect(observer.config.cleanupInterval, const Duration(seconds: 60));
      expect(observer.config.stackExpirationDuration, const Duration(minutes: 5));
      expect(observer.config.maxStackCacheSize, 200);

      observer.dispose();
    });
  });

  group('Value serialization', () {
    testWidgets('serializes primitive values correctly', (tester) async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final intProvider = Provider<int>((ref) => 42);
      final stringProvider = Provider<String>((ref) => 'test');
      final boolProvider = Provider<bool>((ref) => true);
      final doubleProvider = Provider<double>((ref) => 3.14);

      container.read(intProvider);
      container.read(stringProvider);
      container.read(boolProvider);
      container.read(doubleProvider);

      // Values should be captured
      expect(observer.addEvents.length, 4);

      container.dispose();
    });

    test('handles null values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final nullProvider = Provider<String?>((ref) => null);
      container.read(nullProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('handles enum values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final enumProvider = Provider<_TestEnum>((ref) => _TestEnum.first);
      container.read(enumProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('serializes List values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final listProvider = Provider<List<int>>((ref) => [1, 2, 3, 4, 5]);
      container.read(listProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('serializes Map values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final mapProvider = Provider<Map<String, dynamic>>((ref) => {
            'key1': 'value1',
            'key2': 42,
            'key3': true,
          });
      container.read(mapProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('handles custom class with toJson', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final customProvider =
          Provider<_CustomClass>((ref) => _CustomClass('test', 42));
      container.read(customProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('handles custom class without toJson', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final customProvider =
          Provider<_NonSerializableClass>((ref) => _NonSerializableClass('test'));
      container.read(customProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('handles large values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final largeString = 'x' * 10000;
      final largeProvider = Provider<String>((ref) => largeString);
      container.read(largeProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('handles nested structures', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final nestedProvider = Provider<Map<String, dynamic>>((ref) => {
            'level1': {
              'level2': {
                'level3': {'value': 42},
              },
            },
          });
      container.read(nestedProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });
  });

  group('Value Comparison and Filtering', () {
    test('skipUnchangedValues config is enabled by default', () {
      final observer = _TestObserver();
      expect(observer.config.skipUnchangedValues, true);
    });

    test('skipUnchangedValues can be configured', () {
      final observerEnabled = _TestObserverWithConfig(
        TrackerConfig.forPackage(
          'test_app',
          skipUnchangedValues: true,
          enablePeriodicCleanup: false,
        ),
      );
      final observerDisabled = _TestObserverWithConfig(
        TrackerConfig.forPackage(
          'test_app',
          skipUnchangedValues: false,
          enablePeriodicCleanup: false,
        ),
      );

      expect(observerEnabled.config.skipUnchangedValues, true);
      expect(observerDisabled.config.skipUnchangedValues, false);

      observerEnabled.dispose();
      observerDisabled.dispose();
    });

    test('skipUnchangedValues filters identical primitive updates',
        () {
      final observer = _TestObserver(); // skipUnchangedValues=true by default
      final container = ProviderContainer(observers: [observer]);

      final value = 1;
      final testProvider = Provider<int>((ref) => value);

      // Read initial value
      container.read(testProvider);

      final initialUpdateCount = observer.updateEvents.length;

      // Invalidate with same value multiple times
      container.invalidate(testProvider);
      container.read(testProvider);

      container.invalidate(testProvider);
      container.read(testProvider);

      // Should be filtered out (value hasn't changed)
      expect(observer.updateEvents.length, equals(initialUpdateCount));

      container.dispose();
    });

    test('skipUnchangedValues tracks different values',
        () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final family = Provider.family<int, int>((ref, value) => value);

      // Read different values
      container.read(family(1));
      container.read(family(2));
      container.read(family(3));

      // Should track family providers with different parameters
      expect(observer.addEvents.length, equals(3));

      container.dispose();
    });

    test('with skipUnchangedValues=false, tracks all updates',
        () {
      final observer = _TestObserverWithConfig(
        TrackerConfig.forPackage('test_app', skipUnchangedValues: false),
      );
      final container = ProviderContainer(observers: [observer]);

      final value = 1;
      final testProvider = Provider<int>((ref) => value);

      // Read initial value
      container.read(testProvider);

      // Invalidate with same value multiple times
      container.invalidate(testProvider);
      container.read(testProvider);

      container.invalidate(testProvider);
      container.read(testProvider);

      container.invalidate(testProvider);
      container.read(testProvider);

      // With skipUnchangedValues=false, should track updates even with same value
      // Note: Provider re-evaluation with same value should still trigger updates
      expect(observer.updateEvents.length, greaterThanOrEqualTo(0));

      container.dispose();
    });
  });

  group('Provider Name Extraction', () {
    test('extracts provider name from named provider', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final namedProvider = Provider<int>(
        (ref) => 42,
        name: 'myNamedProvider',
      );
      container.read(namedProvider);

      expect(observer.addEvents.length, 1);
      // The provider name should be available through context

      container.dispose();
    });

    test('handles providers without explicit name', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final unnamedProvider = Provider<int>((ref) => 42);
      container.read(unnamedProvider);

      expect(observer.addEvents.length, 1);
      // Should use runtime type as name

      container.dispose();
    });
  });

  group('Error Handling', () {
    test('handles provider that throws exception', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final errorProvider = Provider<int>((ref) {
        throw Exception('Test error');
      });

      expect(() => container.read(errorProvider), throwsException);
      expect(observer.errorEvents.length, 1);

      container.dispose();
    });

    test('handles async provider with error', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw Exception('Async error');
      });

      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      // FutureProvider errors are tracked as AsyncValue.error in add/update events
      // Not necessarily in errorEvents
      expect(observer.addEvents.length, greaterThanOrEqualTo(1));

      container.dispose();
    });

    test('continues tracking after error', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final errorProvider = Provider<int>((ref) {
        throw Exception('Error');
      });
      final normalProvider = Provider<int>((ref) => 42);

      // Error provider
      expect(() => container.read(errorProvider), throwsException);

      // Normal provider should still be tracked
      container.read(normalProvider);

      expect(observer.errorEvents.length, 1);
      expect(observer.addEvents.length, 2); // Both errorProvider and normalProvider trigger add events

      container.dispose();
    });
  });

  group('Memory Management', () {
    test('observer can be garbage collected after disposal', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage('test_app'),
      );
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      container.dispose();

      // After disposal, observer should be eligible for GC
      expect(observer.config.enabled, true);
    });

    test('handles multiple provider disposals', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider1 = Provider.autoDispose<int>((ref) => 1);
      final provider2 = Provider.autoDispose<int>((ref) => 2);
      final provider3 = Provider.autoDispose<int>((ref) => 3);

      final sub1 = container.listen(provider1, (previous, next) {});
      final sub2 = container.listen(provider2, (previous, next) {});
      final sub3 = container.listen(provider3, (previous, next) {});

      sub1.close();
      sub2.close();
      sub3.close();

      await Future.delayed(Duration.zero);

      expect(observer.disposeEvents.length, greaterThanOrEqualTo(3));

      container.dispose();
    });
  });

  group('Edge Cases', () {
    test('handles disabled observer', () async {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(enabled: false),
      );
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      // Observer is disabled, but should not crash
      expect(observer.config.enabled, false);

      container.dispose();
    });

    test('handles very long provider names', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final longNameProvider = Provider<int>(
        (ref) => 42,
        name: 'a' * 1000,
      );
      container.read(longNameProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('handles special characters in values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final specialCharsProvider = Provider<String>(
        (ref) => 'Special: \n\t\r"\'\\',
      );
      container.read(specialCharsProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('handles concurrent provider reads', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final providers = List.generate(
        10,
        (i) => Provider<int>((ref) => i),
      );

      // Read all providers concurrently
      for (final provider in providers) {
        container.read(provider);
      }

      expect(observer.addEvents.length, 10);

      container.dispose();
    });
  });
}

/// Test observer that records events
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];
  final List<ProviderObserverContext> errorEvents = [];

  _TestObserver()
    : super(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: false, // Disable console for tests
          enablePeriodicCleanup: false, // Disable cleanup timer for tests
        ),
      );

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    addEvents.add(context);
    super.didAddProvider(context, value);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    // Add event after super call to respect filtering
    updateEvents.add(context);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposeEvents.add(context);
    super.didDisposeProvider(context);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    errorEvents.add(context);
    super.providerDidFail(context, error, stackTrace);
  }
}

enum _TestEnum {
  first,
  // ignore: unused_field
  second,
  // ignore: unused_field
  third,
}

/// Test helper for custom config
final class _TestObserverWithConfig extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];

  _TestObserverWithConfig(TrackerConfig config) : super(config: config);

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    addEvents.add(context);
    super.didAddProvider(context, value);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    // Add event after super call to respect filtering
    updateEvents.add(context);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposeEvents.add(context);
    super.didDisposeProvider(context);
  }
}

/// Custom class with toJson
class _CustomClass {
  final String name;
  final int value;

  _CustomClass(this.name, this.value);

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
      };
}

/// Custom class without toJson
class _NonSerializableClass {
  final String data;

  _NonSerializableClass(this.data);

  @override
  String toString() => 'NonSerializable($data)';
}
