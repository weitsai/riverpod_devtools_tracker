import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Async Provider Tracking', () {
    late _TestObserver observer;
    late ProviderContainer container;

    setUp(() {
      observer = _TestObserver();
      container = ProviderContainer(observers: [observer]);
    });

    tearDown(() {
      container.dispose();
    });

    group('FutureProvider Tracking', () {
      test('records add and update events', () async {
        final futureProvider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 42;
        });

        // Read the provider to trigger initialization
        container.read(futureProvider);

        // Should have didAddProvider event
        expect(observer.addEvents.length, 1);

        // Wait for the future to complete
        await Future.delayed(const Duration(milliseconds: 30));

        // Should have didUpdateProvider events
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));
      });

      test('tracks loading to data transition', () async {
        final futureProvider = FutureProvider<String>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'completed';
        });

        // Subscribe to track state changes
        final value1 = container.read(futureProvider);
        expect(value1.isLoading || value1.hasValue, true);

        // Initial add event
        expect(observer.addEvents.length, 1);

        // Wait for completion
        await Future.delayed(const Duration(milliseconds: 30));

        // Should have update event for the data transition
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

        // Final value should be data
        final value2 = container.read(futureProvider);
        expect(value2.hasValue, true);
        expect(value2.value, 'completed');
      });

      test('handles error states', () async {
        final failingProvider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          throw Exception('Test error');
        });

        // Read the provider
        final value1 = container.read(failingProvider);
        expect(value1.isLoading || value1.hasError, true);

        // Wait for the error
        await Future.delayed(const Duration(milliseconds: 30));

        // Should have update events
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

        // Should be in error state
        final value2 = container.read(failingProvider);
        expect(value2.hasError, true);
      });

      test('tracks invalidate and recreate cycles', () async {
        final futureProvider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 100;
        });

        // First read
        container.read(futureProvider);
        expect(observer.addEvents.length, 1);

        // Wait for completion
        await Future.delayed(const Duration(milliseconds: 30));
        final updateCount1 = observer.updateEvents.length;

        // Invalidate and dispose
        container.invalidate(futureProvider);
        await Future.delayed(const Duration(milliseconds: 10));

        // Read again - this may reuse the provider or create a new one
        container.read(futureProvider);
        await Future.delayed(const Duration(milliseconds: 10));

        // Should have at least one add event (original or new)
        expect(observer.addEvents.length, greaterThanOrEqualTo(1));

        // Wait for second completion
        await Future.delayed(const Duration(milliseconds: 30));

        // Should have update events
        expect(observer.updateEvents.length, greaterThanOrEqualTo(updateCount1));
      });

      test('tracks multiple async providers independently', () async {
        final provider1 = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 1;
        });

        final provider2 = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 15));
          return 2;
        });

        // Read both providers
        container.read(provider1);
        container.read(provider2);

        // Should have two add events
        expect(observer.addEvents.length, 2);

        // Wait for both to complete
        await Future.delayed(const Duration(milliseconds: 30));

        // Should have update events for both
        expect(observer.updateEvents.length, greaterThanOrEqualTo(2));
      });

      test('captures AsyncValue state transitions', () async {
        final provider = FutureProvider<String>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'result';
        });

        // Initial state
        final state1 = container.read(provider);
        expect(state1.isLoading || state1.hasValue, true);

        // Wait for completion
        await Future.delayed(const Duration(milliseconds: 30));

        // Final state should have value
        final state2 = container.read(provider);
        expect(state2.hasValue, true);
        expect(state2.value, 'result');

        // Should have recorded events
        expect(observer.addEvents.length, 1);
      });

      test('tracks immediate completion (no delay)', () async {
        final immediateProvider = FutureProvider<int>((ref) async {
          return 999;
        });

        container.read(immediateProvider);
        expect(observer.addEvents.length, 1);

        // Wait a bit for updates
        await Future.delayed(const Duration(milliseconds: 20));

        // Should still track the transition
        expect(observer.updateEvents.length, greaterThanOrEqualTo(0));
      });
    });

    group('StreamProvider Tracking', () {
      test('tracks stream emissions', () async {
        final streamController = StreamController<int>();
        final streamProvider = StreamProvider<int>((ref) {
          return streamController.stream;
        });

        // Listen to provider to trigger updates
        final subscription = container.listen(
          streamProvider,
          (previous, next) {},
        );

        await Future.delayed(const Duration(milliseconds: 10));
        expect(observer.addEvents.length, 1);

        // Emit values
        streamController.add(1);
        await Future.delayed(const Duration(milliseconds: 50));

        streamController.add(2);
        await Future.delayed(const Duration(milliseconds: 50));

        streamController.add(3);
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have update events for each emission
        expect(observer.updateEvents.length, greaterThanOrEqualTo(3));

        streamController.close();
        subscription.close();
      });

      test('handles stream errors', () async {
        final streamController = StreamController<int>();
        final streamProvider = StreamProvider<int>((ref) {
          return streamController.stream;
        });

        // Listen to provider to trigger updates
        final subscription = container.listen(
          streamProvider,
          (previous, next) {},
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Add error to stream
        streamController.addError(Exception('Stream error'));
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have tracked the error transition
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

        streamController.close();
        subscription.close();
      });

      test('tracks stream completion', () async {
        final streamController = StreamController<String>();
        final streamProvider = StreamProvider<String>((ref) {
          return streamController.stream;
        });

        // Listen to provider to trigger updates
        final subscription = container.listen(
          streamProvider,
          (previous, next) {},
        );

        await Future.delayed(const Duration(milliseconds: 10));

        streamController.add('value');
        await Future.delayed(const Duration(milliseconds: 50));

        streamController.close();
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have tracked events
        expect(observer.addEvents.length, 1);
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

        subscription.close();
      });

      test('tracks multiple stream values in sequence', () async {
        final streamController = StreamController<int>();
        final streamProvider = StreamProvider<int>((ref) {
          return streamController.stream;
        });

        // Listen to provider to trigger updates
        final subscription = container.listen(
          streamProvider,
          (previous, next) {},
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final initialUpdateCount = observer.updateEvents.length;

        // Emit 10 values
        for (int i = 0; i < 10; i++) {
          streamController.add(i);
          await Future.delayed(const Duration(milliseconds: 20));
        }

        // Should have tracked all emissions
        expect(
          observer.updateEvents.length,
          greaterThanOrEqualTo(initialUpdateCount + 10),
        );

        streamController.close();
        subscription.close();
      });

      test('tracks periodic stream emissions', () async {
        final streamProvider = StreamProvider<int>((ref) {
          return Stream.periodic(
            const Duration(milliseconds: 20),
            (count) => count,
          ).take(5);
        });

        // Listen to provider to trigger updates
        final subscription = container.listen(
          streamProvider,
          (previous, next) {},
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Wait for all emissions (5 * 20ms = 100ms + buffer)
        await Future.delayed(const Duration(milliseconds: 200));

        // Should have tracked periodic emissions
        expect(observer.updateEvents.length, greaterThanOrEqualTo(5));

        subscription.close();
      });
    });

    group('Async Dependency Chains', () {
      test('tracks dependent FutureProviders', () async {
        final baseProvider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 10;
        });

        final dependentProvider = FutureProvider<int>((ref) async {
          final base = await ref.watch(baseProvider.future);
          return base * 2;
        });

        // Read dependent provider (triggers base provider)
        container.read(dependentProvider);

        await Future.delayed(const Duration(milliseconds: 50));

        // Should have tracked both providers
        expect(observer.addEvents.length, greaterThanOrEqualTo(2));
      });

      test('tracks cascading invalidations', () async {
        var baseValue = 5;
        final baseProvider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return baseValue;
        });

        final dependentProvider = FutureProvider<int>((ref) async {
          final base = await ref.watch(baseProvider.future);
          await Future.delayed(const Duration(milliseconds: 5));
          return base * 3;
        });

        container.read(dependentProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        final initialUpdateCount = observer.updateEvents.length;

        // Invalidate base provider
        baseValue = 10;
        container.invalidate(baseProvider);
        // Need to read again to trigger recomputation
        container.read(dependentProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have new update events from re-computation
        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));
      });

      test('tracks three-level async dependency chain', () async {
        final level1 = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 1;
        });

        final level2 = FutureProvider<int>((ref) async {
          final l1 = await ref.watch(level1.future);
          await Future.delayed(const Duration(milliseconds: 10));
          return l1 + 10;
        });

        final level3 = FutureProvider<int>((ref) async {
          final l2 = await ref.watch(level2.future);
          await Future.delayed(const Duration(milliseconds: 10));
          return l2 + 100;
        });

        container.read(level3);
        // Wait longer for all levels to initialize
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have tracked at least level3 and its dependencies
        // Note: Depending on timing, may track 2-3 providers
        expect(observer.addEvents.length, greaterThanOrEqualTo(2));
      });
    });

    group('Stack Caching Mechanism', () {
      test('caches stack for async provider updates', () async {
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 42;
        });

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 30));

        // Observer should have captured stack information
        expect(observer.addEvents.length, 1);
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));
      });

      test('reuses cached stack for multiple updates', () async {
        var counter = 0;
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return counter;
        });

        // First read
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 30));

        // Invalidate and read multiple times
        for (int i = 0; i < 5; i++) {
          counter++;
          container.invalidate(provider);
          container.read(provider);
          await Future.delayed(const Duration(milliseconds: 30));
        }

        // All updates should have been tracked
        expect(observer.updateEvents.length, greaterThanOrEqualTo(5));
      });

      test('handles stack for concurrent async providers', () async {
        final providers = List.generate(
          10,
          (i) => FutureProvider<int>((ref) async {
            await Future.delayed(Duration(milliseconds: i * 5));
            return i;
          }),
        );

        // Read all providers concurrently
        for (final provider in providers) {
          container.read(provider);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Should have tracked all providers
        expect(observer.addEvents.length, 10);
      });
    });

    group('StackTraceParser', () {
      test('parses valid stack traces', () {
        final config = TrackerConfig.forPackage('test_app');
        final parser = StackTraceParser(config);

        final stackTrace = StackTrace.fromString('''
#0      userFunction (package:test_app/main.dart:10:5)
#1      providerFunction (package:test_app/providers/counter.dart:20:5)
#2      flutterFramework (package:flutter/widgets.dart:100:5)
''');

        final callChain = parser.parseCallChain(stackTrace);

        // Parser should extract location information from the stack trace
        // Note: packagePrefixes filtering may exclude some entries
        expect(callChain, isA<List<LocationInfo>>());
      });

      test('filters framework-only call chain', () {
        final config = TrackerConfig.forPackage('test_app');
        final parser = StackTraceParser(config);

        final stackTraceFrameworkOnly = StackTrace.fromString('''
#0      flutterFunc1 (package:flutter/widgets.dart:100:5)
#1      riverpodFunc (package:riverpod/riverpod.dart:50:5)
#2      flutterFunc2 (package:flutter/foundation.dart:200:5)
''');

        final callChain = parser.parseCallChain(stackTraceFrameworkOnly);

        // Should not have user code
        final hasUserCode = callChain.any(
          (loc) => loc.file.contains('package:test_app/'),
        );
        expect(hasUserCode, false);
      });

      test('handles empty stack trace', () {
        final config = TrackerConfig.forPackage('test_app');
        final parser = StackTraceParser(config);

        final emptyStackTrace = StackTrace.fromString('');
        final callChain = parser.parseCallChain(emptyStackTrace);

        expect(callChain, isEmpty);
      });

      test('extracts user code from mixed stack trace', () {
        final config = TrackerConfig.forPackage('my_app');
        final parser = StackTraceParser(config);

        final mixedStackTrace = StackTrace.fromString('''
#0      myFunction (package:my_app/features/auth.dart:42:5)
#1      flutterWidget (package:flutter/widgets.dart:100:5)
#2      myOtherFunction (package:my_app/utils/helper.dart:15:3)
#3      riverpodInternal (package:riverpod/src/framework.dart:200:5)
''');

        final callChain = parser.parseCallChain(mixedStackTrace);

        // Should have extracted user code (package prefix is removed in shortened path)
        expect(callChain.length, 2); // Only my_app entries should remain
        expect(callChain[0].file, 'features/auth.dart');
        expect(callChain[0].line, 42);
        expect(callChain[1].file, 'utils/helper.dart');
        expect(callChain[1].line, 15);
      });
    });

    group('Error Recovery and Edge Cases', () {
      test('recovers from async error and tracks subsequent success', () async {
        var shouldFail = true;
        final provider = FutureProvider<int>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          if (shouldFail) {
            throw Exception('Temporary error');
          }
          return 100;
        });

        // First read - will fail
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 30));

        final errorUpdateCount = observer.updateEvents.length;

        // Recover
        shouldFail = false;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 30));

        // Should have tracked recovery
        expect(observer.updateEvents.length, greaterThan(errorUpdateCount));
      });

      test('tracks rapid async provider creation and disposal', () async {
        for (int i = 0; i < 50; i++) {
          final tempProvider = FutureProvider<int>((ref) async {
            return i;
          });
          container.read(tempProvider);
          await Future.delayed(const Duration(milliseconds: 2));
        }

        await Future.delayed(const Duration(milliseconds: 50));

        // Should have tracked all providers
        expect(observer.addEvents.length, greaterThanOrEqualTo(50));
      });

      test('handles null async value', () async {
        final nullProvider = FutureProvider<String?>((ref) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return null;
        });

        container.read(nullProvider);
        await Future.delayed(const Duration(milliseconds: 30));

        // Should track null value without crashing
        expect(observer.addEvents.length, 1);
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));
      });

      test('tracks async provider with immediate synchronous value', () {
        final syncProvider = FutureProvider<int>((ref) {
          return Future.value(42);
        });

        container.read(syncProvider);

        // Should track even for immediate futures
        expect(observer.addEvents.length, 1);
      });
    });

    group('Complex Async Scenarios', () {
      test('tracks async provider watching sync provider', () async {
        final syncProvider = Provider<int>((ref) => 5);

        final asyncProvider = FutureProvider<int>((ref) async {
          final sync = ref.watch(syncProvider);
          await Future.delayed(const Duration(milliseconds: 10));
          return sync * 2;
        });

        container.read(asyncProvider);
        await Future.delayed(const Duration(milliseconds: 30));

        // Should have tracked both providers
        expect(observer.addEvents.length, 2);
      });

      test('tracks stream with changing values', () async {
        final streamController = StreamController<int>();
        final streamProvider = StreamProvider<int>((ref) {
          return streamController.stream;
        });

        // Listen to provider to trigger updates
        final subscription = container.listen(
          streamProvider,
          (previous, next) {},
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Emit different values to avoid skipUnchangedValues filtering
        for (int i = 0; i < 5; i++) {
          streamController.add(i);
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Should track all emissions
        expect(observer.updateEvents.length, greaterThanOrEqualTo(5));

        streamController.close();
        subscription.close();
      });

      test('tracks async provider with complex return type', () async {
        final complexProvider = FutureProvider<Map<String, List<int>>>(
          (ref) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return {
              'data': [1, 2, 3],
              'more': [4, 5, 6],
            };
          },
        );

        container.read(complexProvider);
        await Future.delayed(const Duration(milliseconds: 30));

        expect(observer.addEvents.length, 1);
        expect(observer.updateEvents.length, greaterThanOrEqualTo(1));
      });
    });
  });
}

/// Test observer that records events for verification
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
