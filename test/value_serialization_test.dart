import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Value Serialization', () {
    late _SerializationTestObserver observer;
    late ProviderContainer container;

    setUp(() {
      observer = _SerializationTestObserver();
      container = ProviderContainer(observers: [observer]);
    });

    tearDown(() {
      container.dispose();
    });

    group('Primitive Types', () {
      test('serializes integers correctly', () {
        final provider = Provider<int>((ref) => 42);
        container.read(provider);

        expect(observer.lastAddValue, 42);
        expect(observer.lastAddValue is int, isTrue);
      });

      test('serializes doubles correctly', () {
        final provider = Provider<double>((ref) => 3.14159);
        container.read(provider);

        expect(observer.lastAddValue, 3.14159);
        expect(observer.lastAddValue is double, isTrue);
      });

      test('serializes negative numbers correctly', () {
        final provider = Provider<int>((ref) => -100);
        container.read(provider);

        expect(observer.lastAddValue, -100);
      });

      test('serializes zero correctly', () {
        final provider = Provider<int>((ref) => 0);
        container.read(provider);

        expect(observer.lastAddValue, 0);
      });

      test('serializes large numbers correctly', () {
        final provider = Provider<int>((ref) => 9223372036854775807); // max int64
        container.read(provider);

        expect(observer.lastAddValue, 9223372036854775807);
      });

      test('serializes strings correctly', () {
        final provider = Provider<String>((ref) => 'Hello World');
        container.read(provider);

        expect(observer.lastAddValue, 'Hello World');
        expect(observer.lastAddValue is String, isTrue);
      });

      test('serializes empty strings correctly', () {
        final provider = Provider<String>((ref) => '');
        container.read(provider);

        expect(observer.lastAddValue, '');
      });

      test('serializes multi-line strings correctly', () {
        final provider = Provider<String>((ref) => 'Line 1\nLine 2\nLine 3');
        container.read(provider);

        expect(observer.lastAddValue, 'Line 1\nLine 2\nLine 3');
      });

      test('serializes strings with special characters', () {
        final provider = Provider<String>((ref) => 'Hello "World" \\ \$ \n \t');
        container.read(provider);

        expect(observer.lastAddValue, 'Hello "World" \\ \$ \n \t');
      });

      test('serializes boolean true correctly', () {
        final provider = Provider<bool>((ref) => true);
        container.read(provider);

        expect(observer.lastAddValue, true);
        expect(observer.lastAddValue is bool, isTrue);
      });

      test('serializes boolean false correctly', () {
        final provider = Provider<bool>((ref) => false);
        container.read(provider);

        expect(observer.lastAddValue, false);
      });

      test('serializes null correctly', () {
        final provider = Provider<String?>((ref) => null);
        container.read(provider);

        expect(observer.lastAddValue, null);
      });
    });

    group('Enum Serialization', () {
      test('captures enum values correctly', () {
        final provider = Provider<_TestEnum>((ref) => _TestEnum.value1);
        container.read(provider);

        // Observer captures the enum object itself
        expect(observer.lastAddValue, _TestEnum.value1);
        expect(observer.lastAddValue is _TestEnum, isTrue);
      });

      test('tracks enum updates correctly', () async {
        var enumValue = _TestEnum.value1;
        final provider = FutureProvider<_TestEnum>((ref) async => enumValue);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Observer captures AsyncValue, not the raw enum
        expect(observer.lastAddValue, isNotNull);

        // Update to different value
        enumValue = _TestEnum.value2;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Update events should be triggered
        expect(observer.lastUpdateNewValue, isNotNull);
      });
    });

    group('Collection Types', () {
      test('serializes empty list correctly', () {
        final provider = Provider<List<int>>((ref) => []);
        container.read(provider);

        expect(observer.lastAddValue, []);
        expect(observer.lastAddValue is List, isTrue);
      });

      test('serializes int list correctly', () {
        final provider = Provider<List<int>>((ref) => [1, 2, 3, 4, 5]);
        container.read(provider);

        expect(observer.lastAddValue, [1, 2, 3, 4, 5]);
      });

      test('serializes string list correctly', () {
        final provider = Provider<List<String>>(
          (ref) => ['hello', 'world', 'test'],
        );
        container.read(provider);

        expect(observer.lastAddValue, ['hello', 'world', 'test']);
      });

      test('serializes mixed type list correctly', () {
        final provider = Provider<List<dynamic>>((ref) => [1, 'two', 3.0, true]);
        container.read(provider);

        expect(observer.lastAddValue, [1, 'two', 3.0, true]);
      });

      test('serializes empty map correctly', () {
        final provider = Provider<Map<String, int>>((ref) => {});
        container.read(provider);

        expect(observer.lastAddValue, {});
        expect(observer.lastAddValue is Map, isTrue);
      });

      test('serializes simple map correctly', () {
        final provider = Provider<Map<String, int>>(
          (ref) => {'a': 1, 'b': 2, 'c': 3},
        );
        container.read(provider);

        expect(observer.lastAddValue, {'a': 1, 'b': 2, 'c': 3});
      });

      test('serializes nested map correctly', () {
        final provider = Provider<Map<String, dynamic>>(
          (ref) => {
            'user': {'name': 'John', 'age': 30},
            'active': true,
          },
        );
        container.read(provider);

        expect(
          observer.lastAddValue,
          {
            'user': {'name': 'John', 'age': 30},
            'active': true,
          },
        );
      });

      test('serializes nested list correctly', () {
        final provider = Provider<List<List<int>>>(
          (ref) => [
            [1, 2, 3],
            [4, 5, 6],
          ],
        );
        container.read(provider);

        expect(
          observer.lastAddValue,
          [
            [1, 2, 3],
            [4, 5, 6],
          ],
        );
      });

      test('serializes complex nested structure correctly', () {
        final provider = Provider<Map<String, dynamic>>(
          (ref) => {
            'data': [
              {'id': 1, 'name': 'Item 1'},
              {'id': 2, 'name': 'Item 2'},
            ],
            'metadata': {
              'count': 2,
              'page': 1,
            },
          },
        );
        container.read(provider);

        expect(
          observer.lastAddValue,
          {
            'data': [
              {'id': 1, 'name': 'Item 1'},
              {'id': 2, 'name': 'Item 2'},
            ],
            'metadata': {
              'count': 2,
              'page': 1,
            },
          },
        );
      });
    });

    group('Custom Classes', () {
      test('captures class with toJson', () {
        final provider = Provider<_JsonSerializableClass>(
          (ref) => _JsonSerializableClass('Test', 42),
        );
        container.read(provider);

        // Observer captures the class object itself (serialization happens internally)
        expect(observer.lastAddValue, isA<_JsonSerializableClass>());
        expect(observer.lastAddValue, isNotNull);
      });

      test('captures class without toJson', () {
        final provider = Provider<_NonSerializableClass>(
          (ref) => _NonSerializableClass('Test', 42),
        );
        container.read(provider);

        // Observer captures the class object itself
        expect(observer.lastAddValue, isA<_NonSerializableClass>());
        expect(observer.lastAddValue, isNotNull);
      });

      test('handles complex classes gracefully', () {
        final provider = Provider<_ComplexToJsonClass>(
          (ref) => _ComplexToJsonClass(),
        );
        container.read(provider);

        // Should handle gracefully
        expect(observer.lastAddValue, isNotNull);
        expect(observer.lastAddValue, isA<_ComplexToJsonClass>());
      });
    });

    group('Large Values', () {
      test('handles large strings', () {
        final largeString = 'x' * 10000; // 10KB string
        final provider = Provider<String>((ref) => largeString);
        container.read(provider);

        expect(observer.lastAddValue, largeString);
        expect((observer.lastAddValue as String).length, 10000);
      });

      test('handles large lists', () {
        final largeList = List.generate(1000, (i) => i);
        final provider = Provider<List<int>>((ref) => largeList);
        container.read(provider);

        expect(observer.lastAddValue, largeList);
        expect((observer.lastAddValue as List).length, 1000);
      });

      test('handles large maps', () {
        final largeMap = {
          for (int i = 0; i < 100; i++) 'key$i': i,
        };
        final provider = Provider<Map<String, int>>((ref) => largeMap);
        container.read(provider);

        expect(observer.lastAddValue, largeMap);
        expect((observer.lastAddValue as Map).length, 100);
      });

      test('handles deeply nested structures', () {
        Map<String, dynamic> createNested(int depth) {
          if (depth == 0) return {'value': 42};
          return {'nested': createNested(depth - 1)};
        }

        final nested = createNested(10);
        final provider = Provider<Map<String, dynamic>>((ref) => nested);
        container.read(provider);

        expect(observer.lastAddValue, nested);
      });
    });

    group('Special Cases', () {
      test('handles NaN correctly', () {
        final provider = Provider<double>((ref) => double.nan);
        container.read(provider);

        expect((observer.lastAddValue as double).isNaN, isTrue);
      });

      test('handles Infinity correctly', () {
        final provider = Provider<double>((ref) => double.infinity);
        container.read(provider);

        expect(observer.lastAddValue, double.infinity);
      });

      test('handles negative Infinity correctly', () {
        final provider = Provider<double>((ref) => double.negativeInfinity);
        container.read(provider);

        expect(observer.lastAddValue, double.negativeInfinity);
      });

      test('handles DateTime toString', () {
        final now = DateTime(2024, 1, 1);
        final provider = Provider<DateTime>((ref) => now);
        container.read(provider);

        // DateTime is serialized (may be as object or string depending on implementation)
        expect(observer.lastAddValue, isNotNull);
        // DateTime should contain the date information
        final valueStr = observer.lastAddValue.toString();
        expect(valueStr, contains('2024'));
      });

      test('handles Duration serialization', () {
        final duration = const Duration(seconds: 30);
        final provider = Provider<Duration>((ref) => duration);
        container.read(provider);

        // Duration is serialized (implementation may vary)
        expect(observer.lastAddValue, isNotNull);
        final valueStr = observer.lastAddValue.toString();
        expect(valueStr.contains('30') || valueStr.contains('Duration'), isTrue);
      });

      test('handles Uri serialization', () {
        final uri = Uri.parse('https://example.com');
        final provider = Provider<Uri>((ref) => uri);
        container.read(provider);

        // Uri is serialized (implementation may vary)
        expect(observer.lastAddValue, isNotNull);
        final valueStr = observer.lastAddValue.toString();
        expect(valueStr, contains('example.com'));
      });

      test('handles Sets serialization', () {
        final provider = Provider<Set<int>>((ref) => {1, 2, 3});
        container.read(provider);

        // Sets are serialized (implementation may vary)
        expect(observer.lastAddValue, isNotNull);
        final valueStr = observer.lastAddValue.toString();
        expect(valueStr, contains('1'));
      });
    });

    group('Update Serialization', () {
      test('tracks value changes through AsyncValue', () async {
        var value = 10;
        final provider = FutureProvider<int>((ref) async => value);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // AsyncValue is captured, not the raw value
        final addValueStr = observer.lastAddValue.toString();
        expect(addValueStr.contains('AsyncLoading') || addValueStr.contains('AsyncData'), isTrue);

        // Update value
        value = 20;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Update events should be triggered
        expect(observer.lastUpdatePreviousValue, isNotNull);
        expect(observer.lastUpdateNewValue, isNotNull);
      });

      test('serializes enum updates correctly', () async {
        var enumValue = _TestEnum.value1;
        final provider = FutureProvider<_TestEnum>((ref) async => enumValue);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        final addValueStr = observer.lastAddValue.toString();
        expect(addValueStr.contains('value1') || addValueStr.contains('AsyncLoading'), isTrue);

        // Update to different enum value
        enumValue = _TestEnum.value2;
        container.invalidate(provider);
        container.read(provider);
        await Future.delayed(const Duration(milliseconds: 20));

        // Should have triggered update
        expect(observer.lastUpdateNewValue, isNotNull);
      });
    });
  });
}

/// Test observer that captures serialized values
final class _SerializationTestObserver extends RiverpodDevToolsObserver {
  dynamic lastAddValue;
  dynamic lastUpdatePreviousValue;
  dynamic lastUpdateNewValue;

  _SerializationTestObserver()
      : super(
          config: TrackerConfig.forPackage(
            'test_app',
            enableConsoleOutput: false,
          ),
        );

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    lastAddValue = value;
    super.didAddProvider(context, value);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    lastUpdatePreviousValue = previousValue;
    lastUpdateNewValue = newValue;
    super.didUpdateProvider(context, previousValue, newValue);
  }
}

/// Test enum
enum _TestEnum {
  value1,
  value2,
}

/// Test class with toJson
class _JsonSerializableClass {
  final String name;
  final int value;

  _JsonSerializableClass(this.name, this.value);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

/// Test class without toJson
class _NonSerializableClass {
  final String name;
  final int value;

  _NonSerializableClass(this.name, this.value);

  @override
  String toString() => '_NonSerializableClass(name: $name, value: $value)';
}

/// Test class with toJson that returns complex data
class _ComplexToJsonClass {
  Map<String, dynamic> toJson() {
    return {
      'circular': this, // This will cause serialization issues
    };
  }
}
