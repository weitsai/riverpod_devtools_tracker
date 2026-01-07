import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('TrackerConfig', () {
    test('default config has correct values', () {
      const config = TrackerConfig();

      expect(config.enabled, true);
      expect(config.packagePrefixes, isEmpty);
      expect(config.enableConsoleOutput, true);
      expect(config.prettyConsoleOutput, true);
      expect(config.maxCallChainDepth, 10);
      expect(config.maxValueLength, 200);
      expect(config.ignoredPackagePrefixes, contains('package:flutter/'));
      expect(
        config.ignoredPackagePrefixes,
        contains('package:flutter_riverpod/'),
      );
      expect(config.ignoredPackagePrefixes, contains('package:riverpod/'));
      expect(config.ignoredPackagePrefixes, contains('dart:'));
    });

    test('forPackage factory creates correct config', () {
      final config = TrackerConfig.forPackage(
        'my_app',
        maxCallChainDepth: 5,
        enableConsoleOutput: false,
      );

      expect(config.packagePrefixes, contains('package:my_app/'));
      expect(config.maxCallChainDepth, 5);
      expect(config.enableConsoleOutput, false);
      expect(config.enabled, true);
    });

    test('forPackage with additional packages', () {
      final config = TrackerConfig.forPackage(
        'my_app',
        additionalPackages: ['package:my_common/', 'package:my_utils/'],
      );

      expect(config.packagePrefixes, contains('package:my_app/'));
      expect(config.packagePrefixes, contains('package:my_common/'));
      expect(config.packagePrefixes, contains('package:my_utils/'));
    });

    test('copyWith creates modified copy', () {
      const original = TrackerConfig(enabled: true, maxCallChainDepth: 10);

      final modified = original.copyWith(enabled: false, maxCallChainDepth: 5);

      expect(modified.enabled, false);
      expect(modified.maxCallChainDepth, 5);
      expect(modified.enableConsoleOutput, original.enableConsoleOutput);
    });

    test('copyWith preserves unmodified values', () {
      final original = TrackerConfig.forPackage('test_app');
      final modified = original.copyWith(enabled: false);

      expect(modified.enabled, false);
      expect(modified.packagePrefixes, original.packagePrefixes);
      expect(modified.maxCallChainDepth, original.maxCallChainDepth);
      expect(modified.ignoredPackagePrefixes, original.ignoredPackagePrefixes);
    });
  });

  group('LocationInfo', () {
    test('creates with required fields', () {
      const location = LocationInfo(
        location: 'lib/main.dart:42',
        file: 'lib/main.dart',
        line: 42,
        function: 'main',
      );

      expect(location.location, 'lib/main.dart:42');
      expect(location.file, 'lib/main.dart');
      expect(location.line, 42);
      expect(location.function, 'main');
      expect(location.column, isNull);
    });

    test('creates with optional column', () {
      const location = LocationInfo(
        location: 'lib/main.dart:42:10',
        file: 'lib/main.dart',
        line: 42,
        function: 'main',
        column: 10,
      );

      expect(location.column, 10);
    });

    test('toJson returns correct map', () {
      const location = LocationInfo(
        location: 'lib/main.dart:42',
        file: 'lib/main.dart',
        line: 42,
        function: 'main',
      );

      final json = location.toJson();

      expect(json['location'], 'lib/main.dart:42');
      expect(json['file'], 'lib/main.dart');
      expect(json['line'], 42);
      expect(json['function'], 'main');
      expect(json.containsKey('column'), false);
    });

    test('toJson includes column when present', () {
      const location = LocationInfo(
        location: 'lib/main.dart:42:10',
        file: 'lib/main.dart',
        line: 42,
        function: 'main',
        column: 10,
      );

      final json = location.toJson();

      expect(json['column'], 10);
    });

    test('toString returns location string', () {
      const location = LocationInfo(
        location: 'lib/main.dart:42',
        file: 'lib/main.dart',
        line: 42,
        function: 'main',
      );

      expect(location.toString(), 'lib/main.dart:42');
    });
  });

  group('StackTraceParser', () {
    late StackTraceParser parser;

    setUp(() {
      parser = StackTraceParser(TrackerConfig.forPackage('test_app'));
    });

    test('parseCallChain returns empty list for empty trace', () {
      final stackTrace = StackTrace.fromString('');
      final chain = parser.parseCallChain(stackTrace);

      expect(chain, isEmpty);
    });

    test('parseCallChain respects maxCallChainDepth', () {
      final parser = StackTraceParser(
        TrackerConfig.forPackage('test_app', maxCallChainDepth: 2),
      );

      final stackTrace = StackTrace.fromString('''
#0      func1 (package:test_app/file1.dart:10:5)
#1      func2 (package:test_app/file2.dart:20:5)
#2      func3 (package:test_app/file3.dart:30:5)
#3      func4 (package:test_app/file4.dart:40:5)
''');

      final chain = parser.parseCallChain(stackTrace);

      expect(chain.length, 2);
    });

    test('parseCallChain filters ignored packages', () {
      final stackTrace = StackTrace.fromString('''
#0      userFunc (package:test_app/main.dart:10:5)
#1      flutterFunc (package:flutter/widgets.dart:100:5)
#2      riverpodFunc (package:riverpod/riverpod.dart:50:5)
#3      anotherUserFunc (package:test_app/screen.dart:20:5)
''');

      final chain = parser.parseCallChain(stackTrace);

      expect(chain.length, 2);
      expect(chain[0].function, 'userFunc');
      expect(chain[1].function, 'anotherUserFunc');
    });

    test('parseCallChain parses line and column correctly', () {
      final stackTrace = StackTrace.fromString('''
#0      myFunction (package:test_app/main.dart:42:15)
''');

      final chain = parser.parseCallChain(stackTrace);

      expect(chain.length, 1);
      expect(chain[0].line, 42);
      expect(chain[0].column, 15);
      expect(chain[0].function, 'myFunction');
    });

    test('findTriggerLocation returns first non-provider location', () {
      final stackTrace = StackTrace.fromString('''
#0      providerFunc (package:test_app/providers/counter_provider.dart:10:5)
#1      triggerFunc (package:test_app/screens/home.dart:20:5)
#2      otherFunc (package:test_app/main.dart:30:5)
''');

      final trigger = parser.findTriggerLocation(stackTrace);

      expect(trigger, isNotNull);
      expect(trigger!.function, 'triggerFunc');
    });

    test(
      'findTriggerLocation returns first location if all are provider files',
      () {
        final stackTrace = StackTrace.fromString('''
#0      func1 (package:test_app/providers/provider1.dart:10:5)
#1      func2 (package:test_app/providers/provider2.dart:20:5)
''');

        final trigger = parser.findTriggerLocation(stackTrace);

        expect(trigger, isNotNull);
        expect(trigger!.function, 'func1');
      },
    );

    test('findTriggerLocation returns null for empty trace', () {
      final stackTrace = StackTrace.fromString('');
      final trigger = parser.findTriggerLocation(stackTrace);

      expect(trigger, isNull);
    });

    test('parseCallChain handles generated files', () {
      final stackTrace = StackTrace.fromString('''
#0      generatedFunc (package:test_app/models/user.g.dart:10:5)
#1      userFunc (package:test_app/main.dart:20:5)
''');

      final chain = parser.parseCallChain(stackTrace);

      // Both should be included since ignoredFilePatterns is empty by default
      expect(chain.length, 2);
    });

    test('parseCallChain with ignoredFilePatterns', () {
      final parser = StackTraceParser(
        TrackerConfig.forPackage('test_app', ignoredFilePatterns: ['.g.dart']),
      );

      final stackTrace = StackTrace.fromString('''
#0      generatedFunc (package:test_app/models/user.g.dart:10:5)
#1      userFunc (package:test_app/main.dart:20:5)
''');

      final chain = parser.parseCallChain(stackTrace);

      expect(chain.length, 1);
      expect(chain[0].function, 'userFunc');
    });
  });
}
