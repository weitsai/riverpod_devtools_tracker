/// Base class and implementations for representing diffs between values
library;

/// Enum representing the type of diff
enum DiffType {
  /// Value is unchanged
  unchanged,

  /// Value was added (new key in map, new element in list)
  added,

  /// Value was removed (key deleted from map, element removed from list)
  removed,

  /// Value was modified (value changed but type remained same)
  modified,

  /// Type was changed (e.g., string → number)
  typeChanged,
}

/// Base class for all diff types
abstract class ValueDiff {
  /// The type of this diff
  final DiffType type;

  const ValueDiff(this.type);

  /// Factory for unchanged value
  factory ValueDiff.unchanged(dynamic value) = UnchangedDiff;

  /// Factory for added value
  factory ValueDiff.added(dynamic value) = AddedDiff;

  /// Factory for removed value
  factory ValueDiff.removed(dynamic value) = RemovedDiff;

  /// Factory for modified value
  factory ValueDiff.modified(dynamic oldValue, dynamic newValue) =
      ModifiedDiff;

  /// Factory for type-changed value
  factory ValueDiff.typeChanged(dynamic oldValue, dynamic newValue) =
      TypeChangedDiff;

  /// Whether this diff represents a change
  bool get hasChanges => type != DiffType.unchanged;
}

/// Represents an unchanged value
class UnchangedDiff extends ValueDiff {
  /// The unchanged value
  final dynamic value;

  const UnchangedDiff(this.value) : super(DiffType.unchanged);

  @override
  bool get hasChanges => false;
}

/// Represents an added value
class AddedDiff extends ValueDiff {
  /// The added value
  final dynamic value;

  const AddedDiff(this.value) : super(DiffType.added);
}

/// Represents a removed value
class RemovedDiff extends ValueDiff {
  /// The removed value
  final dynamic value;

  const RemovedDiff(this.value) : super(DiffType.removed);
}

/// Represents a modified value
class ModifiedDiff extends ValueDiff {
  /// The old value before modification
  final dynamic oldValue;

  /// The new value after modification
  final dynamic newValue;

  const ModifiedDiff(this.oldValue, this.newValue) : super(DiffType.modified);
}

/// Represents a value whose type changed
class TypeChangedDiff extends ValueDiff {
  /// The old value (with old type)
  final dynamic oldValue;

  /// The new value (with new type)
  final dynamic newValue;

  const TypeChangedDiff(this.oldValue, this.newValue)
      : super(DiffType.typeChanged);
}

/// Represents a diff of a Map/Object
class MapDiff extends ValueDiff {
  /// Map of key to diff for each field
  final Map<String, ValueDiff> diffs;

  const MapDiff({required this.diffs}) : super(DiffType.modified);

  @override
  bool get hasChanges => diffs.values.any((d) => d.hasChanges);

  /// Count of added fields
  int get addedCount =>
      diffs.values.where((d) => d.type == DiffType.added).length;

  /// Count of removed fields
  int get removedCount =>
      diffs.values.where((d) => d.type == DiffType.removed).length;

  /// Count of modified fields (including nested diffs with changes)
  int get modifiedCount => diffs.values.where((d) {
        if (d.type == DiffType.modified || d.type == DiffType.typeChanged) {
          return true;
        }
        if (d is MapDiff && d.hasChanges) {
          return true;
        }
        if (d is ListDiff && d.hasChanges) {
          return true;
        }
        return false;
      }).length;
}

/// Represents a diff of a List/Array
class ListDiff extends ValueDiff {
  /// Map of index to diff for each changed element
  final Map<int, ValueDiff> diffs;

  /// Original list length
  final int oldLength;

  /// New list length
  final int newLength;

  const ListDiff({
    required this.diffs,
    required this.oldLength,
    required this.newLength,
  }) : super(DiffType.modified);

  @override
  bool get hasChanges => diffs.isNotEmpty;
}
