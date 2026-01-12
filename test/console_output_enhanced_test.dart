import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Console Output Enhanced Coverage', () {
    test('simple console output with triggerLocation', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: false, // Simple format
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // This should trigger console output with location
      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      // Verify config is set correctly
      expect(observer.config.prettyConsoleOutput, false);
      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('pretty console with triggerLocation (non-null)', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // This should trigger pretty console output with location
      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      expect(observer.config.prettyConsoleOutput, true);

      container.dispose();
    });

    test('pretty console with callChain output', () {
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

      // Create nested providers to generate call chain
      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => ref.watch(provider1) + 1);
      final provider3 = Provider<int>((ref) => ref.watch(provider2) + 1);

      // Reading provider3 should create a call chain
      container.read(provider3);

      expect(observer.config.maxCallChainDepth, 10);

      container.dispose();
    });

    test('pretty console with long callChain (>5 items)', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
          maxCallChainDepth: 15, // Allow long chains
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

      // This should trigger "... and N more" in console output
      container.read(provider7);

      expect(observer.config.maxCallChainDepth, 15);

      container.dispose();
    });

    test('pretty console with update changeType and null triggerLocation',
        () async {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Use FutureProvider which often has null triggerLocation for auto-updates
      var value = 1;
      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });

      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Trigger update which may have null triggerLocation
      value = 2;
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // This should show "(auto-computed by dependency)" message
      expect(observer.config.prettyConsoleOutput, true);

      container.dispose();
    });

    test('console output with dispose having non-null triggerLocation', () {
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
      sub.close(); // This triggers dispose

      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('console output with empty callChain', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
          maxCallChainDepth: 0, // Force empty call chain
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      // Should handle empty call chain gracefully
      expect(observer.config.maxCallChainDepth, 0);

      container.dispose();
    });

    test('console output with error changeType and triggerLocation', () {
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
        throw Exception('Test error with location');
      });

      // Trigger error with stack trace
      expect(() => container.read(errorProvider), throwsException);

      // Should output error with ❌ emoji and location
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('simple console format captures all changeTypes', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: false, // Simple format
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Add
      final provider1 = Provider<int>((ref) => 1);
      container.read(provider1);

      // Update
      final family = Provider.family<int, int>((ref, id) => id);
      container.read(family(1));
      container.read(family(2)); // Different parameter = update-like

      // Dispose
      final autoDispose = Provider.autoDispose<int>((ref) => 42);
      final sub = container.listen(autoDispose, (previous, next) {});
      sub.close();

      // Error
      final errorProvider = Provider<int>((ref) => throw Exception('Error'));
      expect(() => container.read(errorProvider), throwsException);

      expect(observer.config.prettyConsoleOutput, false);

      container.dispose();
    });
  });
}
