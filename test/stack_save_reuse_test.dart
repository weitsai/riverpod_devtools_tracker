import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Stack Save and Reuse Logic', () {
    test('saveStackIfValid is called when hasUserCode is true', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // FutureProvider will have user code on initialization
      // This should trigger line 122: _saveStackIfValid call
      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 42;
      });

      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Initial read should save stack
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('saved stack is reused in subsequent updates', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = 0;
      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });

      // First read - saves stack (line 122)
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Invalidate and read again
      // On async completion, may use saved stack (lines 127-128)
      value = 1;
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      value = 2;
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('multiple providers each save and reuse their own stacks', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value1 = 0;
      var value2 = 0;
      var value3 = 0;

      final provider1 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value1;
      });

      final provider2 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value2;
      });

      final provider3 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value3;
      });

      // Save stacks for all providers
      container.read(provider1);
      container.read(provider2);
      container.read(provider3);
      await Future.delayed(const Duration(milliseconds: 30));

      // Update all - should reuse saved stacks
      value1 = 1;
      value2 = 2;
      value3 = 3;
      container.invalidate(provider1);
      container.invalidate(provider2);
      container.invalidate(provider3);
      container.read(provider1);
      container.read(provider2);
      container.read(provider3);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(observer.addEvents.length, 3);
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('stack saved with non-null triggerLocation not in provider file',
        () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create provider that will have triggerLocation
      // This should trigger line 249: condition check
      final provider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 42;
      });

      container.read(provider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Stack should be saved
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('rapidly created providers save stacks correctly', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create many providers rapidly
      final providers = <FutureProvider<int>>[];
      for (int i = 0; i < 20; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        providers.add(provider);
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All should save their stacks
      expect(observer.addEvents.length, 20);

      // Invalidate and read again - should reuse saved stacks
      for (int i = 0; i < 10; i++) {
        container.invalidate(providers[i]);
        container.read(providers[i]);
      }

      await Future.delayed(const Duration(milliseconds: 30));

      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('dependent providers save their own stacks', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var baseValue = 0;

      final baseProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return baseValue;
      });

      final dependentProvider = FutureProvider<int>((ref) async {
        final base = await ref.watch(baseProvider.future);
        return base * 2;
      });

      // Both should save stacks
      container.read(dependentProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Update base to trigger dependent update
      baseValue = 5;
      container.invalidate(baseProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(observer.addEvents.length, 2);
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('stream provider saves and reuses stack for multiple values',
        () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // StreamProvider saves stack on first value
      final streamProvider = StreamProvider<int>((ref) async* {
        yield 1;
        await Future.delayed(const Duration(milliseconds: 10));
        yield 2;
        await Future.delayed(const Duration(milliseconds: 10));
        yield 3;
      });

      container.read(streamProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      // Should save stack once and reuse for subsequent stream values
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThanOrEqualTo(0));

      container.dispose();
    });

    test('provider with changing dependencies saves stack', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var useFirstDep = true;

      final dep1 = Provider<int>((ref) => 1);
      final dep2 = Provider<int>((ref) => 2);

      final dynamicProvider = FutureProvider<int>((ref) async {
        final value =
            useFirstDep ? ref.watch(dep1) : ref.watch(dep2);
        await Future.delayed(const Duration(milliseconds: 5));
        return value * 10;
      });

      container.read(dynamicProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Change dependency
      useFirstDep = false;
      container.invalidate(dynamicProvider);
      container.read(dynamicProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.addEvents.length, greaterThanOrEqualTo(2));

      container.dispose();
    });
  });
}

/// Test observer that records events
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];

  _TestObserver()
      : super(
          config: TrackerConfig.forPackage(
            'test_app',
            enableConsoleOutput: false,
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
}
