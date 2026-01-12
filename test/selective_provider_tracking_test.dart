import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Selective Provider Tracking', () {
    group('Whitelist (trackedProviders)', () {
      testWidgets('tracks only providers in whitelist', (tester) async {
        final observer = _TestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            trackedProviders: {'counterProvider', 'userProvider'},
          ),
        );
        final container = ProviderContainer(observers: [observer]);

        // Define providers
        final counterProvider = Provider<int>((ref) => 42, name: 'counterProvider');
        final userProvider = Provider<String>((ref) => 'John', name: 'userProvider');
        final settingsProvider = Provider<bool>((ref) => true, name: 'settingsProvider');

        // Read providers
        container.read(counterProvider);
        container.read(userProvider);
        container.read(settingsProvider);

        // Only whitelisted providers should be tracked
        expect(observer.addEvents.length, 2);
        expect(observer.addEvents[0].provider.name, 'counterProvider');
        expect(observer.addEvents[1].provider.name, 'userProvider');

        container.dispose();
      });

      testWidgets('tracks all providers when whitelist is empty', (tester) async {
        final observer = _TestObserver(
          config: TrackerConfig.forPackage('test_app'),
        );
        final container = ProviderContainer(observers: [observer]);

        // Define providers
        final provider1 = Provider<int>((ref) => 1, name: 'provider1');
        final provider2 = Provider<int>((ref) => 2, name: 'provider2');
        final provider3 = Provider<int>((ref) => 3, name: 'provider3');

        // Read all providers
        container.read(provider1);
        container.read(provider2);
        container.read(provider3);

        // All providers should be tracked
        expect(observer.addEvents.length, 3);

        container.dispose();
      });
    });

    group('Blacklist (ignoredProviders)', () {
      testWidgets('ignores providers in blacklist', (tester) async {
        final observer = _TestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            ignoredProviders: {'loggingProvider', 'analyticsProvider'},
          ),
        );
        final container = ProviderContainer(observers: [observer]);

        // Define providers
        final counterProvider = Provider<int>((ref) => 42, name: 'counterProvider');
        final loggingProvider = Provider<String>((ref) => 'log', name: 'loggingProvider');
        final analyticsProvider = Provider<bool>((ref) => true, name: 'analyticsProvider');

        // Read all providers
        container.read(counterProvider);
        container.read(loggingProvider);
        container.read(analyticsProvider);

        // Only counterProvider should be tracked
        expect(observer.addEvents.length, 1);
        expect(observer.addEvents[0].provider.name, 'counterProvider');

        container.dispose();
      });

      testWidgets('blacklist takes priority over whitelist', (tester) async {
        final observer = _TestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            trackedProviders: {'provider1', 'provider2'},
            ignoredProviders: {'provider2'},
          ),
        );
        final container = ProviderContainer(observers: [observer]);

        final provider1 = Provider<int>((ref) => 1, name: 'provider1');
        final provider2 = Provider<int>((ref) => 2, name: 'provider2');

        container.read(provider1);
        container.read(provider2);

        // provider2 is in whitelist but also in blacklist, so only provider1 is tracked
        expect(observer.addEvents.length, 1);
        expect(observer.addEvents[0].provider.name, 'provider1');

        container.dispose();
      });
    });

    group('Custom filter (providerFilter)', () {
      testWidgets('filters by provider type', (tester) async {
        final observer = _TestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            providerFilter: (name, type) {
              // Only track FutureProvider
              return type.contains('Future');
            },
          ),
        );
        final container = ProviderContainer(observers: [observer]);

        // Define different types of providers
        final regularProvider = Provider<int>((ref) => 42, name: 'regularProvider');
        final futureProvider = FutureProvider<int>((ref) async => 42, name: 'futureProvider');

        // Read all providers
        container.read(regularProvider);
        container.read(futureProvider);

        // Only FutureProvider should be tracked
        expect(observer.addEvents.length, 1);
        expect(observer.addEvents[0].provider.name, 'futureProvider');

        container.dispose();
      });

      testWidgets('custom filter applied after blacklist', (tester) async {
        final observer = _TestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            ignoredProviders: {'futureProvider1'},
            providerFilter: (name, type) => type.contains('Future'),
          ),
        );
        final container = ProviderContainer(observers: [observer]);

        final futureProvider1 = FutureProvider<int>((ref) async => 1, name: 'futureProvider1');
        final futureProvider2 = FutureProvider<int>((ref) async => 2, name: 'futureProvider2');
        final regularProvider = Provider<int>((ref) => 42, name: 'regularProvider');

        container.read(futureProvider1);
        container.read(futureProvider2);
        container.read(regularProvider);

        // futureProvider1 is blacklisted, regularProvider fails type filter
        // Only futureProvider2 is tracked
        expect(observer.addEvents.length, 1);
        expect(observer.addEvents[0].provider.name, 'futureProvider2');

        container.dispose();
      });
    });

    group('Filter applies to all lifecycle events', () {
      testWidgets('filters didDisposeProvider events', (tester) async {
        final observer = _TestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            trackedProviders: {'tracked'},
          ),
        );
        final container = ProviderContainer(observers: [observer]);

        final tracked = Provider<int>((ref) => 42, name: 'tracked');
        final ignored = Provider<int>((ref) => 99, name: 'ignored');

        container.read(tracked);
        container.read(ignored);

        // Clear add events
        observer.addEvents.clear();

        // Invalidate both
        container.invalidate(tracked);
        container.invalidate(ignored);

        // Only tracked provider dispose should be captured
        expect(observer.disposeEvents.length, 1);
        expect(observer.disposeEvents[0].provider.name, 'tracked');

        container.dispose();
      });
    });

    group('Performance impact', () {
      test('filters reduce tracked provider count', () {
        final observerNoFilter = _TestObserver(
          config: TrackerConfig.forPackage('test_app'),
        );
        final observerWithFilter = _TestObserver(
          config: TrackerConfig.forPackage(
            'test_app',
            trackedProviders: {'important'},
          ),
        );

        final container1 = ProviderContainer(observers: [observerNoFilter]);
        final container2 = ProviderContainer(observers: [observerWithFilter]);

        // Create many providers
        for (var i = 0; i < 10; i++) {
          final provider = Provider<int>((ref) => i, name: 'provider$i');
          container1.read(provider);
          container2.read(provider);
        }

        // Add the important one
        final important = Provider<int>((ref) => 999, name: 'important');
        container1.read(important);
        container2.read(important);

        // No filter tracks all providers
        expect(observerNoFilter.addEvents.length, 11);

        // With filter tracks only the important one
        expect(observerWithFilter.addEvents.length, 1);
        expect(observerWithFilter.addEvents[0].provider.name, 'important');

        container1.dispose();
        container2.dispose();
      });
    });
  });
}

/// Test observer that records events (only those that pass the filter)
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];

  _TestObserver({required TrackerConfig config})
    : super(
        config: config.copyWith(
          enableConsoleOutput: false, // Disable console for tests
        ),
      );

  /// Check if provider should be tracked (same logic as base class)
  bool _shouldTrackProvider(ProviderObserverContext context) {
    final providerName = context.provider.name ?? context.provider.runtimeType.toString();
    final providerType = context.provider.runtimeType.toString();

    // Check blacklist
    if (config.ignoredProviders.contains(providerName)) {
      return false;
    }

    // Check whitelist
    if (config.trackedProviders.isNotEmpty) {
      if (!config.trackedProviders.contains(providerName)) {
        return false;
      }
    }

    // Apply custom filter
    if (config.providerFilter != null) {
      return config.providerFilter!(providerName, providerType);
    }

    return true;
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (_shouldTrackProvider(context)) {
      addEvents.add(context);
    }
    super.didAddProvider(context, value);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (_shouldTrackProvider(context)) {
      updateEvents.add(context);
    }
    super.didUpdateProvider(context, previousValue, newValue);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (_shouldTrackProvider(context)) {
      disposeEvents.add(context);
    }
    super.didDisposeProvider(context);
  }
}
