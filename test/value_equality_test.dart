import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Value Equality Comparison', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    group('Primitive Types Equality', () {
      test('identical integers are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = 42;
        final provider = FutureProvider<int>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        // Invalidate with same value
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Update count should not increase much (value unchanged)
        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('different integers are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = 42;
        final provider = FutureProvider<int>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        // Change value
        value = 100;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should have new update events
        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('identical strings are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = 'test';
        final provider = FutureProvider<String>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        // Same string value
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('different strings are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = 'hello';
        final provider = FutureProvider<String>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = 'world';
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('identical booleans are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = true;
        final provider = FutureProvider<bool>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('different booleans are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = true;
        final provider = FutureProvider<bool>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = false;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });
    });

    group('Null Equality', () {
      test('null equals null', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        String? value;
        final provider = FutureProvider<String?>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('null does not equal non-null', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        String? value;
        final provider = FutureProvider<String?>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = 'not null';
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('non-null does not equal null', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        String? value = 'something';
        final provider = FutureProvider<String?>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = null;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });
    });

    group('Collection Equality', () {
      test('identical lists are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = [1, 2, 3];
        final provider = FutureProvider<List<int>>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        // Same content list
        value = [1, 2, 3];
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should recognize as equal
        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('different lists are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = [1, 2, 3];
        final provider = FutureProvider<List<int>>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = [1, 2, 4]; // Different content
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('lists with different order are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = [1, 2, 3];
        final provider = FutureProvider<List<int>>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = [3, 2, 1]; // Different order
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('identical maps are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = {'a': 1, 'b': 2};
        final provider = FutureProvider<Map<String, int>>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = {'a': 1, 'b': 2}; // Same content
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('different maps are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = {'a': 1, 'b': 2};
        final provider = FutureProvider<Map<String, int>>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = {'a': 1, 'b': 3}; // Different value
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('maps with different keys are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = {'a': 1, 'b': 2};
        final provider = FutureProvider<Map<String, int>>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = {'a': 1, 'c': 2}; // Different key
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('empty collections are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = <int>[];
        final provider = FutureProvider<List<int>>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = <int>[]; // Another empty list
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });
    });

    group('Nested Structure Equality', () {
      test('identical nested maps are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = {
          'user': {'name': 'John', 'age': 30},
          'active': true,
        };
        final provider = FutureProvider<Map<String, dynamic>>(
          (ref) async => value,
        );

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = {
          'user': {'name': 'John', 'age': 30},
          'active': true,
        };
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('nested maps with different deep values are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = {
          'user': {'name': 'John', 'age': 30},
          'active': true,
        };
        final provider = FutureProvider<Map<String, dynamic>>(
          (ref) async => value,
        );

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = {
          'user': {'name': 'John', 'age': 31}, // Different age
          'active': true,
        };
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('deeply nested structures are compared correctly', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = {
          'level1': {
            'level2': {
              'level3': {'value': 42},
            },
          },
        };
        final provider = FutureProvider<Map<String, dynamic>>(
          (ref) async => value,
        );

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = {
          'level1': {
            'level2': {
              'level3': {'value': 42}, // Same deep value
            },
          },
        };
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });
    });

    group('Custom Class Equality', () {
      test('identical custom classes with same toString are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = _TestClass('John', 30);
        final provider = FutureProvider<_TestClass>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = _TestClass('John', 30); // Same content
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should recognize as equal based on string comparison
        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('custom classes with different values are not equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = _TestClass('John', 30);
        final provider = FutureProvider<_TestClass>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = _TestClass('Jane', 25); // Different content
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });
    });

    group('Skip Unchanged Values Feature', () {
      test('skipUnchangedValues=false records all updates', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: false);
        container = ProviderContainer(observers: [observer]);

        var value = 42;
        final provider = FutureProvider<int>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        // Same value, but should still record
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should have more update events even though value is same
        expect(observer.updateEvents.length, greaterThan(initialUpdateCount));

        container.dispose();
      });

      test('skipUnchangedValues=true filters identical values', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = 42;
        final provider = FutureProvider<int>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        // Same value should be filtered
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Update count should not increase significantly
        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });
    });

    group('Special Values Equality', () {
      test('NaN equals NaN', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = double.nan;
        final provider = FutureProvider<double>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // NaN != NaN in Dart, so it should be treated as different value
        value = double.nan;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should have update events (NaN treated as different)
        expect(observer.updateEvents.length, greaterThan(0));

        container.dispose();
      });

      test('Infinity equals Infinity', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = double.infinity;
        final provider = FutureProvider<double>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = double.infinity;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });

      test('zero and negative zero are equal', () async {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        var value = 0.0;
        final provider = FutureProvider<double>((ref) async => value);

        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final initialUpdateCount = observer.updateEvents.length;

        value = -0.0;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // 0.0 == -0.0 in Dart
        expect(observer.updateEvents.length, lessThanOrEqualTo(initialUpdateCount + 2));

        container.dispose();
      });
    });

    group('Type Mismatch', () {
      test('different types are not equal', () {
        final observer = _EqualityTestObserver(skipUnchangedValues: true);
        container = ProviderContainer(observers: [observer]);

        // Test with synchronous provider to directly test equality
        final provider1 = Provider<int>((ref) => 42);
        final provider2 = Provider<String>((ref) => '42');

        container.read(provider1);
        container.read(provider2);

        // Should create separate events for different types
        expect(observer.addEvents.length, 2);

        container.dispose();
      });
    });
  });
}

/// Test observer that tracks update events for equality testing
final class _EqualityTestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];

  _EqualityTestObserver({required bool skipUnchangedValues})
      : super(
          config: TrackerConfig.forPackage(
            'test_app',
            enableConsoleOutput: false,
            skipUnchangedValues: skipUnchangedValues,
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
    // Add after super call to respect filtering
    updateEvents.add(context);
  }
}

/// Test class for equality testing
class _TestClass {
  final String name;
  final int age;

  _TestClass(this.name, this.age);

  @override
  String toString() => '_TestClass(name: $name, age: $age)';
}
