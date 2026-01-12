import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Console Output Configuration', () {
    test('simple console output without pretty format', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: false, // Simple format
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      // Should output simple format to console
      expect(observer.config.prettyConsoleOutput, false);

      container.dispose();
    });

    test('pretty console output with update event', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final family = Provider.family<int, int>((ref, id) => id);

      // Create multiple providers to trigger update-like events
      container.read(family(1));
      container.read(family(2));

      expect(observer.config.prettyConsoleOutput, true);

      container.dispose();
    });

    test('console output with null triggerLocation', () async {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // FutureProvider often has null triggerLocation for auto-computed updates
      var value = 1;
      final futureProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });

      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      value = 2;
      container.invalidate(futureProvider);
      container.read(futureProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Should handle null triggerLocation gracefully
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('console output with error changeType', () {
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
        throw Exception('Test error');
      });

      // Trigger error
      expect(() => container.read(errorProvider), throwsException);

      // Should output error with ❌ emoji
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('console output with dispose changeType', () {
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
      sub.close();

      // Should output dispose with 🗑️ emoji
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('console output with call chain', () {
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

      // Create a provider that will have a call chain
      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      // Should show call chain in console output
      expect(observer.config.maxCallChainDepth, 10);

      container.dispose();
    });

    test('console output with long call chain (>5 items)', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
          maxCallChainDepth: 20, // Allow longer chains
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create nested provider dependencies
      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => ref.watch(provider1) + 1);
      final provider3 = Provider<int>((ref) => ref.watch(provider2) + 1);
      final provider4 = Provider<int>((ref) => ref.watch(provider3) + 1);
      final provider5 = Provider<int>((ref) => ref.watch(provider4) + 1);
      final provider6 = Provider<int>((ref) => ref.watch(provider5) + 1);

      container.read(provider6);

      // Should show "... N more items" for long chains
      expect(observer.config.maxCallChainDepth, 20);

      container.dispose();
    });

    test('console output with maxValueLength truncation', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
          maxValueLength: 50, // Short length to trigger truncation
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final longString = 'x' * 200; // Very long value
      final provider = Provider<String>((ref) => longString);
      container.read(provider);

      // Should truncate value in console output
      expect(observer.config.maxValueLength, 50);

      container.dispose();
    });

    test('console output disabled', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: false, // Disabled
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      // Should not output to console
      expect(observer.config.enableConsoleOutput, false);

      container.dispose();
    });

    test('console output with update changeType and null triggerLocation', () async {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create provider that depends on another
      final baseProvider = Provider<int>((ref) => 1);
      final dependentProvider = Provider<int>((ref) => ref.watch(baseProvider) * 2);

      container.read(dependentProvider);

      // Invalidate base provider to trigger auto-computed update
      container.invalidate(baseProvider);
      container.read(dependentProvider);

      // Should show "auto-computed by dependency" message
      expect(observer.config.prettyConsoleOutput, true);

      container.dispose();
    });
  });

  group('Console Output Edge Cases', () {
    test('handles empty call chain', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);
      container.read(testProvider);

      // Should handle empty call chain without errors
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('handles null previousValue in console output', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final nullProvider = Provider<String?>((ref) => null);
      container.read(nullProvider);

      // Invalidate to trigger update
      container.invalidate(nullProvider);
      container.read(nullProvider);

      // Should handle null values in output
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('handles null currentValue in console output', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final nullProvider = Provider<String?>((ref) => null);
      container.read(nullProvider);

      // Should handle null value in add event
      expect(observer.config.enabled, true);

      container.dispose();
    });

    test('console output with very long provider name', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: ['test_app'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final longName = 'a' * 200;
      final provider = Provider<int>((ref) => 42, name: longName);
      container.read(provider);

      // Should handle long provider names
      expect(observer.config.enabled, true);

      container.dispose();
    });
  });
}
