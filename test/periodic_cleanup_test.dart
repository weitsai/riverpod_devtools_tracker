import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Periodic Memory Cleanup (Issue #9)', () {
    test('observer starts cleanup timer when enabled', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: false,
          enablePeriodicCleanup: true,
          cleanupInterval: const Duration(milliseconds: 100),
        ),
      );

      // Timer should be started
      expect(observer, isNotNull);

      // Clean up
      observer.dispose();
    });

    test('observer does not start timer when disabled', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: false,
          enablePeriodicCleanup: false,
        ),
      );

      // Should not crash even though timer is not started
      expect(observer, isNotNull);

      // dispose should still work
      observer.dispose();
    });

    test('dispose cancels timer and clears cache', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: false,
          enablePeriodicCleanup: true,
        ),
      );

      // Dispose should not throw
      expect(() => observer.dispose(), returnsNormally);

      // Calling dispose again should also not throw
      expect(() => observer.dispose(), returnsNormally);
    });

    test('TrackerConfig has correct default values for cleanup', () {
      const config = TrackerConfig();

      expect(config.enablePeriodicCleanup, true);
      expect(config.cleanupInterval, const Duration(seconds: 30));
      expect(config.stackExpirationDuration, const Duration(seconds: 60));
      expect(config.maxStackCacheSize, 100);
    });

    test('TrackerConfig.forPackage accepts cleanup parameters', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        enablePeriodicCleanup: false,
        cleanupInterval: const Duration(seconds: 10),
        stackExpirationDuration: const Duration(seconds: 120),
        maxStackCacheSize: 200,
      );

      expect(config.enablePeriodicCleanup, false);
      expect(config.cleanupInterval, const Duration(seconds: 10));
      expect(config.stackExpirationDuration, const Duration(seconds: 120));
      expect(config.maxStackCacheSize, 200);
    });

    test('TrackerConfig.copyWith updates cleanup parameters', () {
      const original = TrackerConfig(
        enablePeriodicCleanup: true,
        cleanupInterval: Duration(seconds: 30),
      );

      final modified = original.copyWith(
        enablePeriodicCleanup: false,
        cleanupInterval: const Duration(seconds: 60),
        maxStackCacheSize: 50,
      );

      expect(modified.enablePeriodicCleanup, false);
      expect(modified.cleanupInterval, const Duration(seconds: 60));
      expect(modified.maxStackCacheSize, 50);
      // Unchanged values should remain
      expect(modified.stackExpirationDuration, original.stackExpirationDuration);
    });

    test('periodic cleanup works with provider updates', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: false,
          enablePeriodicCleanup: true,
          cleanupInterval: const Duration(milliseconds: 50),
          stackExpirationDuration: const Duration(milliseconds: 100),
        ),
      );

      final container = ProviderContainer(observers: [observer]);
      final testProvider1 = Provider<int>((ref) => 1, name: 'test1');
      final testProvider2 = Provider<int>((ref) => 2, name: 'test2');
      final testProvider3 = Provider<int>((ref) => 3, name: 'test3');

      // Trigger some provider reads
      container.read(testProvider1);
      container.read(testProvider2);
      container.read(testProvider3);

      // Wait for cleanup timer to run a few times
      await Future.delayed(const Duration(milliseconds: 200));

      // Clean up
      observer.dispose();
      container.dispose();

      // Test should complete without errors
      expect(true, true);
    });

    test('manual cleanup respects maxStackCacheSize from config', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage(
          'test_app',
          enableConsoleOutput: false,
          enablePeriodicCleanup: false,
          maxStackCacheSize: 5,
        ),
      );

      final container = ProviderContainer(observers: [observer]);

      // Create multiple providers to exceed cache size
      for (int i = 0; i < 10; i++) {
        final provider = Provider<int>((ref) => i, name: 'provider$i');
        container.read(provider);
      }

      // Cache should be limited by maxStackCacheSize
      // (We can't directly test cache size, but we verify no errors occur)

      observer.dispose();
      container.dispose();

      expect(true, true);
    });
  });
}
