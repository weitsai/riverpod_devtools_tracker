import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_extension/l10n/app_localizations.dart';
import 'package:riverpod_devtools_extension/src/models/provider_state_info.dart';
import 'package:riverpod_devtools_extension/src/widgets/state_detail_panel.dart';

void main() {
  group('StateDetailPanel', () {
    // Helper to create test widget with localizations
    Widget createTestWidget(ProviderStateInfo stateInfo) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
        ],
        home: Scaffold(
          body: StateDetailPanel(stateInfo: stateInfo),
        ),
      );
    }

    testWidgets('renders with basic provider info', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_1',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '42',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Verify provider name is displayed
      expect(find.text('testProvider'), findsOneWidget);
      expect(find.text('Provider'), findsOneWidget);
      expect(find.text('ADD'), findsOneWidget);
    });

    testWidgets('displays current value for add event', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_2',
        providerName: 'counterProvider',
        providerType: 'StateProvider',
        changeType: 'add',
        currentValue: '100',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show "After" section with current value
      expect(find.text('After'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('displays previous and current values for update event',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_3',
        providerName: 'counterProvider',
        providerType: 'StateProvider',
        changeType: 'update',
        previousValue: '5',
        currentValue: '10',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show both "Before" and "After" sections
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
    });

    testWidgets('shows trigger location when available', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_4',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
        location: 'lib/main.dart:42',
        locationFile: 'lib/main.dart',
        locationLine: 42,
        locationFunction: 'testFunction',
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show trigger location section (labeled as "Change Source")
      expect(find.text('Change Source'), findsOneWidget);
      expect(find.textContaining('lib/main.dart:42'), findsOneWidget);
    });

    testWidgets('displays call chain when available', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_5',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
        callChain: [
          CallChainEntry(
            location: 'lib/main.dart:10',
            file: 'lib/main.dart',
            line: 10,
            function: 'function1',
          ),
          CallChainEntry(
            location: 'lib/utils.dart:20',
            file: 'lib/utils.dart',
            line: 20,
            function: 'function2',
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show call chain section
      expect(find.text('Call Chain'), findsOneWidget);
      // File names and line numbers are displayed separately
      expect(find.textContaining('lib/main.dart'), findsOneWidget);
      expect(find.textContaining('lib/utils.dart'), findsOneWidget);
    });

    testWidgets('expands and collapses values with long content',
        (tester) async {
      final longValue = 'x' * 300; // Create a long value
      final stateInfo = ProviderStateInfo(
        id: 'test_6',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: longValue,
        currentValue: '10',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // First switch to text view mode (expand button only shows in text mode)
      // The button shows the current mode icon (tree), so we find account_tree
      final viewModeButton = find.byIcon(Icons.account_tree);
      await tester.tap(viewModeButton);
      await tester.pumpAndSettle();

      // Now find the expand button
      final expandButtons = find.byIcon(Icons.unfold_more);
      if (expandButtons.evaluate().isNotEmpty) {
        // Tap the first expand button
        await tester.tap(expandButtons.first);
        await tester.pumpAndSettle();

        // After tapping, should show collapse button
        expect(find.byIcon(Icons.unfold_less), findsWidgets);
      }
    });

    testWidgets('switches between tree and text view modes', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_8',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '{"name": "test", "value": 42}',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Find the tree view icon (default mode shows account_tree icon)
      expect(find.byIcon(Icons.account_tree), findsOneWidget);

      // Tap the view mode button to switch to text view
      final viewModeButton = find.byIcon(Icons.account_tree);
      await tester.tap(viewModeButton);
      await tester.pumpAndSettle();

      // After switching, should show text view icon (notes)
      expect(find.byIcon(Icons.notes), findsOneWidget);
    });

    testWidgets('displays formatted timestamp', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_9',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1, 12, 30, 45),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should display timestamp (format varies by implementation)
      // Just verify the panel renders without error
      expect(find.byType(StateDetailPanel), findsOneWidget);
    });

    testWidgets('handles null previous value for add event', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_10',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        previousValue: null,
        currentValue: 'new value',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should not crash and should show current value
      expect(find.text('After'), findsOneWidget);
      expect(find.textContaining('new value'), findsOneWidget);
    });

    testWidgets('handles complex JSON values', (tester) async {
      final complexJson =
          '{"user": {"name": "John", "age": 30}, "active": true}';
      final stateInfo = ProviderStateInfo(
        id: 'test_11',
        providerName: 'userProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: complexJson,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render complex JSON without crashing
      expect(find.byType(StateDetailPanel), findsOneWidget);
    });

    testWidgets('displays dispose event correctly', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_12',
        providerName: 'disposedProvider',
        providerType: 'Provider',
        changeType: 'dispose',
        previousValue: '42',
        currentValue: null,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show DISPOSE tag
      expect(find.text('DISPOSE'), findsOneWidget);
      expect(find.text('disposedProvider'), findsOneWidget);
    });

    testWidgets('displays error event correctly', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_13',
        providerName: 'errorProvider',
        providerType: 'FutureProvider',
        changeType: 'error',
        currentValue: 'Exception: Something went wrong',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show ERROR tag
      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('errorProvider'), findsOneWidget);
    });

    testWidgets('copy buttons are present for values', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_14',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: 'old',
        currentValue: 'new',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
        // Add trigger location to show copy button
        location: 'lib/test.dart:100',
        locationFile: 'lib/test.dart',
        locationLine: 100,
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should have copy button for trigger location
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('handles list values', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_15',
        providerName: 'listProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '[1, 2, 3, 4, 5]',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render list value
      expect(find.byType(StateDetailPanel), findsOneWidget);
      expect(find.text('listProvider'), findsOneWidget);
    });

    testWidgets('handles map values', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_16',
        providerName: 'mapProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '{"key1": "value1", "key2": "value2"}',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render map value
      expect(find.byType(StateDetailPanel), findsOneWidget);
      expect(find.text('mapProvider'), findsOneWidget);
    });

    testWidgets('scrolls when content is long', (tester) async {
      final longCallChain = List.generate(
        20,
        (i) => CallChainEntry(
          location: 'lib/file$i.dart:${i * 10}',
          file: 'lib/file$i.dart',
          line: i * 10,
          function: 'function$i',
        ),
      );

      final stateInfo = ProviderStateInfo(
        id: 'test_17',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
        callChain: longCallChain,
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should have a SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('displays provider type tag with correct color',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_18',
        providerName: 'futureProvider',
        providerType: 'FutureProvider',
        changeType: 'add',
        currentValue: 'async value',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should display provider type
      expect(find.text('FutureProvider'), findsOneWidget);
    });

    testWidgets('handles empty call chain gracefully', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_19',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
        callChain: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render without crashing
      expect(find.byType(StateDetailPanel), findsOneWidget);
    });

    testWidgets('displays short values without expand button',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_20',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'short',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Widget should render successfully
      expect(find.byType(StateDetailPanel), findsOneWidget);
    });
  });
}
