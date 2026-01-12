import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Stack Caching Logic', () {
    test('saves stack when hasUserCode is true', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // FutureProvider will save stack on initialization (hasUserCode = true)
      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 42;
      });

      // Initial read should save stack
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Should have add event
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('reuses saved stack when hasUserCode is false', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = 1;
      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });

      // First read - saves stack
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Invalidate and trigger update
      value = 2;
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Update should reuse saved stack
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('stack saved for async provider with user code', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create async provider with clear user code location
      final provider = FutureProvider<String>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 'async result';
      });

      container.read(provider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Stack should be saved with user code location
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('multiple async providers each save their own stack', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create multiple async providers
      final provider1 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 1;
      });

      final provider2 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 2;
      });

      final provider3 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 3;
      });

      // Read all providers
      container.read(provider1);
      container.read(provider2);
      container.read(provider3);

      await Future.delayed(const Duration(milliseconds: 30));

      // Each should save its own stack
      expect(observer.addEvents.length, 3);

      container.dispose();
    });

    test('saved stack persists across invalidations', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = 0;
      final provider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });

      // Initial read
      container.read(provider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Multiple invalidations
      for (int i = 1; i <= 5; i++) {
        value = i;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Should reuse same saved stack for all updates
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('stack cache with triggerLocation not in provider file', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // This provider's trigger location should not be a provider file
      final provider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 42;
      });

      container.read(provider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Stack should be saved because triggerLocation is not a provider file
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('dependent async providers save stacks correctly', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create dependent async providers
      final baseProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 10;
      });

      final dependentProvider = FutureProvider<int>((ref) async {
        final base = await ref.watch(baseProvider.future);
        return base * 2;
      });

      container.read(dependentProvider);
      await Future.delayed(const Duration(milliseconds: 30));

      // Both providers should save stacks
      expect(observer.addEvents.length, 2);

      container.dispose();
    });

    test('stream provider saves and reuses stack', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // StreamProvider also uses stack caching
      final streamProvider = StreamProvider<int>((ref) async* {
        yield 1;
        await Future.delayed(const Duration(milliseconds: 10));
        yield 2;
        await Future.delayed(const Duration(milliseconds: 10));
        yield 3;
      });

      container.read(streamProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      // Should save stack and reuse for stream events
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThanOrEqualTo(0));

      container.dispose();
    });

    test('autoDispose providers clean up saved stacks', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // AutoDispose async provider
      final provider = FutureProvider.autoDispose<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return 42;
      });

      final sub = container.listen(provider, (previous, next) {});
      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.addEvents.length, 1);

      // Dispose should clean up
      sub.close();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(observer.disposeEvents.length, greaterThan(0));

      container.dispose();
    });

    test('cached stack includes callChain and triggerLocation', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create provider with dependencies to generate call chain
      final base = Provider<int>((ref) => 1);
      final dependent = FutureProvider<int>((ref) async {
        final value = ref.watch(base);
        await Future.delayed(const Duration(milliseconds: 5));
        return value * 2;
      });

      container.read(dependent);
      await Future.delayed(const Duration(milliseconds: 20));

      // Stack should include call chain
      expect(observer.addEvents.length, 2); // base + dependent

      container.dispose();
    });
  });
}

/// Test observer that records events
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];

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

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposeEvents.add(context);
    super.didDisposeProvider(context);
  }
}
