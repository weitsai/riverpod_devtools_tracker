/// Core diff engine for comparing values and generating diffs
library;

import 'dart:math' as math;
import 'value_diff.dart';

/// Core diff engine for comparing values
class DiffEngine {
  /// Compare two values and produce a diff
  ///
  /// Handles:
  /// - Primitive values (null, num, String, bool)
  /// - Maps/Objects
  /// - Lists/Arrays
  /// - Type changes
  static ValueDiff diff(dynamic oldValue, dynamic newValue) {
    // Identical values (including null == null)
    if (identical(oldValue, newValue)) {
      return ValueDiff.unchanged(oldValue);
    }

    // Deep equality check for primitives
    if (oldValue == newValue) {
      return ValueDiff.unchanged(oldValue);
    }

    // Type changed - check before primitive check
    if (oldValue.runtimeType != newValue.runtimeType) {
      return ValueDiff.typeChanged(oldValue, newValue);
    }

    // Primitive values
    if (_isPrimitive(oldValue) && _isPrimitive(newValue)) {
      return ValueDiff.modified(oldValue, newValue);
    }

    // Objects/Maps
    if (oldValue is Map && newValue is Map) {
      return _diffMaps(oldValue, newValue);
    }

    // Lists/Arrays
    if (oldValue is List && newValue is List) {
      return _diffLists(oldValue, newValue);
    }

    // Fallback: treat as different
    return ValueDiff.modified(oldValue, newValue);
  }

  /// Diff two maps
  static MapDiff _diffMaps(Map<dynamic, dynamic> oldMap, Map<dynamic, dynamic> newMap) {
    final diffs = <String, ValueDiff>{};
    final allKeys = {...oldMap.keys, ...newMap.keys};

    for (final key in allKeys) {
      final keyStr = key.toString();
      final oldHas = oldMap.containsKey(key);
      final newHas = newMap.containsKey(key);

      if (!oldHas && newHas) {
        // Key added
        diffs[keyStr] = ValueDiff.added(newMap[key]);
      } else if (oldHas && !newHas) {
        // Key removed
        diffs[keyStr] = ValueDiff.removed(oldMap[key]);
      } else {
        // Both have the key, check if value changed
        final oldVal = oldMap[key];
        final newVal = newMap[key];

        final valueDiff = diff(oldVal, newVal);
        // Only include if there are changes
        if (valueDiff.hasChanges) {
          diffs[keyStr] = valueDiff;
        }
      }
    }

    return MapDiff(diffs: diffs);
  }

  /// Diff two lists
  ///
  /// Uses simple index-based comparison.
  /// For better results with insertions/deletions, consider implementing
  /// LCS (Longest Common Subsequence) algorithm.
  static ListDiff _diffLists(List<dynamic> oldList, List<dynamic> newList) {
    final diffs = <int, ValueDiff>{};
    final maxLength = math.max(oldList.length, newList.length);

    for (int i = 0; i < maxLength; i++) {
      if (i >= oldList.length) {
        // Element added at end
        diffs[i] = ValueDiff.added(newList[i]);
      } else if (i >= newList.length) {
        // Element removed from end
        diffs[i] = ValueDiff.removed(oldList[i]);
      } else {
        // Both have element at index i, check if changed
        final valueDiff = diff(oldList[i], newList[i]);
        if (valueDiff.hasChanges) {
          diffs[i] = valueDiff;
        }
      }
    }

    return ListDiff(
      diffs: diffs,
      oldLength: oldList.length,
      newLength: newList.length,
    );
  }

  /// Check if a value is primitive (null, num, String, bool)
  static bool _isPrimitive(dynamic value) {
    return value == null ||
        value is num ||
        value is String ||
        value is bool;
  }
}
