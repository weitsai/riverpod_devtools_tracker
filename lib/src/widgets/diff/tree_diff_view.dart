/// Tree diff view widget with expand/collapse functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../diff/value_diff.dart';

/// Tree diff view with expandable/collapsible nodes
///
/// Shows a hierarchical tree structure with:
/// - Expand/collapse controls
/// - Change type indicators (icons and colors)
/// - Summary statistics for nested changes
/// - JSON path navigation
class TreeDiffView extends StatefulWidget {
  /// The diff to display
  final ValueDiff diff;

  /// Whether to show only changes (hide unchanged fields)
  final bool showOnlyChanges;

  const TreeDiffView({
    super.key,
    required this.diff,
    this.showOnlyChanges = true,
  });

  @override
  State<TreeDiffView> createState() => _TreeDiffViewState();
}

class _TreeDiffViewState extends State<TreeDiffView> {
  /// Set of expanded paths
  final Set<String> _expandedPaths = {};

  @override
  Widget build(BuildContext context) {
    if (widget.diff is! MapDiff && widget.diff is! ListDiff) {
      // For non-nested diffs, just show the value
      return _buildSimpleDiff(widget.diff, '');
    }

    return ListView(
      children: _buildTreeNodes(widget.diff, ''),
    );
  }

  List<Widget> _buildTreeNodes(ValueDiff diff, String parentPath) {
    final widgets = <Widget>[];

    if (diff is MapDiff) {
      for (final entry in diff.diffs.entries) {
        final key = entry.key;
        final valueDiff = entry.value;
        final path = parentPath.isEmpty ? key : '$parentPath.$key';

        if (widget.showOnlyChanges && !valueDiff.hasChanges) {
          continue;
        }

        final hasChildren = valueDiff is MapDiff || valueDiff is ListDiff;
        final isExpanded = _expandedPaths.contains(path);

        widgets.add(
          _DiffTreeNode(
            name: key,
            diff: valueDiff,
            path: path,
            isExpanded: isExpanded,
            hasChildren: hasChildren,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedPaths.remove(path);
                } else {
                  _expandedPaths.add(path);
                }
              });
            },
          ),
        );

        if (isExpanded && hasChildren) {
          widgets.addAll(
            _buildTreeNodes(valueDiff, path).map(
              (w) => Padding(
                padding: const EdgeInsets.only(left: 24),
                child: w,
              ),
            ),
          );
        }
      }
    } else if (diff is ListDiff) {
      for (final entry in diff.diffs.entries) {
        final index = entry.key;
        final valueDiff = entry.value;
        final path = '$parentPath[$index]';

        final hasChildren = valueDiff is MapDiff || valueDiff is ListDiff;
        final isExpanded = _expandedPaths.contains(path);

        widgets.add(
          _DiffTreeNode(
            name: '[$index]',
            diff: valueDiff,
            path: path,
            isExpanded: isExpanded,
            hasChildren: hasChildren,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedPaths.remove(path);
                } else {
                  _expandedPaths.add(path);
                }
              });
            },
          ),
        );

        if (isExpanded && hasChildren) {
          widgets.addAll(
            _buildTreeNodes(valueDiff, path).map(
              (w) => Padding(
                padding: const EdgeInsets.only(left: 24),
                child: w,
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  Widget _buildSimpleDiff(ValueDiff diff, String path) {
    return _DiffTreeNode(
      name: 'value',
      diff: diff,
      path: path,
      isExpanded: false,
      hasChildren: false,
      onToggle: () {},
    );
  }
}

/// Individual node in the tree
class _DiffTreeNode extends StatelessWidget {
  final String name;
  final ValueDiff diff;
  final String path;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback onToggle;

  const _DiffTreeNode({
    required this.name,
    required this.diff,
    required this.path,
    required this.isExpanded,
    required this.hasChildren,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, summary) = _getNodeInfo();

    return InkWell(
      onTap: hasChildren ? onToggle : null,
      onDoubleTap: () {
        // Copy path to clipboard
        Clipboard.setData(ClipboardData(text: path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Path copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF30363D),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  if (summary.isNotEmpty)
                    Text(
                      summary,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (hasChildren)
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: const Color(0xFF8B949E),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _getNodeInfo() {
    if (diff is AddedDiff) {
      final addedDiff = diff as AddedDiff;
      return (
        Icons.add_circle,
        const Color(0xFF3FB950),
        'Added: ${_formatValue(addedDiff.value)}',
      );
    } else if (diff is RemovedDiff) {
      final removedDiff = diff as RemovedDiff;
      return (
        Icons.remove_circle,
        const Color(0xFFF85149),
        'Removed: ${_formatValue(removedDiff.value)}',
      );
    } else if (diff is ModifiedDiff) {
      final modifiedDiff = diff as ModifiedDiff;
      return (
        Icons.edit,
        const Color(0xFFD29922),
        '${_formatValue(modifiedDiff.oldValue)} → ${_formatValue(modifiedDiff.newValue)}',
      );
    } else if (diff is TypeChangedDiff) {
      final typeDiff = diff as TypeChangedDiff;
      return (
        Icons.swap_horiz,
        const Color(0xFF6366F1),
        '${typeDiff.oldValue.runtimeType} → ${typeDiff.newValue.runtimeType}',
      );
    } else if (diff is MapDiff) {
      final mapDiff = diff as MapDiff;
      final parts = <String>[];
      if (mapDiff.addedCount > 0) parts.add('${mapDiff.addedCount} added');
      if (mapDiff.removedCount > 0) {
        parts.add('${mapDiff.removedCount} removed');
      }
      if (mapDiff.modifiedCount > 0) {
        parts.add('${mapDiff.modifiedCount} modified');
      }

      return (
        isExpanded ? Icons.folder_open : Icons.folder,
        const Color(0xFF6366F1),
        parts.isEmpty ? 'No changes' : parts.join(', '),
      );
    } else if (diff is ListDiff) {
      final listDiff = diff as ListDiff;
      return (
        isExpanded ? Icons.view_list : Icons.list,
        const Color(0xFF6366F1),
        'Length: ${listDiff.oldLength} → ${listDiff.newLength}',
      );
    } else {
      // UnchangedDiff
      return (
        Icons.circle,
        const Color(0xFF8B949E),
        'Unchanged',
      );
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      if (value.length > 30) {
        return '"${value.substring(0, 27)}..."';
      }
      return '"$value"';
    }
    if (value is num || value is bool) return value.toString();

    final str = value.toString();
    if (str.length > 40) {
      return '${str.substring(0, 37)}...';
    }
    return str;
  }
}
