import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

// Define some test providers (Riverpod 3 style)
final counterProvider = Provider<int>((ref) => 0, name: 'counterProvider');
final debugProvider = Provider<String>((ref) => 'debug', name: 'debugProvider');
final tempProvider = Provider<String>((ref) => 'temp', name: 'tempProvider');
final userProvider = Provider<String>((ref) => 'user', name: 'userProvider');

// Provider without explicit name (will use runtimeType)
final unnamedProvider = Provider<int>((ref) => 0);

void main() {
  group('TrackerConfig.forPackage with provider references', () {
    test('extracts names from provider references', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        ignoredProviders: [debugProvider, tempProvider],
      );

      expect(config.ignoredProviders, contains('debugProvider'));
      expect(config.ignoredProviders, contains('tempProvider'));
      expect(config.ignoredProviders.length, 2);
    });

    test('handles providers without explicit names', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        ignoredProviders: [unnamedProvider],
      );

      // Should fall back to runtimeType (without generic parameters)
      expect(config.ignoredProviders.isNotEmpty, true);
      expect(config.ignoredProviders.first, isNotEmpty);
    });

    test('handles mixed named and unnamed providers', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        trackedProviders: [counterProvider, unnamedProvider],
      );

      expect(config.trackedProviders, contains('counterProvider'));
      expect(config.trackedProviders.length, 2);
    });

    test('works with both tracked and ignored providers', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        ignoredProviders: [debugProvider],
        trackedProviders: [counterProvider],
      );

      expect(config.ignoredProviders, equals({'debugProvider'}));
      expect(config.trackedProviders, equals({'counterProvider'}));
    });

    test('empty provider lists result in empty sets', () {
      final config = TrackerConfig.forPackage('test_app');

      expect(config.ignoredProviders, isEmpty);
      expect(config.trackedProviders, isEmpty);
    });
  });

  group('Integration test with RiverpodDevToolsObserver', () {
    test('observer respects ignored provider references', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        ignoredProviders: [debugProvider],
      );

      final observer = RiverpodDevToolsObserver(config: config);

      // debugProvider should be ignored
      expect(
        observer.shouldTrackProvider('debugProvider', 'Provider'),
        false,
      );

      // other providers should be tracked
      expect(
        observer.shouldTrackProvider('counterProvider', 'StateProvider'),
        true,
      );
    });

    test('observer respects tracked provider references', () {
      final config = TrackerConfig.forPackage(
        'test_app',
        trackedProviders: [counterProvider],
      );

      final observer = RiverpodDevToolsObserver(config: config);

      // counterProvider should be tracked
      expect(
        observer.shouldTrackProvider('counterProvider', 'StateProvider'),
        true,
      );

      // other providers should NOT be tracked (whitelist mode)
      expect(
        observer.shouldTrackProvider('debugProvider', 'Provider'),
        false,
      );
    });

    test('observer tracks all providers when no filters set', () {
      final config = TrackerConfig.forPackage('test_app');
      final observer = RiverpodDevToolsObserver(config: config);

      // All providers should be tracked
      expect(
        observer.shouldTrackProvider('counterProvider', 'StateProvider'),
        true,
      );
      expect(
        observer.shouldTrackProvider('debugProvider', 'Provider'),
        true,
      );
    });
  });
}
