import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_extension/src/models/provider_state_info.dart';

void main() {
  group('ProviderStateInfo', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': 'test-id-123',
          'providerName': 'counterProvider',
          'providerType': 'StateProvider<int>',
          'previousValue': 0,
          'currentValue': 1,
          'timestamp': '2025-01-05T12:00:00.000Z',
          'changeType': 'update',
          'location': 'main.dart:42',
          'file': 'lib/main.dart',
          'line': 42,
          'function': 'increment',
          'callChain': [],
        };

        final info = ProviderStateInfo.fromJson(json);

        expect(info.id, 'test-id-123');
        expect(info.providerName, 'counterProvider');
        expect(info.providerType, 'StateProvider<int>');
        expect(info.previousValue, 0);
        expect(info.currentValue, 1);
        expect(info.changeType, 'update');
        expect(info.location, 'main.dart:42');
        expect(info.locationFile, 'lib/main.dart');
        expect(info.locationLine, 42);
        expect(info.locationFunction, 'increment');
      });

      test('handles missing optional fields with defaults', () {
        final json = <String, dynamic>{};

        final info = ProviderStateInfo.fromJson(json);

        expect(info.providerName, 'Unknown');
        expect(info.providerType, 'Unknown');
        expect(info.changeType, 'update');
        expect(info.callChain, isEmpty);
        expect(info.location, isNull);
      });

      test('parses callChain entries', () {
        final json = {
          'id': 'test-id',
          'providerName': 'testProvider',
          'providerType': 'Provider',
          'timestamp': '2025-01-05T12:00:00.000Z',
          'changeType': 'update',
          'callChain': [
            {
              'location': 'main.dart:10',
              'file': 'lib/main.dart',
              'line': 10,
              'function': 'onPressed',
            },
          ],
        };

        final info = ProviderStateInfo.fromJson(json);

        expect(info.callChain.length, 1);
        expect(info.callChain[0].location, 'main.dart:10');
        expect(info.callChain[0].file, 'lib/main.dart');
        expect(info.callChain[0].line, 10);
        expect(info.callChain[0].function, 'onPressed');
      });
    });

    group('toJson', () {
      test('serializes to JSON correctly', () {
        final info = ProviderStateInfo(
          id: 'test-id',
          providerName: 'counterProvider',
          providerType: 'StateProvider<int>',
          previousValue: 0,
          currentValue: 1,
          timestamp: DateTime.parse('2025-01-05T12:00:00.000Z'),
          changeType: 'update',
        );

        final json = info.toJson();

        expect(json['id'], 'test-id');
        expect(json['providerName'], 'counterProvider');
        expect(json['providerType'], 'StateProvider<int>');
        expect(json['previousValue'], 0);
        expect(json['currentValue'], 1);
        expect(json['changeType'], 'update');
        expect(json['timestamp'], '2025-01-05T12:00:00.000Z');
      });
    });

    group('formattedValue', () {
      test('formats null value', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: null,
          currentValue: null,
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedPreviousValue, 'null');
        expect(info.formattedCurrentValue, 'null');
      });

      test('formats primitive values', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: 42,
          currentValue: 'hello',
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedPreviousValue, '42');
        expect(info.formattedCurrentValue, 'hello');
      });

      test('formats Map with type and value fields', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: null,
          currentValue: {'type': 'int', 'value': '42'},
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedCurrentValue, '42');
      });

      test('formats error Map', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: null,
          currentValue: {'type': 'Exception', 'error': 'Something went wrong'},
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedCurrentValue, 'Error: Something went wrong');
      });

      test('formats AsyncLoading empty', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: null,
          currentValue: 'AsyncLoading<String>()',
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedCurrentValue, contains('Loading'));
        expect(info.formattedCurrentValue, contains('String'));
      });

      test('formats AsyncLoading with previous value', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: null,
          currentValue: 'AsyncLoading<int>(value: 42)',
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedCurrentValue, contains('Loading'));
        expect(info.formattedCurrentValue, contains('42'));
      });

      test('formats AsyncData', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: null,
          currentValue: 'AsyncData<String>(value: hello world)',
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedCurrentValue, contains('Data'));
        expect(info.formattedCurrentValue, contains('hello world'));
      });

      test('formats AsyncError', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          previousValue: null,
          currentValue:
              'AsyncError<String>(error: Network error, stackTrace: ...)',
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.formattedCurrentValue, contains('Error'));
        expect(info.formattedCurrentValue, contains('Network error'));
      });
    });

    group('triggerLocation', () {
      test('returns location from direct fields when available', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          timestamp: DateTime.now(),
          changeType: 'update',
          locationFile: 'lib/main.dart',
          locationLine: 42,
          locationFunction: 'onTap',
        );

        final trigger = info.triggerLocation;

        expect(trigger, isNotNull);
        expect(trigger!.file, 'lib/main.dart');
        expect(trigger.line, 42);
        expect(trigger.function, 'onTap');
      });

      test('returns first entry from callChain when no direct location', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          timestamp: DateTime.now(),
          changeType: 'update',
          callChain: [
            CallChainEntry(
              location: 'home.dart:50',
              file: 'lib/screens/home.dart',
              line: 50,
              function: 'build',
            ),
            CallChainEntry(
              location: 'main.dart:10',
              file: 'lib/main.dart',
              line: 10,
              function: 'main',
            ),
          ],
        );

        final trigger = info.triggerLocation;

        expect(trigger, isNotNull);
        expect(trigger!.file, 'lib/screens/home.dart');
        expect(trigger.line, 50);
        expect(trigger.function, 'build');
      });

      test('returns null when no location info available', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.triggerLocation, isNull);
      });
    });

    group('hasLocation', () {
      test('returns true when location is set', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          timestamp: DateTime.now(),
          changeType: 'update',
          location: 'main.dart:42',
        );

        expect(info.hasLocation, true);
      });

      test('returns true when locationFile is set', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          timestamp: DateTime.now(),
          changeType: 'update',
          locationFile: 'lib/main.dart',
        );

        expect(info.hasLocation, true);
      });

      test('returns false when no location info', () {
        final info = ProviderStateInfo(
          id: 'test',
          providerName: 'test',
          providerType: 'test',
          timestamp: DateTime.now(),
          changeType: 'update',
        );

        expect(info.hasLocation, false);
      });
    });
  });

  group('StackTraceEntry', () {
    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'file': 'lib/main.dart',
          'line': 42,
          'column': 10,
          'function': 'main',
          'library': 'package:my_app/main.dart',
        };

        final entry = StackTraceEntry.fromJson(json);

        expect(entry.file, 'lib/main.dart');
        expect(entry.line, 42);
        expect(entry.column, 10);
        expect(entry.function, 'main');
        expect(entry.library, 'package:my_app/main.dart');
      });

      test('handles missing optional fields', () {
        final json = {'file': 'lib/main.dart'};

        final entry = StackTraceEntry.fromJson(json);

        expect(entry.file, 'lib/main.dart');
        expect(entry.line, isNull);
        expect(entry.column, isNull);
        expect(entry.function, isNull);
        expect(entry.library, isNull);
      });

      test('handles empty JSON', () {
        final entry = StackTraceEntry.fromJson({});

        expect(entry.file, '');
      });
    });

    group('toJson', () {
      test('serializes to JSON', () {
        final entry = StackTraceEntry(
          file: 'lib/main.dart',
          line: 42,
          column: 10,
          function: 'main',
          library: 'package:my_app/main.dart',
        );

        final json = entry.toJson();

        expect(json['file'], 'lib/main.dart');
        expect(json['line'], 42);
        expect(json['column'], 10);
        expect(json['function'], 'main');
        expect(json['library'], 'package:my_app/main.dart');
      });
    });

    group('isFramework', () {
      test('returns true for flutter package', () {
        final entry = StackTraceEntry(file: 'package:flutter/widgets.dart');
        expect(entry.isFramework, true);
      });

      test('returns true for dart: prefix', () {
        final entry = StackTraceEntry(file: 'dart:async/future.dart');
        expect(entry.isFramework, true);
      });

      test('returns true for flutter/ path', () {
        final entry = StackTraceEntry(file: 'flutter/lib/src/widgets.dart');
        expect(entry.isFramework, true);
      });

      test('returns false for user code', () {
        final entry = StackTraceEntry(file: 'lib/main.dart');
        expect(entry.isFramework, false);
      });

      test('returns false for user package', () {
        final entry = StackTraceEntry(file: 'package:my_app/main.dart');
        expect(entry.isFramework, false);
      });
    });

    group('isRiverpodInternal', () {
      test('returns true for package:riverpod/', () {
        final entry = StackTraceEntry(file: 'package:riverpod/riverpod.dart');
        expect(entry.isRiverpodInternal, true);
      });

      test('returns true for package:flutter_riverpod/', () {
        final entry = StackTraceEntry(
          file: 'package:flutter_riverpod/flutter_riverpod.dart',
        );
        expect(entry.isRiverpodInternal, true);
      });

      test('returns true for _notifyListeners function', () {
        final entry = StackTraceEntry(
          file: 'lib/provider.dart',
          function: '_notifyListeners',
        );
        expect(entry.isRiverpodInternal, true);
      });

      test('returns true for ProviderElementBase function', () {
        final entry = StackTraceEntry(
          file: 'lib/provider.dart',
          function: 'ProviderElementBase.setState',
        );
        expect(entry.isRiverpodInternal, true);
      });

      test('returns false for user code', () {
        final entry = StackTraceEntry(
          file: 'lib/main.dart',
          function: 'increment',
        );
        expect(entry.isRiverpodInternal, false);
      });
    });

    group('shortFileName', () {
      test('returns last path segment', () {
        final entry = StackTraceEntry(file: 'lib/src/screens/home.dart');
        expect(entry.shortFileName, 'home.dart');
      });

      test('returns file if no path separator', () {
        final entry = StackTraceEntry(file: 'main.dart');
        expect(entry.shortFileName, 'main.dart');
      });

      test('handles package path', () {
        final entry = StackTraceEntry(
          file: 'package:my_app/src/screens/home.dart',
        );
        expect(entry.shortFileName, 'home.dart');
      });
    });

    group('formattedLocation', () {
      test('returns file:line:column when all present', () {
        final entry = StackTraceEntry(
          file: 'lib/main.dart',
          line: 42,
          column: 10,
        );
        expect(entry.formattedLocation, 'main.dart:42:10');
      });

      test('returns file:line when no column', () {
        final entry = StackTraceEntry(file: 'lib/main.dart', line: 42);
        expect(entry.formattedLocation, 'main.dart:42');
      });

      test('returns file only when no line', () {
        final entry = StackTraceEntry(file: 'lib/main.dart');
        expect(entry.formattedLocation, 'main.dart');
      });
    });

    group('toString', () {
      test('formats with all fields', () {
        final entry = StackTraceEntry(
          file: 'lib/main.dart',
          line: 42,
          column: 10,
          function: 'main',
        );
        expect(entry.toString(), 'lib/main.dart:42:10 in main');
      });

      test('formats without column', () {
        final entry = StackTraceEntry(
          file: 'lib/main.dart',
          line: 42,
          function: 'main',
        );
        expect(entry.toString(), 'lib/main.dart:42 in main');
      });

      test('formats with unknown function', () {
        final entry = StackTraceEntry(file: 'lib/main.dart', line: 42);
        expect(entry.toString(), 'lib/main.dart:42 in unknown');
      });
    });
  });

  group('CallChainEntry', () {
    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'location': 'main.dart:42',
          'file': 'lib/main.dart',
          'line': 42,
          'function': 'onPressed',
        };

        final entry = CallChainEntry.fromJson(json);

        expect(entry.location, 'main.dart:42');
        expect(entry.file, 'lib/main.dart');
        expect(entry.line, 42);
        expect(entry.function, 'onPressed');
      });

      test('handles missing fields with defaults', () {
        final entry = CallChainEntry.fromJson({});

        expect(entry.location, '');
        expect(entry.file, '');
        expect(entry.line, 0);
        expect(entry.function, '');
      });

      test('handles partial JSON', () {
        final json = {'location': 'main.dart:10', 'file': 'lib/main.dart'};

        final entry = CallChainEntry.fromJson(json);

        expect(entry.location, 'main.dart:10');
        expect(entry.file, 'lib/main.dart');
        expect(entry.line, 0);
        expect(entry.function, '');
      });
    });
  });
}
