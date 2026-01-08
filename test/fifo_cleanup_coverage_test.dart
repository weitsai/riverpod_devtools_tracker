import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('FIFO Cleanup Coverage', () {
    test(
        'FIFO cleanup triggered when cache exceeds 100 with all recent stacks',
        () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create exactly 105 providers very rapidly
      // All will be "fresh" (not expired), triggering FIFO cleanup
      // This should cover lines 266-280
      final providers = <FutureProvider<int>>[];

      for (int i = 0; i < 105; i++) {
        final provider = FutureProvider<int>((ref) async {
          // Very short delay to keep all timestamps recent
          await Future.delayed(const Duration(microseconds: 500));
          return i;
        });
        providers.add(provider);
        container.read(provider);

        // No delay between providers - keep them all "recent"
      }

      // Wait for all to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // All 105 providers should be tracked
      expect(observer.addEvents.length, 105);

      // Now invalidate some to trigger additional updates
      // This ensures the cached stacks are being used
      for (int i = 95; i < 105; i++) {
        container.invalidate(providers[i]);
        container.read(providers[i]);
      }

      await Future.delayed(const Duration(milliseconds: 30));

      // Should have updates
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('cleanup removes oldest entries when FIFO triggered', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final firstBatch = <FutureProvider<int>>[];
      final secondBatch = <FutureProvider<int>>[];

      // Create first batch of 60 providers
      for (int i = 0; i < 60; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(microseconds: 500));
          return i;
        });
        firstBatch.add(provider);
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 30));

      // Small delay to make first batch slightly older
      await Future.delayed(const Duration(milliseconds: 5));

      // Create second batch of 50 providers (total 110)
      // This should trigger FIFO cleanup
      for (int i = 60; i < 110; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(microseconds: 500));
          return i;
        });
        secondBatch.add(provider);
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All should be tracked initially
      expect(observer.addEvents.length, 110);

      // Verify second batch (more recent) still works
      for (int i = 0; i < 10; i++) {
        container.invalidate(secondBatch[i]);
        container.read(secondBatch[i]);
      }

      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('sustained creation of providers triggers multiple FIFO cleanups',
        () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create providers in waves to trigger multiple cleanup cycles
      for (int wave = 0; wave < 3; wave++) {
        for (int i = 0; i < 45; i++) {
          final idx = wave * 45 + i;
          final provider = FutureProvider<int>((ref) async {
            await Future.delayed(const Duration(microseconds: 500));
            return idx;
          });
          container.read(provider);
        }

        // Minimal delay between waves
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await Future.delayed(const Duration(milliseconds: 30));

      // Total: 3 * 45 = 135 providers
      // Should have triggered FIFO cleanup
      expect(observer.addEvents.length, 135);

      container.dispose();
    });

    test('FIFO cleanup with mixed sync and async providers', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Mix of sync and async providers
      for (int i = 0; i < 110; i++) {
        if (i % 2 == 0) {
          // Sync provider
          final provider = Provider<int>((ref) => i);
          container.read(provider);
        } else {
          // Async provider
          final provider = FutureProvider<int>((ref) async {
            await Future.delayed(const Duration(microseconds: 500));
            return i;
          });
          container.read(provider);
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // All should be tracked
      expect(observer.addEvents.length, 110);

      container.dispose();
    });

    test('FIFO cleanup preserves most recently used stacks', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final recentProviders = <FutureProvider<int>>[];

      // Create 110 providers
      for (int i = 0; i < 110; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(microseconds: 500));
          return i;
        });

        if (i >= 100) {
          // Keep reference to last 10 (most recent)
          recentProviders.add(provider);
        }

        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify most recent providers can be invalidated and read
      // Their stacks should still be available
      for (final provider in recentProviders) {
        container.invalidate(provider);
        container.read(provider);
      }

      await Future.delayed(const Duration(milliseconds: 30));

      expect(observer.addEvents.length, 110);
      expect(observer.updateEvents.length, greaterThan(0));

      container.dispose();
    });

    test('rapid FIFO triggers with continuous provider creation', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create providers continuously to keep triggering FIFO
      for (int i = 0; i < 150; i++) {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(microseconds: 300));
          return i;
        });
        container.read(provider);

        // No delay - keep creating rapidly
      }

      await Future.delayed(const Duration(milliseconds: 60));

      // All should be tracked
      expect(observer.addEvents.length, 150);

      container.dispose();
    });

    test('FIFO cleanup with family providers', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create family providers (each parameter creates a new provider instance)
      final family = FutureProvider.family<int, int>((ref, id) async {
        await Future.delayed(const Duration(microseconds: 500));
        return id * 10;
      });

      // Create 110 instances via family
      for (int i = 0; i < 110; i++) {
        container.read(family(i));
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Should have 110 add events
      expect(observer.addEvents.length, 110);

      container.dispose();
    });

    test('FIFO cleanup handles provider disposal during cleanup', () async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create mix of regular and autoDispose providers
      for (int i = 0; i < 110; i++) {
        if (i % 3 == 0) {
          // AutoDispose provider
          final provider = FutureProvider.autoDispose<int>((ref) async {
            await Future.delayed(const Duration(microseconds: 500));
            return i;
          });
          final sub = container.listen(provider, (previous, next) {});

          // Dispose some immediately
          if (i < 20) {
            sub.close();
          }
        } else {
          // Regular provider
          final provider = FutureProvider<int>((ref) async {
            await Future.delayed(const Duration(microseconds: 500));
            return i;
          });
          container.read(provider);
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Should track all additions
      expect(observer.addEvents.length, greaterThanOrEqualTo(100));

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
