import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  group('DiffEngine', () {
    group('Primitive Value Diffs', () {
      test('detects unchanged primitives', () {
        final diff = DiffEngine.diff(42, 42);
        expect(diff, isA<UnchangedDiff>());
        expect(diff.hasChanges, false);
      });

      test('detects modified primitives', () {
        final diff = DiffEngine.diff(42, 43);
        expect(diff, isA<ModifiedDiff>());
        expect(diff.hasChanges, true);

        final modDiff = diff as ModifiedDiff;
        expect(modDiff.oldValue, 42);
        expect(modDiff.newValue, 43);
      });

      test('handles null values correctly', () {
        final nullToNull = DiffEngine.diff(null, null);
        expect(nullToNull.hasChanges, false);

        final nullToValue = DiffEngine.diff(null, 42);
        expect(nullToValue, isA<TypeChangedDiff>());

        final valueToNull = DiffEngine.diff(42, null);
        expect(valueToNull, isA<TypeChangedDiff>());
      });

      test('detects type changes', () {
        final diff = DiffEngine.diff('42', 42);
        expect(diff, isA<TypeChangedDiff>());
        expect(diff.hasChanges, true);
      });
    });

    group('Map/Object Diffs', () {
      test('detects added keys', () {
        final oldMap = {'a': 1};
        final newMap = {'a': 1, 'b': 2};

        final diff = DiffEngine.diff(oldMap, newMap) as MapDiff;

        expect(diff.diffs.containsKey('b'), true);
        expect(diff.diffs['b'], isA<AddedDiff>());
        expect(diff.addedCount, 1);
      });

      test('detects removed keys', () {
        final oldMap = {'a': 1, 'b': 2};
        final newMap = {'a': 1};

        final diff = DiffEngine.diff(oldMap, newMap) as MapDiff;

        expect(diff.diffs.containsKey('b'), true);
        expect(diff.diffs['b'], isA<RemovedDiff>());
        expect(diff.removedCount, 1);
      });

      test('detects modified values', () {
        final oldMap = {'a': 1};
        final newMap = {'a': 2};

        final diff = DiffEngine.diff(oldMap, newMap) as MapDiff;

        expect(diff.diffs.containsKey('a'), true);
        expect(diff.diffs['a'], isA<ModifiedDiff>());
        expect(diff.modifiedCount, 1);
      });

      test('handles empty maps', () {
        final Map<String, dynamic> empty1 = {};
        final Map<String, dynamic> empty2 = {};
        final emptyToEmpty = DiffEngine.diff(empty1, empty2) as MapDiff;
        expect(emptyToEmpty.hasChanges, false);

        final Map<String, dynamic> emptyMap = {};
        final Map<String, dynamic> fullMap = {'a': 1};
        final emptyToFull = DiffEngine.diff(emptyMap, fullMap) as MapDiff;
        expect(emptyToFull.addedCount, 1);
      });

      test('handles nested maps', () {
        final oldMap = {
          'user': {'name': 'Alice', 'age': 25},
        };
        final newMap = {
          'user': {'name': 'Bob', 'age': 25},
        };

        final diff = DiffEngine.diff(oldMap, newMap) as MapDiff;

        expect(diff.diffs.containsKey('user'), true);
        final userDiff = diff.diffs['user'] as MapDiff;
        expect(userDiff.diffs.containsKey('name'), true);
        expect(userDiff.diffs['name'], isA<ModifiedDiff>());
      });

      test('handles maps with mixed value types', () {
        final oldMap = {'a': 1, 'b': 'hello', 'c': true};
        final newMap = {'a': 2, 'b': 'world', 'c': false};

        final diff = DiffEngine.diff(oldMap, newMap) as MapDiff;

        expect(diff.modifiedCount, 3);
      });
    });

    group('List/Array Diffs', () {
      test('detects added elements', () {
        final oldList = [1, 2];
        final newList = [1, 2, 3];

        final diff = DiffEngine.diff(oldList, newList) as ListDiff;

        expect(diff.diffs.containsKey(2), true);
        expect(diff.diffs[2], isA<AddedDiff>());
        expect(diff.oldLength, 2);
        expect(diff.newLength, 3);
      });

      test('detects removed elements', () {
        final oldList = [1, 2, 3];
        final newList = [1, 2];

        final diff = DiffEngine.diff(oldList, newList) as ListDiff;

        expect(diff.diffs.containsKey(2), true);
        expect(diff.diffs[2], isA<RemovedDiff>());
        expect(diff.oldLength, 3);
        expect(diff.newLength, 2);
      });

      test('detects modified elements', () {
        final oldList = [1, 2, 3];
        final newList = [1, 5, 3];

        final diff = DiffEngine.diff(oldList, newList) as ListDiff;

        expect(diff.diffs.containsKey(1), true);
        expect(diff.diffs[1], isA<ModifiedDiff>());
      });

      test('handles empty lists', () {
        final List<dynamic> empty1 = [];
        final List<dynamic> empty2 = [];
        final emptyToEmpty = DiffEngine.diff(empty1, empty2) as ListDiff;
        expect(emptyToEmpty.hasChanges, false);

        final List<dynamic> emptyList = [];
        final List<dynamic> fullList = [1];
        final emptyToFull = DiffEngine.diff(emptyList, fullList) as ListDiff;
        expect(emptyToFull.diffs.containsKey(0), true);
        expect(emptyToFull.diffs[0], isA<AddedDiff>());
      });

      test('handles nested lists', () {
        final oldList = [
          [1, 2],
          [3, 4],
        ];
        final newList = [
          [1, 2],
          [3, 5],
        ];

        final diff = DiffEngine.diff(oldList, newList) as ListDiff;

        expect(diff.diffs.containsKey(1), true);
        final innerDiff = diff.diffs[1] as ListDiff;
        expect(innerDiff.diffs.containsKey(1), true);
      });
    });

    group('Type Change Detection', () {
      test('detects type changes', () {
        final diff = DiffEngine.diff({'a': 1}, [1, 2]);
        expect(diff, isA<TypeChangedDiff>());
      });

      test('preserves old and new values', () {
        final diff = DiffEngine.diff('hello', 42) as TypeChangedDiff;
        expect(diff.oldValue, 'hello');
        expect(diff.newValue, 42);
      });
    });

    group('Edge Cases', () {
      test('handles very large objects', () {
        final Map<String, int> largeMap = Map.fromIterables(
          List.generate(1000, (i) => 'key$i'),
          List.generate(1000, (i) => i),
        );

        final Map<String, int> modifiedMap = Map.from(largeMap)
          ..['key500'] = 999;

        final diff = DiffEngine.diff(largeMap, modifiedMap) as MapDiff;

        expect(diff.modifiedCount, 1);
      });

      test('handles deeply nested structures', () {
        dynamic createNestedMap(int depth) {
          if (depth == 0) return 'leaf';
          return {'nested': createNestedMap(depth - 1)};
        }

        final oldMap = createNestedMap(10);
        final newMap = createNestedMap(10);

        final diff = DiffEngine.diff(oldMap, newMap);
        expect(diff.hasChanges, false);
      });

      test('handles DateTime objects', () {
        final date1 = DateTime(2024, 1, 1);
        final date2 = DateTime(2024, 1, 2);

        final diff = DiffEngine.diff(date1, date2);
        expect(diff, isA<ModifiedDiff>());
      });
    });
  });

  group('MapDiff', () {
    test('calculates statistics correctly', () {
      final diffs = {
        'added': const AddedDiff(42),
        'removed': const RemovedDiff(24),
        'modified': const ModifiedDiff(1, 2),
        'unchanged': const UnchangedDiff(10),
      };

      final mapDiff = MapDiff(diffs: diffs);

      expect(mapDiff.addedCount, 1);
      expect(mapDiff.removedCount, 1);
      expect(mapDiff.modifiedCount, 1);
      expect(mapDiff.hasChanges, true);
    });

    test('hasChanges returns false for unchanged map', () {
      final diffs = {
        'a': const UnchangedDiff(1),
        'b': const UnchangedDiff(2),
      };

      final mapDiff = MapDiff(diffs: diffs);
      expect(mapDiff.hasChanges, false);
    });
  });

  group('ValueDiff factories', () {
    test('unchanged factory creates UnchangedDiff', () {
      final diff = ValueDiff.unchanged(42);
      expect(diff, isA<UnchangedDiff>());
      expect((diff as UnchangedDiff).value, 42);
    });

    test('added factory creates AddedDiff', () {
      final diff = ValueDiff.added(42);
      expect(diff, isA<AddedDiff>());
      expect((diff as AddedDiff).value, 42);
    });

    test('removed factory creates RemovedDiff', () {
      final diff = ValueDiff.removed(42);
      expect(diff, isA<RemovedDiff>());
      expect((diff as RemovedDiff).value, 42);
    });

    test('modified factory creates ModifiedDiff', () {
      final diff = ValueDiff.modified(1, 2);
      expect(diff, isA<ModifiedDiff>());
      final modDiff = diff as ModifiedDiff;
      expect(modDiff.oldValue, 1);
      expect(modDiff.newValue, 2);
    });

    test('typeChanged factory creates TypeChangedDiff', () {
      final diff = ValueDiff.typeChanged('hello', 42);
      expect(diff, isA<TypeChangedDiff>());
      final typeDiff = diff as TypeChangedDiff;
      expect(typeDiff.oldValue, 'hello');
      expect(typeDiff.newValue, 42);
    });
  });
}
