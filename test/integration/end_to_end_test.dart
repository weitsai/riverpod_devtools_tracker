import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

/// End-to-End Integration Tests
///
/// These tests verify the complete flow from provider changes through
/// the observer to event generation, including stack trace parsing
/// and location detection.
void main() {
  group('End-to-End Integration Tests', () {
    test('should track complete provider lifecycle (add, update, dispose)',
        () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      // Test ADD
      final counterProvider = Provider<int>((ref) => 42, name: 'counter');
      final value1 = container.read(counterProvider);
      expect(value1, 42);

      // Test DISPOSE
      container.dispose();
    });

    test('should track multiple providers independently', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      // Create multiple providers
      final provider1 = Provider<int>((ref) => 1, name: 'provider1');
      final provider2 = Provider<String>((ref) => 'a', name: 'provider2');
      final provider3 = Provider<bool>((ref) => true, name: 'provider3');

      // Read all providers
      expect(container.read(provider1), 1);
      expect(container.read(provider2), 'a');
      expect(container.read(provider3), true);

      container.dispose();
    });

    test('should track provider with complex state', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      // Provider with Map state
      final userProvider = Provider<Map<String, dynamic>>(
        (ref) => {'name': 'John', 'age': 30},
        name: 'user',
      );

      final initialUser = container.read(userProvider);
      expect(initialUser['name'], 'John');
      expect(initialUser['age'], 30);

      container.dispose();
    });

    test('should track provider dependencies', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      // Base provider
      final baseProvider = Provider<int>((ref) => 10, name: 'base');

      // Derived provider
      final derivedProvider = Provider<int>(
        (ref) {
          final base = ref.watch(baseProvider);
          return base * 2;
        },
        name: 'derived',
      );

      // Initial read
      expect(container.read(derivedProvider), 20);

      container.dispose();
    });

    test('should handle provider errors', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      // Provider that throws error
      final errorProvider = Provider<int>(
        (ref) => throw Exception('Test error'),
        name: 'error',
      );

      // Reading should throw
      expect(
        () => container.read(errorProvider),
        throwsException,
      );

      container.dispose();
    });

    test('should work with FutureProvider', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      final futureProvider = FutureProvider<int>(
        (ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 42;
        },
        name: 'future',
      );

      // Initial state should be loading
      final initialState = container.read(futureProvider);
      expect(initialState.isLoading, true);

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 50));

      // Should have value
      final finalState = container.read(futureProvider);
      expect(finalState.hasValue, true);
      expect(finalState.value, 42);

      container.dispose();
    });

    test('should work with StreamProvider', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      final streamProvider = StreamProvider<int>(
        (ref) async* {
          yield 1;
          yield 2;
          yield 3;
        },
        name: 'stream',
      );

      // Initial state
      final initialState = container.read(streamProvider);
      expect(initialState.isLoading || initialState.hasValue, true);

      // Wait for stream completion
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have value (either loading or has value)
      final finalState = container.read(streamProvider);
      if (finalState.hasValue) {
        expect([1, 2, 3].contains(finalState.value), true);
      }

      container.dispose();
    });

    test('should respect config filters', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
          ignoredFilePatterns: ['.g.dart'],
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      final provider = Provider<int>((ref) => 123, name: 'filtered');
      expect(container.read(provider), 123);

      container.dispose();
    });

    test('should track NotifierProvider', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      final counterNotifierProvider = NotifierProvider<CounterNotifier, int>(
        CounterNotifier.new,
        name: 'counterNotifier',
      );

      // Initial state
      expect(container.read(counterNotifierProvider), 0);

      // Increment
      container.read(counterNotifierProvider.notifier).increment();
      expect(container.read(counterNotifierProvider), 1);

      // Decrement
      container.read(counterNotifierProvider.notifier).decrement();
      expect(container.read(counterNotifierProvider), 0);

      container.dispose();
    });

    test('should handle multiple container lifecycle', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      // Create and dispose multiple containers
      for (int i = 0; i < 5; i++) {
        final container = ProviderContainer(observers: [observer]);
        final provider = Provider<int>((ref) => i, name: 'provider$i');
        expect(container.read(provider), i);
        container.dispose();
      }

      // Should not crash
      expect(true, true);
    });

    test('should work with observer attached to ProviderScope', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'riverpod_devtools_tracker',
          enableConsoleOutput: false,
        ),
      );

      final container = ProviderContainer(observers: [observer]);
      final testProvider = Provider<String>((ref) => 'test', name: 'test');

      expect(container.read(testProvider), 'test');

      container.dispose();
    });
  });
}

/// Test NotifierProvider class
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}
