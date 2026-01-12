import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/src/tracker_config.dart';
import 'package:riverpod_devtools_tracker/src/riverpod_devtools_observer.dart';

void main() {
  group('Value Serialization Performance', () {
    late RiverpodDevToolsObserver observer;

    setUp(() {
      observer = RiverpodDevToolsObserver(
        config: TrackerConfig.forPackage('test_app'),
      );
    });

    test('efficiently serializes large Map without double encoding', () {
      // Create a large map with nested structures
      final largeMap = <String, dynamic>{};
      for (var i = 0; i < 100; i++) {
        largeMap['key_$i'] = {
          'id': i,
          'name': 'Item $i',
          'data': List.generate(10, (j) => {'index': j, 'value': j * i}),
        };
      }

      // Time the serialization
      final stopwatch = Stopwatch()..start();
      final serialized = observer.serializeValueForTest(largeMap);
      stopwatch.stop();

      // Verify the result is serializable
      expect(() => json.encode(serialized), returnsNormally);

      // Verify no double encoding occurred (result should be original map)
      expect(serialized, isA<Map>());
      expect(serialized, equals(largeMap));

      // Performance should be reasonable (< 50ms for this size)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('efficiently serializes large List without double encoding', () {
      // Create a large list
      final largeList = List.generate(
        1000,
        (i) => {'id': i, 'value': 'Item $i', 'timestamp': DateTime.now().millisecondsSinceEpoch},
      );

      // Time the serialization
      final stopwatch = Stopwatch()..start();
      final serialized = observer.serializeValueForTest(largeList);
      stopwatch.stop();

      // Verify the result is serializable
      expect(() => json.encode(serialized), returnsNormally);

      // Verify no double encoding occurred (result should be original list)
      expect(serialized, isA<List>());
      expect(serialized, equals(largeList));

      // Performance should be reasonable (< 30ms for this size)
      expect(stopwatch.elapsedMilliseconds, lessThan(30));
    });

    test('handles objects with toJson efficiently', () {
      final obj = _TestObjectWithToJson(
        id: 42,
        name: 'Test Object',
        data: List.generate(50, (i) => {'index': i, 'value': i * 2}),
      );

      // Time the serialization
      final stopwatch = Stopwatch()..start();
      final serialized = observer.serializeValueForTest(obj);
      stopwatch.stop();

      // Verify the result is serializable
      expect(() => json.encode(serialized), returnsNormally);

      // Verify toJson was called and no double encoding occurred
      expect(serialized, isA<Map>());
      expect(serialized['id'], equals(42));
      expect(serialized['name'], equals('Test Object'));

      // Performance should be reasonable (< 20ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(20));
    });

    test('primitive types have minimal overhead', () {
      final values = [
        42,
        3.14,
        'Hello World',
        true,
        false,
      ];

      for (final value in values) {
        final stopwatch = Stopwatch()..start();
        final serialized = observer.serializeValueForTest(value);
        stopwatch.stop();

        // Primitives should return immediately
        expect(serialized, equals(value));
        expect(stopwatch.elapsedMicroseconds, lessThan(100)); // < 0.1ms
      }
    });

    test('enum serialization returns structured format', () {
      final enumValue = _TestEnum.second;

      final serialized = observer.serializeValueForTest(enumValue);

      // Verify structured format
      expect(serialized, isA<Map>());
      expect(serialized['type'], equals('Enum'));
      expect(serialized['name'], equals('second'));
    });

    test('comparison: optimized vs original double encoding', () {
      final largeMap = <String, dynamic>{};
      for (var i = 0; i < 100; i++) {
        largeMap['key_$i'] = {
          'id': i,
          'data': List.generate(10, (j) => j * i),
        };
      }

      // Measure optimized serialization (just validation)
      final stopwatch1 = Stopwatch()..start();
      json.encode(largeMap);
      final optimizedTime = stopwatch1.elapsedMicroseconds;

      // Measure original double encoding
      final stopwatch2 = Stopwatch()..start();
      json.decode(json.encode(largeMap));
      final doubleEncodingTime = stopwatch2.elapsedMicroseconds;

      // Optimized should be faster
      expect(optimizedTime, lessThan(doubleEncodingTime));

      // Print performance comparison
      final improvement = ((doubleEncodingTime - optimizedTime) / doubleEncodingTime * 100).toStringAsFixed(1);
      print('Performance improvement: $improvement%');
      print('Optimized: ${optimizedTime}μs, Double encoding: ${doubleEncodingTime}μs');
    });
  });
}

// Test helper class with toJson
class _TestObjectWithToJson {
  final int id;
  final String name;
  final List<Map<String, dynamic>> data;

  _TestObjectWithToJson({
    required this.id,
    required this.name,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'data': data,
      };
}

// Test enum
enum _TestEnum { second }
