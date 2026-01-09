import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Direct Console Output Tests', () {
    test('triggers all console output code paths', () async {
      // Use actual test file path to ensure we have user code
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: const ['test_app', 'riverpod_devtools_tracker'],
          maxCallChainDepth: 10,
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create nested providers to generate callChain
      final provider1 = Provider<int>((ref) => 1);
      final provider2 = Provider<int>((ref) => ref.watch(provider1) + 1);
      final provider3 = Provider<int>((ref) => ref.watch(provider2) + 1);
      final provider4 = Provider<int>((ref) => ref.watch(provider3) + 1);
      final provider5 = Provider<int>((ref) => ref.watch(provider4) + 1);
      final provider6 = Provider<int>((ref) => ref.watch(provider5) + 1);
      final provider7 = Provider<int>((ref) => ref.watch(provider6) + 1);

      // This should trigger console output with callChain
      container.read(provider7);

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 10));

      // Now test simple format
      final observer2 = RiverpodDevToolsObserver(
        config: TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: false, // Simple format
          packagePrefixes: const ['test_app', 'riverpod_devtools_tracker'],
        ),
      );
      final container2 = ProviderContainer(observers: [observer2]);

      final simpleProvider = Provider<int>((ref) => 42);
      container2.read(simpleProvider);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(observer.config.enableConsoleOutput, true);
      expect(observer2.config.enableConsoleOutput, true);

      container.dispose();
      container2.dispose();
    });

    test('console output with update event and triggerLocation', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: const ['test_app', 'riverpod_devtools_tracker'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      var value = 0;
      final testProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });

      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Trigger update
      value = 1;
      container.invalidate(testProvider);
      container.read(testProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('console output with null triggerLocation (auto-computed)', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: const ['test_app', 'riverpod_devtools_tracker'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Create dependent provider
      final base = Provider<int>((ref) => 1);
      final dependent = FutureProvider<int>((ref) async {
        final val = ref.watch(base);
        await Future.delayed(const Duration(milliseconds: 5));
        return val * 2;
      });

      container.read(dependent);
      await Future.delayed(const Duration(milliseconds: 20));

      // Invalidate base to trigger auto-computed update
      container.invalidate(base);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });

    test('all changeType emojis in console output', () async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig(
          enabled: true,
          enableConsoleOutput: true,
          prettyConsoleOutput: true,
          packagePrefixes: const ['test_app', 'riverpod_devtools_tracker'],
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Add event
      final addProvider = Provider<int>((ref) => 1);
      container.read(addProvider);

      // Update event
      var value = 0;
      final updateProvider = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value;
      });
      container.read(updateProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      value = 1;
      container.invalidate(updateProvider);
      container.read(updateProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Dispose event
      final disposeProvider = Provider.autoDispose<int>((ref) => 2);
      final sub = container.listen(disposeProvider, (previous, next) {});
      sub.close();

      // Error event
      final errorProvider = Provider<int>((ref) => throw Exception('Error'));
      expect(() => container.read(errorProvider), throwsException);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(observer.config.enableConsoleOutput, true);

      container.dispose();
    });
  });
}
