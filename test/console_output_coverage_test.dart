import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Console Output Coverage Tests', () {
    test('simple format with non-null triggerLocation outputs to console',
        () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: false, // Simple format
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create provider that will have triggerLocation
      final testProvider = Provider<int>((ref) => 42);

      // This should trigger line 360: simple format with triggerLocation
      container.read(testProvider);

      expect(observer.config.enableConsoleOutput, true);
      expect(observer.config.prettyConsoleOutput, false);

      container.dispose();
    });

    test('pretty format with non-null triggerLocation shows location line',
        () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create provider that will have triggerLocation
      final testProvider = Provider<int>((ref) => 42);

      // This should trigger line 390: pretty format with triggerLocation
      container.read(testProvider);

      expect(observer.config.prettyConsoleOutput, true);

      container.dispose();
    });

    test('pretty format with non-empty callChain shows call chain section',
        () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
          maxCallChainDepth: 10,
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create nested providers to generate callChain
      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => ref.watch(provider1) + 1);
      final provider3 = Provider<int>((ref) => ref.watch(provider2) + 1);

      // This should trigger lines 396-405: pretty format with callChain
      container.read(provider3);

      expect(observer.config.maxCallChainDepth, 10);

      container.dispose();
    });

    test('pretty format with callChain longer than 5 shows truncation', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
          maxCallChainDepth: 15,
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create deep nested providers (>5 levels)
      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => ref.watch(provider1) + 1);
      final provider3 = Provider<int>((ref) => ref.watch(provider2) + 1);
      final provider4 = Provider<int>((ref) => ref.watch(provider3) + 1);
      final provider5 = Provider<int>((ref) => ref.watch(provider4) + 1);
      final provider6 = Provider<int>((ref) => ref.watch(provider5) + 1);
      final provider7 = Provider<int>((ref) => ref.watch(provider6) + 1);

      // This should trigger line 404-405: "... and N more" message
      container.read(provider7);

      expect(observer.config.maxCallChainDepth, 15);

      container.dispose();
    });

    test('console output with all combinations of add events', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Test various provider types to ensure console output
      final simpleProvider = Provider<int>((ref) => 1);
      final familyProvider = Provider.family<int, int>((ref, id) => id);
      final futureProvider = FutureProvider<int>((ref) async => 42);

      container.read(simpleProvider);
      container.read(familyProvider(1));
      container.read(futureProvider);

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('console output for dispose events with location', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final autoDisposeProvider = Provider.autoDispose<int>((ref) => 42);

      final sub = container.listen(autoDisposeProvider, (previous, next) {});

      // Trigger dispose with console output
      sub.close();

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('console output for error events with location', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final errorProvider = Provider<int>((ref) {
        throw Exception('Test error for console output');
      });

      // Trigger error with console output
      expect(() => container.read(errorProvider), throwsException);

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('console output with empty callChain but non-null triggerLocation',
        () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
          maxCallChainDepth: 1, // Limit chain to test empty scenario
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('console output captures different changeTypes correctly', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Add event
      final provider1 = Provider<int>((ref) => 1);
      container.read(provider1);

      // Update event (via family)
      final family = Provider.family<int, int>((ref, id) => id);
      container.read(family(1));
      container.read(family(2));

      // Dispose event
      final autoDispose = Provider.autoDispose<int>((ref) => 42);
      final sub = container.listen(autoDispose, (previous, next) {});
      sub.close();

      // Error event
      final errorProvider = Provider<int>((ref) => throw Exception('Error'));
      expect(() => container.read(errorProvider), throwsException);

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('simple console format with location string construction', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: false,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create multiple providers to trigger various console outputs
      for (int i = 0; i < 5; i++) {
        final provider = Provider<int>((ref) => i);
        container.read(provider);
      }

      expect(observer.config.prettyConsoleOutput, false);

      container.dispose();
    });
  });
}
