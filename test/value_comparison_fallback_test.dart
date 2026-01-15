import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('Value Comparison Fallback Paths', () {
    test('primitive type direct comparison (num, bool, String)', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Test int
      final intProvider = Provider<int>((ref) => 42);
      container.read(intProvider);

      // Test double
      final doubleProvider = Provider<double>((ref) => 3.14);
      container.read(doubleProvider);

      // Test bool
      final boolProvider = Provider<bool>((ref) => true);
      container.read(boolProvider);

      // Test String
      final stringProvider = Provider<String>((ref) => 'test');
      container.read(stringProvider);

      expect(observer.addEvents.length, 4);

      container.dispose();
    });

    test('mixed primitive types comparison', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Test comparison of different primitive types
      final provider1 = Provider<Object>((ref) => 42); // int
      final provider2 = Provider<Object>((ref) => 3.14); // double
      final provider3 = Provider<Object>((ref) => true); // bool
      final provider4 = Provider<Object>((ref) => 'string'); // String

      container.read(provider1);
      container.read(provider2);
      container.read(provider3);
      container.read(provider4);

      expect(observer.addEvents.length, 4);

      container.dispose();
    });

    test('object with failing JSON serialization uses toString fallback', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create object that may have JSON serialization issues
      final testProvider = Provider<_NonSerializable>((ref) {
        return _NonSerializable('test', 42);
      });

      container.read(testProvider);

      // Should fall back to toString comparison
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('circular reference object uses toString fallback', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create circular reference
      final circular = _CircularReference();
      circular.self = circular;

      final provider = Provider<_CircularReference>((ref) => circular);
      container.read(provider);

      // Should handle circular reference gracefully with toString fallback
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('JSON encoding failure triggers toString comparison', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Use object that might fail JSON encoding
      final provider = Provider<_JsonEncodingFailure>((ref) {
        return _JsonEncodingFailure();
      });

      container.read(provider);

      // Should fall back to toString when JSON encoding fails
      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('complex nested structure serialization fallback', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Create complex nested structure that may challenge serialization
      final complexData = {
        'level1': {
          'level2': {
            'level3': {
              'object': _NonSerializable('nested', 123),
              'list': [1, 2, 3],
            }
          }
        }
      };

      final provider = Provider<Map<String, dynamic>>((ref) => complexData);
      container.read(provider);

      expect(observer.addEvents.length, 1);

      container.dispose();
    });

    test('serialization with special characters and unicode', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Test strings with special characters
      final specialStrings = [
        '{"key": "value"}', // JSON-like string
        'Line1\nLine2\nLine3', // Newlines
        'Tab\there', // Tabs
        'Unicode: 你好世界 🎉', // Unicode characters
        r'Raw string with \n', // Raw string
      ];

      for (var str in specialStrings) {
        final provider = Provider<String>((ref) => str);
        container.read(provider);
      }

      expect(observer.addEvents.length, specialStrings.length);

      container.dispose();
    });

    test('skipUnchangedValues with primitive comparison path', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      // Test that primitive values use direct comparison
      final provider = Provider<int>((ref) => 42);
      container.read(provider);

      // Invalidate and read again with same value
      container.invalidate(provider);
      container.read(provider);

      // Should have 1 add and 0 updates (value unchanged)
      expect(observer.addEvents.length, 1);
      expect(observer.updateEvents.length, 0);

      container.dispose();
    });

    test('object equality uses serialization comparison', () {
      final observer = _TestObserver();
      final container = ProviderContainer(observers: [observer]);

      var value = _SerializableData(name: 'test', count: 1);
      final provider = Provider<_SerializableData>((ref) => value);

      container.read(provider);

      // Update with different object but same values
      value = _SerializableData(name: 'test', count: 1);
      container.invalidate(provider);
      container.read(provider);

      // Should recognize as same value
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

/// Class that doesn't implement toJson and may have serialization issues
class _NonSerializable {
  final String name;
  final int value;

  _NonSerializable(this.name, this.value);

  @override
  String toString() => 'NonSerializable($name, $value)';
}

/// Class with circular reference
class _CircularReference {
  _CircularReference? self;

  @override
  String toString() => 'CircularReference';
}

/// Class that fails JSON encoding
class _JsonEncodingFailure {
  // Functions can't be JSON serialized
  void callback() {}

  @override
  String toString() => 'JsonEncodingFailure';
}

/// Serializable data class
class _SerializableData {
  final String name;
  final int count;

  _SerializableData({required this.name, required this.count});

  Map<String, dynamic> toJson() => {'name': name, 'count': count};

  @override
  String toString() => 'SerializableData($name, $count)';
}
