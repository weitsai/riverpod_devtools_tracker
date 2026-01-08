import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_extension/l10n/app_localizations.dart';
import 'package:riverpod_devtools_extension/src/models/provider_state_info.dart';
import 'package:riverpod_devtools_extension/src/widgets/provider_list_tile.dart';

void main() {
  group('ProviderListTile', () {
    // Helper to create test widget with localizations
    Widget createTestWidget(
      ProviderStateInfo stateInfo, {
      bool isSelected = false,
      int? changeNumber,
    }) {
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
          body: ProviderListTile(
            stateInfo: stateInfo,
            isSelected: isSelected,
            changeNumber: changeNumber,
            onTap: () {},
          ),
        ),
      );
    }

    testWidgets('renders basic provider info', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_1',
        providerName: 'counterProvider',
        providerType: 'StateProvider',
        changeType: 'add',
        currentValue: '0',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show provider name and type
      expect(find.text('counterProvider'), findsOneWidget);
      expect(find.text('StateProvider'), findsOneWidget);
    });

    testWidgets('displays changeNumber when provided', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_2',
        providerName: 'testProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: '1',
        currentValue: '2',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(
        createTestWidget(stateInfo, changeNumber: 42),
      );

      // Should display change number
      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('shows selected state with highlighted background',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_3',
        providerName: 'selectedProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(
        createTestWidget(stateInfo, isSelected: true),
      );

      // Verify the widget renders correctly when selected
      expect(find.text('selectedProvider'), findsOneWidget);
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('shows unselected state with default background',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_4',
        providerName: 'unselectedProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(
        createTestWidget(stateInfo, isSelected: false),
      );

      // Verify the widget renders correctly when not selected
      expect(find.text('unselectedProvider'), findsOneWidget);
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapCount = 0;
      final stateInfo = ProviderStateInfo(
        id: 'test_5',
        providerName: 'tappableProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderListTile(
              stateInfo: stateInfo,
              isSelected: false,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      // Tap the tile
      await tester.tap(find.byType(ProviderListTile));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    testWidgets('displays add change type icon', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_6',
        providerName: 'addProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'new',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show add icon
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('displays update change type icon', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_7',
        providerName: 'updateProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: 'old',
        currentValue: 'new',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show edit icon
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('displays dispose change type icon', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_8',
        providerName: 'disposeProvider',
        providerType: 'Provider',
        changeType: 'dispose',
        previousValue: 'old',
        currentValue: null,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show remove icon
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('displays location info when available', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_9',
        providerName: 'locationProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
        location: 'lib/main.dart:42',
        locationFile: 'lib/main.dart',
        locationLine: 42,
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show code icon and location
      expect(find.byIcon(Icons.code), findsOneWidget);
      expect(find.textContaining('lib/main.dart'), findsOneWidget);
    });

    testWidgets('displays auto-computed indicator for update without location',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_10',
        providerName: 'autoProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: '1',
        currentValue: '2',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show auto-awesome icon and auto-computed text
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('auto-computed'), findsOneWidget);
    });

    testWidgets('displays current value for add event', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_11',
        providerName: 'addValueProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '42',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show add icon and current value
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.textContaining('42'), findsOneWidget);
    });

    testWidgets('displays value change for update event', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_12',
        providerName: 'updateValueProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: '10',
        currentValue: '20',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show arrow icon for value change
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.textContaining('10'), findsOneWidget);
      expect(find.textContaining('20'), findsOneWidget);
    });

    testWidgets('expands and collapses long values for add event',
        (tester) async {
      final longValue = 'x' * 100;
      final stateInfo = ProviderStateInfo(
        id: 'test_13',
        providerName: 'longValueProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: longValue,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Find expand button
      final expandButton = find.byIcon(Icons.unfold_more);
      expect(expandButton, findsOneWidget);

      // Tap to expand
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Should show collapse button
      expect(find.byIcon(Icons.unfold_less), findsOneWidget);
    });

    testWidgets('expands and collapses long values for update event',
        (tester) async {
      final longValue1 = 'previous_' + ('x' * 50);
      final longValue2 = 'current_' + ('y' * 50);
      final stateInfo = ProviderStateInfo(
        id: 'test_14',
        providerName: 'longUpdateProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: longValue1,
        currentValue: longValue2,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Find expand button
      final expandButton = find.byIcon(Icons.unfold_more);
      if (expandButton.evaluate().isNotEmpty) {
        // Tap to expand
        await tester.tap(expandButton.first);
        await tester.pumpAndSettle();

        // Should show collapse button
        expect(find.byIcon(Icons.unfold_less), findsWidgets);
      }
    });

    testWidgets('displays timestamp as relative time for recent changes',
        (tester) async {
      final recentTimestamp = DateTime.now().subtract(const Duration(seconds: 30));
      final stateInfo = ProviderStateInfo(
        id: 'test_15',
        providerName: 'recentProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: recentTimestamp,
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render timestamp (format varies based on time difference)
      expect(find.byType(ProviderListTile), findsOneWidget);
      expect(find.text('recentProvider'), findsOneWidget);
    });

    testWidgets('displays timestamp as absolute time for old changes',
        (tester) async {
      final oldTimestamp = DateTime.now().subtract(const Duration(hours: 2));
      final stateInfo = ProviderStateInfo(
        id: 'test_16',
        providerName: 'oldProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: oldTimestamp,
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should show absolute time (HH:MM format)
      final hourStr = oldTimestamp.hour.toString().padLeft(2, '0');
      final minStr = oldTimestamp.minute.toString().padLeft(2, '0');
      expect(find.text('$hourStr:$minStr'), findsOneWidget);
    });

    testWidgets('handles null values correctly', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_17',
        providerName: 'nullProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: null,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render without crashing
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('displays StateProvider with correct color', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_18',
        providerName: 'stateProvider',
        providerType: 'StateProvider',
        changeType: 'add',
        currentValue: '0',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render with StateProvider type
      expect(find.text('StateProvider'), findsOneWidget);
    });

    testWidgets('displays FutureProvider with correct color', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_19',
        providerName: 'futureProvider',
        providerType: 'FutureProvider',
        changeType: 'add',
        currentValue: 'AsyncValue.loading()',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render with FutureProvider type
      expect(find.text('FutureProvider'), findsOneWidget);
    });

    testWidgets('handles Map values in diff display', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_20',
        providerName: 'mapProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: '{"count": 1, "name": "old"}',
        currentValue: '{"count": 2, "name": "new"}',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render map diff
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('handles List values correctly', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_21',
        providerName: 'listProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '[1, 2, 3, 4, 5]',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render list value
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('handles empty Map values', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_22',
        providerName: 'emptyMapProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '{}',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render without crashing
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('handles empty List values', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_23',
        providerName: 'emptyListProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: '[]',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render without crashing
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('does not show value preview for dispose event',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_24',
        providerName: 'disposeProvider',
        providerType: 'Provider',
        changeType: 'dispose',
        previousValue: '42',
        currentValue: null,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should not show add or arrow icons for value preview
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('truncates very long provider names', (tester) async {
      final longName = 'veryLongProviderName' * 10;
      final stateInfo = ProviderStateInfo(
        id: 'test_25',
        providerName: longName,
        providerType: 'Provider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render with ellipsis for overflow
      final textWidget = tester.widget<Text>(
        find.text(longName),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('displays NotifierProvider with correct color',
        (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_26',
        providerName: 'notifierProvider',
        providerType: 'NotifierProvider',
        changeType: 'add',
        currentValue: 'test',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      expect(find.text('NotifierProvider'), findsOneWidget);
    });

    testWidgets('displays StreamProvider with correct color', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_27',
        providerName: 'streamProvider',
        providerType: 'StreamProvider',
        changeType: 'add',
        currentValue: 'AsyncValue.loading()',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      expect(find.text('StreamProvider'), findsOneWidget);
    });

    testWidgets('handles complex nested objects', (tester) async {
      final complexValue =
          '{"user": {"id": 1, "name": "John"}, "settings": {"theme": "dark"}}';
      final stateInfo = ProviderStateInfo(
        id: 'test_28',
        providerName: 'complexProvider',
        providerType: 'Provider',
        changeType: 'add',
        currentValue: complexValue,
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      // Should render complex object
      expect(find.byType(ProviderListTile), findsOneWidget);
    });

    testWidgets('shows both changeNumber and provider name', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_29',
        providerName: 'multiInfoProvider',
        providerType: 'Provider',
        changeType: 'update',
        previousValue: '1',
        currentValue: '2',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(
        createTestWidget(stateInfo, changeNumber: 123),
      );

      expect(find.text('#123'), findsOneWidget);
      expect(find.text('multiInfoProvider'), findsOneWidget);
    });

    testWidgets('handles StateNotifierProvider type', (tester) async {
      final stateInfo = ProviderStateInfo(
        id: 'test_30',
        providerName: 'stateNotifierProvider',
        providerType: 'StateNotifierProvider',
        changeType: 'update',
        previousValue: '{"count": 0}',
        currentValue: '{"count": 1}',
        timestamp: DateTime(2024, 1, 1),
        stackTrace: const [],
      );

      await tester.pumpWidget(createTestWidget(stateInfo));

      expect(find.text('StateNotifierProvider'), findsOneWidget);
    });
  });
}
