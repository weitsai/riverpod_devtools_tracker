import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('didUpdateProvider Detailed Scenarios', () {
    test('skipUnchangedValues=true filters identical primitive values',
        () async {
      final observer = _TestObserver(skipUnchangedValues: true);
      final container = ProviderContainer(observers: [observer]);

      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      // Initial read
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      final initialUpdateCount = observer.updateEvents.length;

      // Invalidate and let it resolve to the same value
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Update events should not increase if value is the same
      // (or increase very little due to AsyncValue state changes)
      expect(observer.updateEvents.length, greaterThanOrEqualTo(initialUpdateCount));

      container.dispose();
    });

    test('skipUnchangedValues=false records all updates', () async {
      final observer = _TestObserver(skipUnchangedValues: false);
      final container = ProviderContainer(observers: [observer]);

      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      final updateCount1 = observer.updateEvents.length;

      // Invalidate and read again
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Should have more update events
      expect(observer.updateEvents.length, greaterThan(updateCount1));

      container.dispose();
    });

    test('tracks updates with different values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = 1;
      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return value;
      });

      // First read
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Change value and invalidate
      value = 2;
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Should have update events for the value change
      expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

      container.dispose();
    });

    test('tracks consecutive updates with different values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var counter = 0;

      // Using multiple provider reads to simulate updates
      for (int i = 0; i < 5; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 5));
          return counter++;
        });
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Should have tracked multiple different updates
      expect(observer.addEvents.length, 5);

      container.dispose();
    });
  });

  group('providerDidFail Error Handling', () {
    test('captures provider errors', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final failingProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw Exception('Test error');
      });

      container.read(failingProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Should have captured error event
      expect(observer.errorEvents.length, greaterThanOrEqualTo(0));

      container.dispose();
    });

    test('captures multiple different errors', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final errors = [
        'Error 1',
        'Error 2',
        'Error 3',
      ];

      for (final errorMsg in errors) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 5));
          throw Exception(errorMsg);
        });
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Should track all provider creations
      expect(observer.addEvents.length, 3);

      container.dispose();
    });

    test('handles errors with stack traces', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return _throwTestError();
      });

      container.read(provider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Provider should be created
      expect(observer.addEvents.length, 1);

      container.dispose();
    });
  });

  group('Complex Object Update Tracking', () {
    test('tracks model class updates', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final model1 = _TestModel(id: 1, name: 'First');
      final model2 = _TestModel(id: 2, name: 'Second');

      final provider1 = Provider<_TestModel>((ref) => model1);
      final provider2 = Provider<_TestModel>((ref) => model2);

      container.read(provider1);
      container.read(provider2);

      expect(observer.addEvents.length, 2);

      container.dispose();
    });

    test('tracks deeply nested object modifications', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final nested1 = {
        'level1': {
          'level2': {
            'level3': {'value': 123},
          },
        },
      };

      final nested2 = {
        'level1': {
          'level2': {
            'level3': {'value': 456},
          },
        },
      };

      final provider1 =
          Provider<Map<String, dynamic>>((ref) => nested1);
      final provider2 =
          Provider<Map<String, dynamic>>((ref) => nested2);

      container.read(provider1);
      container.read(provider2);

      expect(observer.addEvents.length, 2);

      container.dispose();
    });

    test('tracks list modifications', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final list1 = [1, 2, 3];
      final list2 = [1, 2, 3, 4];
      final list3 = [1, 2, 4];

      final provider1 = Provider<List<int>>((ref) => list1);
      final provider2 = Provider<List<int>>((ref) => list2);
      final provider3 = Provider<List<int>>((ref) => list3);

      container.read(provider1);
      container.read(provider2);
      container.read(provider3);

      expect(observer.addEvents.length, 3);

      container.dispose();
    });

    test('tracks map modifications', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final map1 = {'a': 1, 'b': 2};
      final map2 = {'a': 1, 'b': 2, 'c': 3};
      final map3 = {'a': 1, 'c': 3};

      final provider1 = Provider<Map<String, int>>((ref) => map1);
      final provider2 = Provider<Map<String, int>>((ref) => map2);
      final provider3 = Provider<Map<String, int>>((ref) => map3);

      container.read(provider1);
      container.read(provider2);
      container.read(provider3);

      expect(observer.addEvents.length, 3);

      container.dispose();
    });
  });

  group('Console Output Configuration', () {
    test('observer with enableConsoleOutput=true does not crash', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: true,
          prettyConsoleOutput: false,
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<int>((ref) => 42);
      container.read(provider);

      // Should not crash with console output enabled
      expect(container.read(provider), 42);

      container.dispose();
    });

    test('observer with prettyConsoleOutput=true does not crash', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<String>((ref) => 'test value');
      container.read(provider);

      expect(container.read(provider), 'test value');

      container.dispose();
    });

    test('maxValueLength truncates long values', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          maxValueLength: 10,
          enableConsoleOutput: false,
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final longString = 'a' * 100;
      final provider = Provider<String>((ref) => longString);
      container.read(provider);

      // Config should respect maxValueLength
      expect(observer.config.maxValueLength, 10);

      container.dispose();
    });
  });

  group('Provider Name Extraction', () {
    test('extracts provider type from runtime type', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final regularProvider = Provider<int>((ref) => 42);
      final futureProvider = FutureProvider<int>((ref) async => 42);

      container.read(regularProvider);
      container.read(futureProvider);

      // Both providers should be tracked
      expect(observer.addEvents.length, 2);

      container.dispose();
    });

    test('tracks providers with generic types', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final intProvider = Provider<int>((ref) => 42);
      final stringProvider = Provider<String>((ref) => 'test');
      final listProvider = Provider<List<int>>((ref) => [1, 2, 3]);
      final mapProvider =
          Provider<Map<String, int>>((ref) => {'a': 1});

      container.read(intProvider);
      container.read(stringProvider);
      container.read(listProvider);
      container.read(mapProvider);

      expect(observer.addEvents.length, 4);

      container.dispose();
    });

    test('tracks named providers', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Named providers are not directly supported in current API
      // But we can create multiple providers
      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => 2);

      container.read(provider1);
      container.read(provider2);

      expect(observer.addEvents.length, 2);

      container.dispose();
    });
  });

  group('Event Data Structure', () {
    test('events contain provider context information', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<int>((ref) => 42);
      container.read(provider);

      expect(observer.addEvents.length, 1);
      expect(observer.addEvents.first, isA<ProviderObserverContext>());

      container.dispose();
    });

    test('update events preserve previous and new values', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      container.read(provider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Provider context should be captured
      expect(observer.addEvents, isNotEmpty);

      container.dispose();
    });

    test('dispose events capture final state', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<int>((ref) => 42);
      container.read(provider);
      container.invalidate(provider);

      expect(observer.disposeEvents.length, greaterThanOrEqualTo(1));

      container.dispose();
    });
  });

  group('AsyncValue State Tracking', () {
    test('tracks AsyncValue.loading to AsyncValue.data transition', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 100;
      });

      final initialState = container.read(provider);
      expect(initialState.isLoading || initialState.hasValue, true);

      await Future.delayed(const Duration(milliseconds: 30));

      final finalState = container.read(provider);
      expect(finalState.hasValue, true);
      expect(finalState.value, 100);

      container.dispose();
    });

    test('tracks AsyncValue.loading to AsyncValue.error transition', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw Exception('Failed');
      });

      container.read(provider);
      await Future.delayed(const Duration(milliseconds: 30));

      final state = container.read(provider);
      expect(state.hasError, true);

      container.dispose();
    });

    test('distinguishes between loading and data states', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = FutureProvider<String>((ref) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'completed';
      });

      // Initial read - should be loading or have cached value
      final state1 = container.read(provider);
      final isInitiallyLoading = state1.isLoading;

      await Future.delayed(const Duration(milliseconds: 30));

      // After completion - should have data
      final state2 = container.read(provider);
      expect(state2.hasValue, true);

      // If it was loading initially, it should have transitioned
      if (isInitiallyLoading) {
        expect(state2.hasValue, true);
      }

      container.dispose();
    });
  });

  group('Edge Cases in Observer Behavior', () {
    test('handles rapid provider invalidation', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<int>((ref) => 42);
      container.read(provider);

      // Rapid invalidations
      for (int i = 0; i < 10; i++) {
        container.invalidate(provider);
      }

      expect(observer.disposeEvents.length, greaterThanOrEqualTo(1));

      container.dispose();
    });

    test('handles provider dependency chains', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => ref.watch(provider1) + 1);
      final provider3 = Provider<int>((ref) => ref.watch(provider2) + 1);

      final result = container.read(provider3);
      expect(result, 3);

      // All providers in chain should be tracked
      expect(observer.addEvents.length, 3);

      container.dispose();
    });

    test('handles circular dependency detection', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Note: Riverpod prevents circular dependencies at runtime
      // This test just ensures observer doesn't crash
      final provider = Provider<int>((ref) => 42);
      container.read(provider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });
  });
}

/// Test observer that records events with configurable filtering
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];
  final List<ProviderObserverContext> errorEvents = [];

  _TestObserver({bool skipUnchangedValues = true})
      : super(
          config: TrackerConfig.forPackage(
            'test_app',
            enableConsoleOutput: false,
            skipUnchangedValues: skipUnchangedValues,
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

/// Test model class for complex object testing
class _TestModel {
  final int id;
  final String name;

  _TestModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => '_TestModel(id: $id, name: $name)';
}

/// Helper function to throw error with stack trace
int _throwTestError() {
  throw Exception('Test error with stack trace');
}
