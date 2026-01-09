import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Selective Provider Tracking', () {
    test('tracks all providers when no filters are set', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Test providers
      final provider1 = Provider<int>((ref) => 1, name: 'provider1');
      final provider2 = Provider<int>((ref) => 2, name: 'provider2');
      final provider3 = Provider<String>((ref) => 'test', name: 'provider3');
      final provider4 = Provider<bool>((ref) => true, name: 'provider4');

      // Trigger provider events
      container.read(provider1);
      container.read(provider2);
      container.read(provider3);
      container.read(provider4);

      // Should track all 4 providers
      expect(observer.addEvents.length, 4);

      container.dispose();
    });

    test('tracks only whitelisted providers when trackedProviders is set', () {
      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          trackedProviders: {'provider1', 'provider3'},
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider1 = Provider<int>((ref) => 1, name: 'provider1');
      final provider2 = Provider<int>((ref) => 2, name: 'provider2');
      final provider3 = Provider<String>((ref) => 'test', name: 'provider3');
      final provider4 = Provider<bool>((ref) => true, name: 'provider4');

      // Trigger provider events
      container.read(provider1);
      container.read(provider2); // Should be ignored
      container.read(provider3);
      container.read(provider4); // Should be ignored

      // Should only track provider1 and provider3
      expect(observer.addEvents.length, 2);
      final trackedNames = observer.addEvents.map((e) => e.provider.name).toSet();
      expect(trackedNames, {'provider1', 'provider3'});

      container.dispose();
    });

    test('ignores blacklisted providers when ignoredProviders is set', () {
      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          ignoredProviders: {'provider2', 'provider4'},
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider1 = Provider<int>((ref) => 1, name: 'provider1');
      final provider2 = Provider<int>((ref) => 2, name: 'provider2');
      final provider3 = Provider<String>((ref) => 'test', name: 'provider3');
      final provider4 = Provider<bool>((ref) => true, name: 'provider4');

      // Trigger provider events
      container.read(provider1);
      container.read(provider2); // Should be ignored
      container.read(provider3);
      container.read(provider4); // Should be ignored

      // Should only track provider1 and provider3
      expect(observer.addEvents.length, 2);
      final trackedNames = observer.addEvents.map((e) => e.provider.name).toSet();
      expect(trackedNames, {'provider1', 'provider3'});

      container.dispose();
    });

    test('whitelist takes precedence over blacklist', () {
      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          trackedProviders: {'provider1', 'provider2'}, // Whitelist
          ignoredProviders: {'provider2', 'provider3'}, // Blacklist
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider1 = Provider<int>((ref) => 1, name: 'provider1');
      final provider2 = Provider<int>((ref) => 2, name: 'provider2');
      final provider3 = Provider<String>((ref) => 'test', name: 'provider3');
      final provider4 = Provider<bool>((ref) => true, name: 'provider4');

      // Trigger provider events
      container.read(provider1);
      container.read(provider2); // In both lists - whitelist wins
      container.read(provider3); // Should be ignored (not in whitelist)
      container.read(provider4); // Should be ignored (not in whitelist)

      // Should only track provider1 and provider2 (whitelist wins)
      expect(observer.addEvents.length, 2);
      final trackedNames = observer.addEvents.map((e) => e.provider.name).toSet();
      expect(trackedNames, {'provider1', 'provider2'});

      container.dispose();
    });

    test('applies custom providerFilter function', () {
      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          // Only track providers with names starting with 'test'
          providerFilter: (name, type) => name.startsWith('test'),
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider1 = Provider<int>((ref) => 1, name: 'provider1');
      final provider2 = Provider<int>((ref) => 2, name: 'testProvider');
      final provider3 = Provider<String>((ref) => 'test', name: 'testData');
      final provider4 = Provider<bool>((ref) => true, name: 'myProvider');

      // Trigger provider events
      container.read(provider1); // Should be ignored
      container.read(provider2); // Should be tracked (starts with 'test')
      container.read(provider3); // Should be tracked (starts with 'test')
      container.read(provider4); // Should be ignored

      // Should only track testProvider and testData
      expect(observer.addEvents.length, 2);
      final trackedNames = observer.addEvents.map((e) => e.provider.name).toSet();
      expect(trackedNames, {'testProvider', 'testData'});

      container.dispose();
    });

    test('providerFilter is applied after whitelist/blacklist', () {
      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          trackedProviders: {'provider2', 'provider3'}, // Whitelist
          // Filter out provider3 by name
          providerFilter: (name, type) => name != 'provider3',
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider1 = Provider<int>((ref) => 1, name: 'provider1');
      final provider2 = Provider<int>((ref) => 2, name: 'provider2');
      final provider3 = Provider<String>((ref) => 'test', name: 'provider3');
      final provider4 = Provider<bool>((ref) => true, name: 'provider4');

      // Trigger provider events
      container.read(provider1); // Not in whitelist - ignored
      container.read(provider2); // In whitelist and passes filter - tracked
      container.read(provider3); // In whitelist but filtered out - ignored
      container.read(provider4); // Not in whitelist - ignored

      // Should only track provider2
      expect(observer.addEvents.length, 1);
      expect(observer.addEvents.first.provider.name, 'provider2');

      container.dispose();
    });

    test('filters work with didUpdateProvider', () async {
      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          trackedProviders: {'testProvider'}, // Only track testProvider
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      var value1 = 0;
      var value2 = 0;
      final provider1 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value1;
      }, name: 'testProvider');
      final provider2 = FutureProvider<int>((ref) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return value2;
      }, name: 'otherProvider');

      // Read providers to trigger add events
      container.read(provider1);
      container.read(provider2);
      await Future.delayed(const Duration(milliseconds: 20));

      observer.updateEvents.clear(); // Clear any AsyncValue updates

      // Update providers
      value1 = 42;
      value2 = 99;
      container.invalidate(provider1);
      container.invalidate(provider2);
      container.read(provider1);
      container.read(provider2);
      await Future.delayed(const Duration(milliseconds: 20));

      // Should have some update events only for testProvider
      final testProviderUpdates = observer.updateEvents
          .where((e) => e.provider.name == 'testProvider')
          .length;
      final otherProviderUpdates = observer.updateEvents
          .where((e) => e.provider.name == 'otherProvider')
          .length;

      expect(testProviderUpdates, greaterThan(0));
      expect(otherProviderUpdates, 0);

      container.dispose();
    });

    test('filters work with didDisposeProvider', () {
      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          trackedProviders: {'provider2'}, // Only track provider2
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      final provider2 = Provider<int>((ref) => 2, name: 'provider2');
      final provider3 = Provider<String>((ref) => 'test', name: 'provider3');

      // Read providers
      container.read(provider2);
      container.read(provider3);

      observer.disposeEvents.clear(); // Clear add events

      // Dispose container (triggers dispose for both providers)
      container.dispose();

      // Should only track provider2 dispose
      expect(observer.disposeEvents.length, 1);
      expect(observer.disposeEvents.first.provider.name, 'provider2');
    });

    test('filters work with providerDidFail', () {
      final failingProvider = Provider<int>((ref) {
        throw Exception('Test error');
      }, name: 'failingProvider');

      final normalProvider = Provider<int>((ref) {
        throw Exception('Normal error');
      }, name: 'normalProvider');

      final observer = _TestObserverWithConfig(
        TrackerConfig(
          enableConsoleOutput: false,
          packagePrefixes: ['package:riverpod_devtools_tracker/'],
          trackedProviders: {'failingProvider'}, // Only track failingProvider
        ),
      );
      final container = ProviderContainer(observers: [observer]);

      // Try to read providers (will fail)
      try {
        container.read(failingProvider);
      } catch (_) {}
      try {
        container.read(normalProvider);
      } catch (_) {}

      // Should only track failingProvider error
      expect(observer.errorEvents.length, 1);
      expect(observer.errorEvents.first.provider.name, 'failingProvider');

      container.dispose();
    });

    test('TrackerConfig.forPackage supports new filter parameters', () {
      final config = TrackerConfig.forPackage(
        'my_app',
        trackedProviders: {'provider1', 'provider2'},
        ignoredProviders: {'provider3'},
        providerFilter: (name, type) => type.contains('State'),
      );

      expect(config.trackedProviders, {'provider1', 'provider2'});
      expect(config.ignoredProviders, {'provider3'});
      expect(config.providerFilter, isNotNull);
      expect(config.providerFilter!('test', 'StateProvider'), true);
      expect(config.providerFilter!('test', 'Provider'), false);
    });

    test('TrackerConfig.copyWith supports new filter parameters', () {
      final config = TrackerConfig(
        trackedProviders: {'provider1'},
        ignoredProviders: {'provider2'},
      );

      final newConfig = config.copyWith(
        trackedProviders: {'provider3', 'provider4'},
        ignoredProviders: {'provider5'},
        providerFilter: (name, type) => name.startsWith('test'),
      );

      expect(newConfig.trackedProviders, {'provider3', 'provider4'});
      expect(newConfig.ignoredProviders, {'provider5'});
      expect(newConfig.providerFilter, isNotNull);
      expect(newConfig.providerFilter!('testProvider', 'Provider'), true);
      expect(newConfig.providerFilter!('normalProvider', 'Provider'), false);
    });
  });
}

// Test observer that extends RiverpodDevToolsObserver to capture events
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];
  final List<ProviderObserverContext> errorEvents = [];

  _TestObserver()
      : super(
          config: TrackerConfig.forPackage(
            'test_app',
            enableConsoleOutput: false,
          ),
        );

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    super.didAddProvider(context, value);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      addEvents.add(context);
    }
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      updateEvents.add(context);
    }
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    super.didDisposeProvider(context);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      disposeEvents.add(context);
    }
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    super.providerDidFail(context, error, stackTrace);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      errorEvents.add(context);
    }
  }
}

// Test observer with custom config
final class _TestObserverWithConfig extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];
  final List<ProviderObserverContext> errorEvents = [];

  _TestObserverWithConfig(TrackerConfig config) : super(config: config);

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    super.didAddProvider(context, value);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      addEvents.add(context);
    }
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      updateEvents.add(context);
    }
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    super.didDisposeProvider(context);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      disposeEvents.add(context);
    }
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    super.providerDidFail(context, error, stackTrace);
    // Only add if the provider should be tracked
    final providerName = getProviderName(context);
    final providerType = getProviderType(context);
    if (shouldTrackProvider(providerName, providerType)) {
      errorEvents.add(context);
    }
  }
}
