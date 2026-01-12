import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Value Equality Fallback Coverage', () {
    test('primitive types use direct comparison path (line 513-514)', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Test all primitive type combinations
      // int comparison
      final intProvider = Provider<int>((ref) => 42);
      container.read(intProvider);
      container.invalidate(intProvider);
      container.read(intProvider); // Same value, should not update

      // double comparison
      final doubleProvider = Provider<double>((ref) => 3.14);
      container.read(doubleProvider);
      container.invalidate(doubleProvider);
      container.read(doubleProvider);

      // bool comparison
      final boolProvider = Provider<bool>((ref) => true);
      container.read(boolProvider);
      container.invalidate(boolProvider);
      container.read(boolProvider);

      // String comparison
      final stringProvider = Provider<String>((ref) => 'test');
      container.read(stringProvider);
      container.invalidate(stringProvider);
      container.read(stringProvider);

      // All should have add events but no update events (values unchanged)
      expect(observer.addEvents.length, 4);
      expect(observer.updateEvents.length, 0);

      container.dispose();
    });

    test('serialization exception triggers catch block (line 494)', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Object that throws during serialization
      final provider = Provider<_ThrowOnSerialize>((ref) {
        return _ThrowOnSerialize();
      });

      // Should handle serialization exception gracefully
      container.read(provider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('JSON encoding failure uses string comparison (line 530-532)', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Object that serializes but fails JSON encoding
      var counter = 0;
      final provider = Provider<_ComplexObject>((ref) {
        return _ComplexObject(id: counter++, data: {'key': 'value'});
      });

      container.read(provider);
      container.invalidate(provider);
      container.read(provider);

      // Should have add and update events
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

      container.dispose();
    });

    test('complete serialization failure uses toString (line 536)', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Object that fails complete serialization
      var counter = 0;
      final provider = Provider<_FailSerialize>((ref) {
        return _FailSerialize(value: counter++);
      });

      container.read(provider);
      container.invalidate(provider);
      container.read(provider);

      // Should handle with toString fallback
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

      container.dispose();
    });

    test('mixed primitive and complex type comparisons', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Test primitive
      final intProvider = Provider<Object>((ref) => 42);
      container.read(intProvider);

      // Test complex object
      final objProvider = Provider<Object>((ref) => {'key': 'value'});
      container.read(objProvider);

      // Test mixed
      final mixedProvider = Provider<Object>((ref) => [1, 'two', true]);
      container.read(mixedProvider);

      expect(observer.addEvents.length, 3);

      container.dispose();
    });

    test('primitive types with different types are not equal', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = 0;
      final provider = Provider<Object>((ref) {
        if (value == 0) {
          return 42; // int
        } else if (value == 1) {
          return '42'; // String
        } else {
          return 42.0; // double
        }
      });

      container.read(provider);

      value = 1;
      container.invalidate(provider);
      container.read(provider); // Different type, should update

      value = 2;
      container.invalidate(provider);
      container.read(provider); // Different type again, should update

      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, 2);

      container.dispose();
    });

    test('object with circular reference uses toString fallback', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var counter = 0;
      final provider = Provider<_CircularRef>((ref) {
        final obj = _CircularRef(id: counter++);
        obj.self = obj; // Circular reference
        return obj;
      });

      container.read(provider);
      container.invalidate(provider);
      container.read(provider);

      // Should handle circular reference without crashing
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('object with non-serializable field uses fallback', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var counter = 0;
      final provider = Provider<_NonSerializableField>((ref) {
        return _NonSerializableField(
          id: counter++,
          callback: () {
            // Non-serializable callback
          },
        );
      });

      container.read(provider);
      container.invalidate(provider);
      container.read(provider);

      // Should handle non-serializable field gracefully
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, greaterThanOrEqualTo(1));

      container.dispose();
    });

    test('deeply nested object with serialization issues', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var counter = 0;
      final provider = Provider<Map<String, dynamic>>((ref) {
        return {
          'level1': {
            'level2': {
              'level3': {
                'object': _ThrowOnSerialize(),
                'id': counter++,
              }
            }
          }
        };
      });

      container.read(provider);
      container.invalidate(provider);
      container.read(provider);

      // Should handle nested serialization failure
      expect(observer.addEvents.length, 1);

      container.dispose();
    });
  });
}

/// Test observer that records events
final class _TestObserver extends RiverpodDevToolsObserver {
  final List<ProviderObserverContext> addEvents = [];
  final List<ProviderObserverContext> updateEvents = [];

  _TestObserver()
      : super(
          config: TrackerConfig.forPackage(
            'test_app',
            enableConsoleOutput: false,
            skipUnchangedValues: true,
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
}

/// Object that throws during serialization
class _ThrowOnSerialize {
  Object? toJson() {
    throw Exception('Serialization failed');
  }

  @override
  String toString() => 'ThrowOnSerialize';
}

/// Object with complex structure
class _ComplexObject {
  final int id;
  final Map<String, dynamic> data;

  _ComplexObject({required this.id, required this.data});

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data,
      };

  @override
  String toString() => 'ComplexObject($id)';
}

/// Object that fails serialization completely
class _FailSerialize {
  final int value;

  _FailSerialize({required this.value});

  @override
  String toString() => 'FailSerialize($value)';
}

/// Object with circular reference
class _CircularRef {
  final int id;
  _CircularRef? self;

  _CircularRef({required this.id});

  @override
  String toString() => 'CircularRef($id)';
}

/// Object with non-serializable field
class _NonSerializableField {
  final int id;
  final Function callback;

  _NonSerializableField({required this.id, required this.callback});

  Map<String, dynamic> toJson() => {
        'id': id,
        // callback is not serializable
      };

  @override
  String toString() => 'NonSerializableField($id)';
}
