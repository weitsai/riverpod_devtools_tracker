/// Inline diff view widget (GitHub style)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

/// Inline diff view showing changes with +/- indicators
///
/// Similar to GitHub's inline diff view:
/// - Green background for added lines
/// - Red background for removed lines
/// - Yellow background for modified lines
class InlineDiffView extends StatelessWidget {
  /// The diff to display
  final ValueDiff diff;

  /// JSON path to this diff (for nested objects)
  final String path;

  /// Indentation level for nested structures
  final int indentLevel;

  /// Whether to show unchanged fields
  final bool showUnchanged;

  const InlineDiffView({
    super.key,
    required this.diff,
    this.path = '',
    this.indentLevel = 0,
    this.showUnchanged = false,
  });

  @override
  Widget build(BuildContext context) {
    if (diff is MapDiff) {
      return _buildMapDiff(context, diff as MapDiff);
    } else if (diff is ListDiff) {
      return _buildListDiff(context, diff as ListDiff);
    } else {
      return _buildValueDiff(context, diff);
    }
  }

  Widget _buildMapDiff(BuildContext context, MapDiff mapDiff) {
    final entries = mapDiff.diffs.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLine(context, '{', DiffType.unchanged),
        ...entries.map((entry) {
          final key = entry.key;
          final valueDiff = entry.value;

          if (valueDiff is UnchangedDiff && !showUnchanged) {
            return const SizedBox.shrink();
          }

          if (valueDiff is UnchangedDiff) {
            return _buildLine(
              context,
              '  "$key": ${_formatValue(valueDiff.value)},',
              DiffType.unchanged,
            );
          } else if (valueDiff is AddedDiff) {
            return _buildLine(
              context,
              '+ "$key": ${_formatValue(valueDiff.value)},',
              DiffType.added,
              icon: '+',
            );
          } else if (valueDiff is RemovedDiff) {
            return _buildLine(
              context,
              '- "$key": ${_formatValue(valueDiff.value)},',
              DiffType.removed,
              icon: '-',
            );
          } else if (valueDiff is ModifiedDiff) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLine(
                  context,
                  '- "$key": ${_formatValue(valueDiff.oldValue)},',
                  DiffType.removed,
                  icon: '-',
                ),
                _buildLine(
                  context,
                  '+ "$key": ${_formatValue(valueDiff.newValue)},',
                  DiffType.added,
                  icon: '+',
                ),
              ],
            );
          } else if (valueDiff is TypeChangedDiff) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLine(
                  context,
                  '- "$key": ${_formatValue(valueDiff.oldValue)} (${valueDiff.oldValue.runtimeType}),',
                  DiffType.removed,
                  icon: '-',
                ),
                _buildLine(
                  context,
                  '+ "$key": ${_formatValue(valueDiff.newValue)} (${valueDiff.newValue.runtimeType}),',
                  DiffType.added,
                  icon: '+',
                ),
              ],
            );
          } else {
            // Nested diff
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLine(
                    context,
                    '"$key": ',
                    DiffType.unchanged,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: InlineDiffView(
                      diff: valueDiff,
                      path: path.isEmpty ? key : '$path.$key',
                      indentLevel: indentLevel + 1,
                      showUnchanged: showUnchanged,
                    ),
                  ),
                ],
              ),
            );
          }
        }),
        _buildLine(context, '}', DiffType.unchanged),
      ],
    );
  }

  Widget _buildListDiff(BuildContext context, ListDiff listDiff) {
    final maxLength =
        listDiff.oldLength > listDiff.newLength ? listDiff.oldLength : listDiff.newLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLine(context, '[', DiffType.unchanged),
        ...List.generate(maxLength, (i) {
          final valueDiff = listDiff.diffs[i];

          if (valueDiff == null && !showUnchanged) {
            return const SizedBox.shrink();
          }

          if (valueDiff == null) {
            // Unchanged element
            // Try to get the value (assume both lists have it if no diff)
            return _buildLine(
              context,
              '  [$i]: (unchanged),',
              DiffType.unchanged,
            );
          } else if (valueDiff is AddedDiff) {
            return _buildLine(
              context,
              '+ [$i]: ${_formatValue(valueDiff.value)},',
              DiffType.added,
              icon: '+',
            );
          } else if (valueDiff is RemovedDiff) {
            return _buildLine(
              context,
              '- [$i]: ${_formatValue(valueDiff.value)},',
              DiffType.removed,
              icon: '-',
            );
          } else if (valueDiff is ModifiedDiff) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLine(
                  context,
                  '- [$i]: ${_formatValue(valueDiff.oldValue)},',
                  DiffType.removed,
                  icon: '-',
                ),
                _buildLine(
                  context,
                  '+ [$i]: ${_formatValue(valueDiff.newValue)},',
                  DiffType.added,
                  icon: '+',
                ),
              ],
            );
          } else {
            // Nested diff
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: InlineDiffView(
                diff: valueDiff,
                path: '$path[$i]',
                indentLevel: indentLevel + 1,
                showUnchanged: showUnchanged,
              ),
            );
          }
        }),
        _buildLine(context, ']', DiffType.unchanged),
      ],
    );
  }

  Widget _buildValueDiff(BuildContext context, ValueDiff diff) {
    if (diff is UnchangedDiff) {
      return _buildLine(
        context,
        _formatValue(diff.value),
        DiffType.unchanged,
      );
    } else if (diff is AddedDiff) {
      return _buildLine(
        context,
        '+ ${_formatValue(diff.value)}',
        DiffType.added,
        icon: '+',
      );
    } else if (diff is RemovedDiff) {
      return _buildLine(
        context,
        '- ${_formatValue(diff.value)}',
        DiffType.removed,
        icon: '-',
      );
    } else if (diff is ModifiedDiff) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLine(
            context,
            '- ${_formatValue(diff.oldValue)}',
            DiffType.removed,
            icon: '-',
          ),
          _buildLine(
            context,
            '+ ${_formatValue(diff.newValue)}',
            DiffType.added,
            icon: '+',
          ),
        ],
      );
    } else if (diff is TypeChangedDiff) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLine(
            context,
            '- ${_formatValue(diff.oldValue)} (${diff.oldValue.runtimeType})',
            DiffType.removed,
            icon: '-',
          ),
          _buildLine(
            context,
            '+ ${_formatValue(diff.newValue)} (${diff.newValue.runtimeType})',
            DiffType.added,
            icon: '+',
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLine(
    BuildContext context,
    String text,
    DiffType type, {
    String? icon,
  }) {
    Color? bgColor;
    Color? textColor;

    switch (type) {
      case DiffType.added:
        bgColor = const Color(0xFF3FB950).withValues(alpha: 0.15);
        textColor = const Color(0xFF3FB950);
        break;
      case DiffType.removed:
        bgColor = const Color(0xFFF85149).withValues(alpha: 0.15);
        textColor = const Color(0xFFF85149);
        break;
      case DiffType.modified:
      case DiffType.typeChanged:
        bgColor = const Color(0xFFD29922).withValues(alpha: 0.15);
        textColor = const Color(0xFFD29922);
        break;
      case DiffType.unchanged:
        textColor = const Color(0xFF8B949E);
        break;
    }

    return GestureDetector(
      onDoubleTap: () {
        // Copy to clipboard on double tap
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              SizedBox(
                width: 16,
                child: Text(
                  icon,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      // Escape special characters
      final escaped = value
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll('\t', '\\t');
      return '"$escaped"';
    }
    if (value is num || value is bool) return value.toString();

    // For complex objects, use toString() but truncate if too long
    final str = value.toString();
    if (str.length > 100) {
      return '${str.substring(0, 97)}...';
    }
    return str;
  }
}
