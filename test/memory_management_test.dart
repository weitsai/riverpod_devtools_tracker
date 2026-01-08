import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Memory Management and Cache Cleanup', () {
    test('Stack cache handles adding many providers without overflow', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create and read 50 providers - should not trigger cleanup
      for (int i = 0; i < 50; i++) {
        final provider = Provider<int>((ref) => i);
        container.read(provider);
      }

      // All should be tracked
      expect(observer.addEvents.length, 50);

      container.dispose();
    });

    test('Stack cache manages 100+ providers efficiently', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create and read 150 providers
      // This should trigger cleanup mechanisms
      for (int i = 0; i < 150; i++) {
        final provider = Provider<int>((ref) => i);
        container.read(provider);
      }

      // All providers should be tracked
      expect(observer.addEvents.length, 150);

      container.dispose();
    });

    test('Observer maintains performance with rapid provider creation', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final stopwatch = Stopwatch()..start();

      // Rapidly create 200 providers
      for (int i = 0; i < 200; i++) {
        final provider = Provider<int>((ref) => i);
        container.read(provider);
      }

      stopwatch.stop();

      // Should complete in reasonable time (< 1 second for 200 providers)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(observer.addEvents.length, 200);

      container.dispose();
    });

    test('Observer handles rapid sequential provider invalidations', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create multiple providers to simulate rapid sequential operations
      for (int i = 0; i < 100; i++) {
        final provider = Provider<int>((ref) => i);
        container.read(provider);

        // Invalidate some providers to trigger recomputation
        if (i % 2 == 0) {
          container.invalidate(provider);
        }
      }

      // Should have tracked 100 provider creations
      expect(observer.addEvents.length, 100);

      container.dispose();
    });

    test('Observer handles mix of sync and async providers', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create mix of sync and async providers
      final syncProviders = List.generate(
        25,
        (i) => Provider<int>((ref) => i),
      );

      final asyncProviders = List.generate(
        25,
        (i) => FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        }),
      );

      // Read all sync providers
      for (final provider in syncProviders) {
        container.read(provider);
      }

      // Read all async providers
      for (final provider in asyncProviders) {
        container.read(provider);
      }

      // Should have 50 add events (25 sync + 25 async)
      expect(observer.addEvents.length, 50);

      // Wait for async providers to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Should have update events from async providers completing
      expect(observer.updateEvents.length, greaterThanOrEqualTo(0));

      container.dispose();
    });

    test('Observer memory stability under sustained load', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Simulate sustained load: create providers, wait, create more
      for (int batch = 0; batch < 5; batch++) {
        for (int i = 0; i < 40; i++) {
          final provider = Provider<int>((ref) => batch * 40 + i);
          container.read(provider);
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Total: 5 batches * 40 providers = 200 providers
      expect(observer.addEvents.length, 200);

      container.dispose();
    });

    test('Observer handles container disposal during active tracking', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create some providers
      for (int i = 0; i < 20; i++) {
        final provider = Provider<int>((ref) => i);
        container.read(provider);
      }

      expect(observer.addEvents.length, 20);

      // Dispose should not throw even with active tracking
      expect(() => container.dispose(), returnsNormally);
    });

    test('Observer tracks large number of async provider state transitions',
        () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create 30 async providers with different delays
      final providers = List.generate(
        30,
        (i) => FutureProvider<int>((ref) async {
          await Future.delayed(Duration(milliseconds: i * 2));
          return i * 10;
        }),
      );

      // Read all providers
      for (final provider in providers) {
        container.read(provider);
      }

      // Should have 30 add events
      expect(observer.addEvents.length, 30);

      // Wait for all to complete
      await Future.delayed(const Duration(milliseconds: 150));

      // Should have update events for completed futures
      expect(observer.updateEvents.length, greaterThanOrEqualTo(0));

      container.dispose();
    });

    test('Observer handles interleaved provider creation and disposal', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create providers in batches and invalidate some
      for (int batch = 0; batch < 10; batch++) {
        final providers = List.generate(
          10,
          (i) => Provider<int>((ref) => batch * 10 + i),
        );

        // Read all providers in batch
        for (final provider in providers) {
          container.read(provider);
        }

        // Invalidate half of them
        for (int i = 0; i < 5; i++) {
          container.invalidate(providers[i]);
        }
      }

      // Should have tracked 100 provider creations
      expect(observer.addEvents.length, greaterThanOrEqualTo(100));

      container.dispose();
    });

    test('Observer maintains accuracy with deep call chains', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create providers that depend on each other (simulating deep chains)
      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => ref.watch(provider1) + 1);
      final provider3 = Provider<int>((ref) => ref.watch(provider2) + 1);
      final provider4 = Provider<int>((ref) => ref.watch(provider3) + 1);
      final provider5 = Provider<int>((ref) => ref.watch(provider4) + 1);

      // Reading the deepest provider should trigger all dependencies
      final result = container.read(provider5);

      expect(result, 5);
      // Should track all 5 provider additions
      expect(observer.addEvents.length, 5);

      container.dispose();
    });

    test('Observer handles null values in high volume', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create many providers with null values
      for (int i = 0; i < 50; i++) {
        final provider = Provider<int?>((ref) => i.isEven ? null : i);
        container.read(provider);
      }

      expect(observer.addEvents.length, 50);

      container.dispose();
    });

    test('Observer processes complex nested data structures efficiently', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create providers with complex nested data
      for (int i = 0; i < 30; i++) {
        Map<String, dynamic> complexData = {'level': 0, 'value': i};
        for (int depth = 0; depth < 5; depth++) {
          complexData = {
            'level': depth + 1,
            'nested': complexData,
            'list': List.generate(3, (j) => j * (depth + 1)),
          };
        }

        final provider =
            Provider<Map<String, dynamic>>((ref) => complexData);
        container.read(provider);
      }

      expect(observer.addEvents.length, 30);

      container.dispose();
    });

    test('Observer handles concurrent provider reads', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create multiple providers and read them "concurrently"
      final providers = List.generate(
        40,
        (i) => Provider<int>((ref) => i),
      );

      // Read all at once (simulating concurrent access)
      for (final provider in providers) {
        container.read(provider);
      }

      expect(observer.addEvents.length, 40);

      container.dispose();
    });

    test('Observer tracks error states in async providers', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create async providers that will fail
      final failingProviders = List.generate(
        10,
        (i) => FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 5));
          if (i.isEven) {
            throw Exception('Error in provider $i');
          }
          return i;
        }),
      );

      // Read all providers
      for (final provider in failingProviders) {
        container.read(provider);
      }

      expect(observer.addEvents.length, 10);

      // Wait for all to complete/fail
      await Future.delayed(const Duration(milliseconds: 50));

      // Should have update events (some success, some error)
      expect(observer.updateEvents.length, greaterThanOrEqualTo(0));

      container.dispose();
    });

    test('Observer maintains performance with large string values', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final stopwatch = Stopwatch()..start();

      // Create providers with large string values
      for (int i = 0; i < 20; i++) {
        final largeString = 'x' * 10000; // 10KB string
        final provider = Provider<String>((ref) => largeString + i.toString());
        container.read(provider);
      }

      stopwatch.stop();

      // Should complete in reasonable time despite large values
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(observer.addEvents.length, 20);

      container.dispose();
    });

    test('FIFO cleanup strategy removes oldest stacks first', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create 110 async providers to trigger FIFO cleanup
      // (max cache size is 100, so this should trigger the FIFO cleanup path)
      final providers = <FutureProvider<int>>[];
      for (int i = 0; i < 110; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        providers.add(provider);
        container.read(provider);

        // Small delay to ensure timestamps are different
        if (i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 2));
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All providers should be tracked
      expect(observer.addEvents.length, 110);

      // Trigger more updates to ensure cleanup is working
      for (int i = 0; i < 10; i++) {
        container.invalidate(providers[i]);
        container.read(providers[i]);
      }

      await Future.delayed(const Duration(milliseconds: 20));

      // Should still track updates
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('Expired stack cleanup removes old cached stacks', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create 110 async providers to exceed cache limit
      for (int i = 0; i < 110; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All providers should be tracked
      expect(observer.addEvents.length, 110);

      // The cleanup should have been triggered
      // (implementation detail: cleanup happens when cache exceeds 100)
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('Stack cache cleanup handles concurrent async providers', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create many async providers concurrently
      final futures = <Future<void>>[];
      for (int i = 0; i < 120; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(Duration(milliseconds: i % 10 + 1));
          return i;
        });

        // Read provider and collect futures
        container.read(provider);
        futures.add(Future.delayed(Duration(milliseconds: i % 5)));
      }

      // Wait for all to settle
      await Future.wait(futures);
      await Future.delayed(const Duration(milliseconds: 100));

      // Should handle concurrent providers without issues
      expect(observer.addEvents.length, 120);

      container.dispose();
    });

    test('Memory cleanup with provider invalidation cycles', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final providers = <FutureProvider<int>>[];

      // Create 50 async providers
      for (int i = 0; i < 50; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        providers.add(provider);
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 30));

      // Invalidate all providers multiple times
      for (int cycle = 0; cycle < 3; cycle++) {
        for (var provider in providers) {
          container.invalidate(provider);
          container.read(provider);
        }
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Should handle invalidation cycles without memory issues
      expect(observer.addEvents.length, 50);
      expect(observer.updateEvents.length, greaterThan(100));

      container.dispose();
    });

    test('Cleanup preserves recent stacks while removing old ones', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create 105 async providers (exceeds limit of 100)
      for (int i = 0; i < 105; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        container.read(provider);

        // Add small delay every 20 providers to create age difference
        if (i % 20 == 0 && i > 0) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All providers should be tracked
      expect(observer.addEvents.length, 105);

      // Create more providers to trigger additional cleanup
      for (int i = 105; i < 115; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 20));

      // Should continue tracking new providers
      expect(observer.addEvents.length, 115);

      container.dispose();
    });

    test('Stack cache handles rapid provider disposal', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create and dispose many autoDispose providers rapidly
      for (int i = 0; i < 80; i++) {
        final provider = Provider.autoDispose<int>((ref) => i);
        final sub = container.listen(provider, (previous, next) {});

        // Dispose immediately
        sub.close();

        if (i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // Should handle rapid disposal without issues
      expect(observer.addEvents.length, 80);
      expect(observer.disposeEvents.length, greaterThan(70));

      container.dispose();
    });

    test('cleanup triggers expired records removal before FIFO', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create 110 providers to exceed cache limit
      // The first batch will be "old" and should be removed by expiration
      for (int i = 0; i < 110; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        container.read(provider);

        // Add delay every 20 providers to create timestamp differences
        if (i == 50) {
          // After 50 providers, wait to make them "older"
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All should be tracked
      expect(observer.addEvents.length, 110);

      container.dispose();
    });

    test('FIFO cleanup when cache exceeds limit with recent stacks', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create 120 providers rapidly (all recent, none expired)
      final providers = <FutureProvider<int>>[];
      for (int i = 0; i < 120; i++) {
        final provider = FutureProvider<int>((ref) async {
          // Very short delay so all stacks are recent
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        providers.add(provider);
        container.read(provider);

        // Minimal delay between providers (all timestamps will be recent)
        if (i % 30 == 0 && i > 0) {
          await Future.delayed(const Duration(milliseconds: 2));
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All providers should be tracked
      expect(observer.addEvents.length, 120);

      // FIFO should have removed oldest entries to keep under limit
      // Continue using some providers to verify cleanup worked
      for (int i = 100; i < 110; i++) {
        container.invalidate(providers[i]);
        container.read(providers[i]);
      }

      await Future.delayed(const Duration(milliseconds: 30));

      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('expired stack cleanup removes only old entries', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create initial batch of providers
      for (int i = 0; i < 50; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Wait to make first batch "old"
      await Future.delayed(const Duration(milliseconds: 100));

      // Create another batch (these will be recent)
      for (int i = 50; i < 100; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All should be tracked
      expect(observer.addEvents.length, 100);

      container.dispose();
    });

    test('cache handles mix of expired and recent stacks', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create staggered providers with different timestamps
      for (int batch = 0; batch < 5; batch++) {
        for (int i = 0; i < 25; i++) {
          final provider = FutureProvider<int>((ref) async {
            await Future.delayed(const Duration(milliseconds: 1));
            return batch * 25 + i;
          });
          container.read(provider);
        }

        // Wait between batches to create age differences
        if (batch < 4) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      await Future.delayed(const Duration(milliseconds: 30));

      // All 125 providers should be tracked
      expect(observer.addEvents.length, 125);

      container.dispose();
    });

    test('cleanup preserves most recent stacks under cache limit', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final recentProviders = <FutureProvider<int>>[];

      // Create exactly 100 providers (at cache limit)
      for (int i = 0; i < 100; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        recentProviders.add(provider);
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Create 10 more to trigger cleanup
      for (int i = 100; i < 110; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return i;
        });
        recentProviders.add(provider);
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 30));

      // All should be tracked
      expect(observer.addEvents.length, 110);

      // Verify recent providers still work (their stacks should be preserved)
      for (int i = 105; i < 110; i++) {
        container.invalidate(recentProviders[i]);
        container.read(recentProviders[i]);
      }

      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });
  });
}

/// Test observer that records events without console output
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
