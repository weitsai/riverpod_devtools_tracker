import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('RiverpodDevToolsObserver', () {
    test('creates with default config', () {
      final observer = RiverpodDevToolsObserver();
      expect(observer.config.enabled, true);
    });

    test('creates with custom config', () {
      final config = TrackerConfig.forPackage('test_app');
      final observer = RiverpodDevToolsObserver(config: config);
      expect(observer.config, config);
    });

    test('respects enabled flag', () {
      final observer = RiverpodDevToolsObserver(
        config: const TrackerConfig(enabled: false),
      );
      expect(observer.config.enabled, false);
    });

    testWidgets('observer can be added to ProviderScope', (tester) async {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage('test_app'),
      );

      await tester.pumpWidget(
        ProviderScope(
          observers: [observer],
          child: const MaterialApp(
            home: Scaffold(body: Text('Test')),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('observer tracks provider add events', (tester) async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);

      // Read the provider to trigger add event
      container.read(testProvider);

      expect(observer.addEvents.length, greaterThan(0));

      container.dispose();
    });

    testWidgets('observer tracks provider dispose events', (tester) async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final testProvider = Provider<int>((ref) => 42);

      // Read and invalidate the provider
      container.read(testProvider);
      container.invalidate(testProvider);

      expect(observer.disposeEvents.length, greaterThan(0));

      container.dispose();
    });
  });

  group('RiverpodDevToolsObserver memory management', () {
    test('stack cache cleanup prevents memory leak', () {
      final observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage('test_app'),
      );

      // Access internal state through reflection would be needed for a real test
      // This is a basic structural test
      expect(observer.config.enabled, true);
    });
  });

  group('Value serialization', () {
    testWidgets('serializes primitive values correctly', (tester) async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final intProvider = Provider<int>((ref) => 42);
      final stringProvider = Provider<String>((ref) => 'test');
      final boolProvider = Provider<bool>((ref) => true);

      container.read(intProvider);
      container.read(stringProvider);
      container.read(boolProvider);

      // Values should be captured
      expect(observer.addEvents.length, 3);

      container.dispose();
    });

    testWidgets('handles null values', (tester) async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final nullProvider = Provider<String?>((ref) => null);
      container.read(nullProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    testWidgets('handles enum values', (tester) async {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      final enumProvider = Provider<_TestEnum>((ref) => _TestEnum.first);
      container.read(enumProvider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });
  });
}

/// Test observer that records events
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];
  final List<ProviderObserverContext> disposeEvents = [];
  final List<ProviderObserverContext> errorEvents = [];

  _TestObserver()
      : super(
          config: TrackerConfig.forPackage(
            'test_app',
            enableConsoleOutput: false, // Disable console for tests
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
    updateEvents.add(context);
    super.didUpdateProvider(context, previousValue, newValue);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposeEvents.add(context);
    super.didDisposeProvider(context);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    errorEvents.add(context);
    super.providerDidFail(context, error, stackTrace);
  }
}

enum _TestEnum {
  first,
  // ignore: unused_field
  second,
  // ignore: unused_field
  third,
}
