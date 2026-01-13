import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../models/provider_state_info.dart';

class StateDetailPanel extends StatefulWidget {
  final ProviderStateInfo stateInfo;

  const StateDetailPanel({super.key, required this.stateInfo});

  @override
  State<StateDetailPanel> createState() => _StateDetailPanelState();
}

enum _ViewMode { tree, text }

class _StateDetailPanelState extends State<StateDetailPanel> {
  bool _isBeforeExpanded = false;
  bool _isAfterExpanded = false;
  _ViewMode _viewMode = _ViewMode.tree;

  ProviderStateInfo get stateInfo => widget.stateInfo;

  // Default maximum characters to display when collapsed
  static const int _collapsedMaxLength = 200;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildValueComparison(),
          const SizedBox(height: 20),
          _buildTriggerLocationSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.2),
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.data_object,
              color: Color(0xFF6366F1),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stateInfo.providerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTag(stateInfo.providerType, const Color(0xFF58A6FF)),
                    const SizedBox(width: 8),
                    _buildTag(
                      stateInfo.changeType.toUpperCase(),
                      _getChangeTypeColor(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _formatTimestamp(stateInfo.timestamp),
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTriggerLocationSection() {
    final locationString = stateInfo.locationString;
    final hasExplicitLocation =
        stateInfo.location != null || stateInfo.locationFile != null;
    final hasCallChain = stateInfo.callChain.isNotEmpty;

    // If neither location nor call chain, show nothing
    if (!hasExplicitLocation && !hasCallChain) {
      return const SizedBox.shrink();
    }

    final triggerLocation = stateInfo.triggerLocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF238636)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Change Source block (shown when explicit location exists)
          if (hasExplicitLocation) ...[
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF3FB950),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.changeSource,
                  style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      locationString ??
                          '${triggerLocation!.file}:${triggerLocation.line}',
                      style: const TextStyle(
                        color: Color(0xFF58A6FF),
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      color: Color(0xFF8B949E),
                      size: 18,
                    ),
                    onPressed: () {
                      final text =
                          locationString ??
                          '${triggerLocation?.file}:${triggerLocation?.line}';
                      Clipboard.setData(ClipboardData(text: text));
                    },
                    tooltip: AppLocalizations.of(context)!.copyLocation,
                  ),
                ],
              ),
            ),
          ],
          // Call Chain block (shown when call chain exists)
          if (hasCallChain) ...[
            if (hasExplicitLocation) const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.layers, color: Color(0xFF3FB950), size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.callChain,
                  style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.itemsCount(stateInfo.callChain.length),
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildCallChainList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_arrows,
                color: Color(0xFF8B949E),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.stateChange,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // View mode toggle button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _viewMode = _viewMode == _ViewMode.text
                          ? _ViewMode.tree
                          : _ViewMode.text;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF238636).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF238636).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _viewMode == _ViewMode.tree
                              ? Icons.account_tree
                              : Icons.notes,
                          size: 16,
                          color: const Color(0xFF3FB950),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _viewMode == _ViewMode.tree ? 'Tree View' : 'Text View',
                          style: const TextStyle(
                            color: Color(0xFF3FB950),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildValueBox(
                  context,
                  AppLocalizations.of(context)!.before,
                  stateInfo.formattedPreviousValue,
                  stateInfo.formattedCurrentValue,
                  const Color(0xFFF85149),
                  isExpanded: _isBeforeExpanded,
                  viewMode: _viewMode,
                  onToggle:
                      () => setState(
                        () => _isBeforeExpanded = !_isBeforeExpanded,
                      ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: Color(0xFF8B949E)),
              ),
              Expanded(
                child: _buildValueBox(
                  context,
                  AppLocalizations.of(context)!.after,
                  stateInfo.formattedCurrentValue,
                  stateInfo.formattedPreviousValue,
                  const Color(0xFF3FB950),
                  isExpanded: _isAfterExpanded,
                  viewMode: _viewMode,
                  onToggle:
                      () =>
                          setState(() => _isAfterExpanded = !_isAfterExpanded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueBox(
    BuildContext context,
    String label,
    String value,
    String otherValue,
    Color labelColor, {
    required bool isExpanded,
    required _ViewMode viewMode,
    required VoidCallback onToggle,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final needsExpand = value.length > _collapsedMaxLength;
    final displayValue =
        !needsExpand || isExpanded
            ? value
            : '${value.substring(0, _collapsedMaxLength)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (needsExpand && viewMode == _ViewMode.text) ...[
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF58A6FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded ? l10n.collapse : l10n.expand,
                          style: const TextStyle(
                            color: Color(0xFF58A6FF),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          isExpanded ? Icons.unfold_less : Icons.unfold_more,
                          size: 14,
                          color: const Color(0xFF58A6FF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: labelColor.withValues(alpha: 0.3)),
          ),
          child: viewMode == _ViewMode.tree
              ? _buildTreeView(value, otherValue, labelColor)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlightedValue(
                      displayValue,
                      otherValue,
                      labelColor,
                    ),
                    if (needsExpand && !isExpanded) ...[
                      const SizedBox(height: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF58A6FF)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.clickToExpandFullContent,
                              style: const TextStyle(
                                color: Color(0xFF58A6FF),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTreeView(
    String value,
    String otherValue,
    Color highlightColor,
  ) {
    final tree = _parseValueTree(value);
    final otherTree = _parseValueTree(otherValue);

    return _TreeNode(
      node: tree,
      otherNode: otherTree,
      highlightColor: highlightColor,
      depth: 0,
    );
  }

  _ValueTreeNode _parseValueTree(String value) {
    value = value.trim();

    // Check if it's a list: [...]
    if (value.startsWith('[') && value.endsWith(']')) {
      final content = value.substring(1, value.length - 1).trim();

      if (content.isEmpty) {
        return _ValueTreeNode(
          type: _NodeType.list,
          name: 'List',
          value: '[]',
          children: [],
        );
      }

      final items = _parseProperties(content);
      final children = <_ValueTreeNode>[];

      for (int i = 0; i < items.length; i++) {
        final item = items[i].trim();
        final childNode = _parseValueTree(item);
        // Add index as name for list items
        children.add(_ValueTreeNode(
          type: _NodeType.property,
          name: '[$i]',
          value: childNode.type == _NodeType.value ? childNode.value : '',
          children: childNode.type == _NodeType.value ? [] : [childNode],
        ));
      }

      return _ValueTreeNode(
        type: _NodeType.list,
        name: 'List',
        value: '',
        children: children,
      );
    }

    // Check if it's an object: ClassName(...)
    final objectPattern = RegExp(r'^(\w+)\((.*)\)$', dotAll: true);
    final objectMatch = objectPattern.firstMatch(value);

    if (objectMatch != null) {
      final className = objectMatch.group(1)!;
      final props = objectMatch.group(2)!.trim();

      if (props.isEmpty) {
        return _ValueTreeNode(
          type: _NodeType.object,
          name: className,
          value: '',
          children: [],
        );
      }

      final properties = _parseProperties(props);
      final children = <_ValueTreeNode>[];

      for (final prop in properties) {
        final colonIndex = prop.indexOf(':');
        if (colonIndex > 0) {
          final key = prop.substring(0, colonIndex).trim();
          final val = prop.substring(colonIndex + 1).trim();
          children.add(_parseValueTree('$key: $val'));
        }
      }

      return _ValueTreeNode(
        type: _NodeType.object,
        name: className,
        value: '',
        children: children,
      );
    }

    // Check for key-value pair
    final kvPattern = RegExp(r'^([^:]+):\s*(.+)$', dotAll: true);
    final kvMatch = kvPattern.firstMatch(value);

    if (kvMatch != null) {
      final key = kvMatch.group(1)!.trim();
      final val = kvMatch.group(2)!.trim();

      // Check if value is a nested structure
      if ((val.startsWith('(') && val.endsWith(')')) ||
          (val.startsWith('{') && val.endsWith('}')) ||
          (val.startsWith('[') && val.endsWith(']'))) {
        final nestedNode = _parseValueTree(val);
        return _ValueTreeNode(
          type: _NodeType.property,
          name: key,
          value: '',
          children: [nestedNode],
        );
      }

      return _ValueTreeNode(
        type: _NodeType.property,
        name: key,
        value: val,
        children: [],
      );
    }

    // Simple value
    return _ValueTreeNode(
      type: _NodeType.value,
      name: '',
      value: value,
      children: [],
    );
  }

  Widget _buildHighlightedValue(
    String currentValue,
    String otherValue,
    Color highlightColor,
  ) {
    // Don't format in text mode - keep original for proper wrapping
    final formattedCurrent = currentValue;
    final formattedOther = otherValue;

    // If values are identical, no need for highlighting
    if (formattedCurrent == formattedOther) {
      return SelectableText(
        formattedCurrent,
        style: const TextStyle(
          color: Color(0xFFC9D1D9),
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      );
    }

    final spans = <TextSpan>[];
    final diffRanges = _computeDiffRanges(formattedCurrent, formattedOther);

    int lastEnd = 0;
    for (final range in diffRanges) {
      // Add normal text before the diff
      if (range.start > lastEnd) {
        spans.add(
          TextSpan(
            text: formattedCurrent.substring(lastEnd, range.start),
            style: const TextStyle(
              color: Color(0xFFC9D1D9),
            ),
          ),
        );
      }

      // Add highlighted diff
      spans.add(
        TextSpan(
          text: formattedCurrent.substring(range.start, range.end),
          style: TextStyle(
            color: Colors.white,
            backgroundColor: highlightColor.withValues(alpha: 0.3),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      lastEnd = range.end;
    }

    // Add remaining normal text
    if (lastEnd < formattedCurrent.length) {
      spans.add(
        TextSpan(
          text: formattedCurrent.substring(lastEnd),
          style: const TextStyle(
            color: Color(0xFFC9D1D9),
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        children: spans,
      ),
    );
  }

  List<_DiffRange> _computeDiffRanges(String current, String other) {
    if (current == other) return [];

    final minLen = current.length < other.length ? current.length : other.length;

    // Find first difference from left
    int leftDiff = 0;
    while (leftDiff < minLen && current[leftDiff] == other[leftDiff]) {
      leftDiff++;
    }

    // Find first difference from right
    int rightDiff = 0;
    while (rightDiff < minLen - leftDiff &&
        current[current.length - 1 - rightDiff] ==
            other[other.length - 1 - rightDiff]) {
      rightDiff++;
    }

    // The difference is in the middle
    final currentEnd = current.length - rightDiff;

    if (leftDiff >= currentEnd) {
      // No substantial difference in the middle
      return [];
    }

    return [_DiffRange(leftDiff, currentEnd)];
  }

  List<_DiffRange> _mergeNearbyRanges(
    List<_DiffRange> ranges, {
    required int maxDistance,
  }) {
    if (ranges.isEmpty) return ranges;

    final merged = <_DiffRange>[];
    var current = ranges[0];

    for (int i = 1; i < ranges.length; i++) {
      final next = ranges[i];
      if (next.start - current.end <= maxDistance) {
        // Merge ranges
        current = _DiffRange(current.start, next.end);
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);

    return merged;
  }

  /// Parse comma-separated properties, handling nested structures
  List<String> _parseProperties(String props) {
    final properties = <String>[];
    final buffer = StringBuffer();
    int depth = 0;
    bool inQuotes = false;

    for (int i = 0; i < props.length; i++) {
      final char = props[i];

      if (char == '"' || char == "'") {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (!inQuotes) {
        if (char == '(' || char == '[' || char == '{') {
          depth++;
          buffer.write(char);
        } else if (char == ')' || char == ']' || char == '}') {
          depth--;
          buffer.write(char);
        } else if (char == ',' && depth == 0) {
          // Property separator at top level
          properties.add(buffer.toString().trim());
          buffer.clear();
        } else {
          buffer.write(char);
        }
      } else {
        buffer.write(char);
      }
    }

    // Add last property
    if (buffer.isNotEmpty) {
      properties.add(buffer.toString().trim());
    }

    return properties;
  }

  Widget _buildStackTraceSection() {
    final hasCallChain = stateInfo.callChain.isNotEmpty;
    final hasExplicitLocation =
        stateInfo.location != null || stateInfo.locationFile != null;

    // If no explicit location, call chain already shown above, no need to show again
    if (!hasExplicitLocation && hasCallChain) {
      return const SizedBox.shrink();
    }

    if (!hasCallChain) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: Color(0xFF8B949E), size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.callChain,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.itemsCount(
                  stateInfo.callChain.length,
                ),
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildCallChainList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallChainList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stateInfo.callChain.length,
      separatorBuilder:
          (_, _) => const Divider(height: 1, color: Color(0xFF21262D)),
      itemBuilder: (context, index) {
        final entry = stateInfo.callChain[index];
        final isFirst = index == 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color:
              isFirst ? const Color(0xFF238636).withValues(alpha: 0.1) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  isFirst ? '→' : '  ',
                  style: TextStyle(
                    color:
                        isFirst
                            ? const Color(0xFF3FB950)
                            : const Color(0xFF484F58),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.file,
                  style: TextStyle(
                    color:
                        isFirst
                            ? const Color(0xFF58A6FF)
                            : const Color(0xFF8B949E),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                ':${entry.line}',
                style: TextStyle(
                  color:
                      isFirst
                          ? const Color(0xFFFFA657)
                          : const Color(0xFF484F58),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Color _getChangeTypeColor() {
    switch (stateInfo.changeType) {
      case 'add':
        return const Color(0xFF3FB950);
      case 'update':
        return const Color(0xFFF0883E);
      case 'dispose':
        return const Color(0xFFF85149);
      default:
        return const Color(0xFF8B949E);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

class _DiffRange {
  final int start;
  final int end;

  _DiffRange(this.start, this.end);
}

enum _NodeType { object, property, value, list }

class _ValueTreeNode {
  final _NodeType type;
  final String name;
  final String value;
  final List<_ValueTreeNode> children;

  _ValueTreeNode({
    required this.type,
    required this.name,
    required this.value,
    required this.children,
  });

  bool get hasChildren => children.isNotEmpty;
}

class _TreeNode extends StatefulWidget {
  final _ValueTreeNode node;
  final _ValueTreeNode? otherNode;
  final Color highlightColor;
  final int depth;

  const _TreeNode({
    required this.node,
    this.otherNode,
    required this.highlightColor,
    required this.depth,
  });

  @override
  State<_TreeNode> createState() => _TreeNodeState();
}

class _TreeNodeState extends State<_TreeNode> {
  bool _isExpanded = true;

  bool _isDifferent() {
    // Don't highlight the top-level container (object or list)
    if (widget.depth == 0) return false;

    if (widget.otherNode == null) return true;

    final node = widget.node;
    final other = widget.otherNode!;

    if (node.name != other.name) return true;
    if (node.value != other.value) return true;
    if (node.children.length != other.children.length) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isDiff = _isDifferent();
    final indent = widget.depth * 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: node.hasChildren
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap:
                node.hasChildren
                    ? () => setState(() => _isExpanded = !_isExpanded)
                    : null,
            child: Container(
              padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
              color:
                  isDiff
                      ? widget.highlightColor.withValues(alpha: 0.1)
                      : Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (node.hasChildren)
                    Icon(
                      _isExpanded
                          ? Icons.arrow_drop_down
                          : Icons.arrow_right,
                      size: 16,
                      color: const Color(0xFF8B949E),
                    )
                  else
                    const SizedBox(width: 16),
                  Expanded(
                    child: _buildNodeContent(node, isDiff),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded && node.hasChildren)
          ...node.children.asMap().entries.map(
                (entry) => _TreeNode(
                  node: entry.value,
                  otherNode:
                      widget.otherNode != null &&
                              entry.key < widget.otherNode!.children.length
                          ? widget.otherNode!.children[entry.key]
                          : null,
                  highlightColor: widget.highlightColor,
                  depth: widget.depth + 1,
                ),
              ),
      ],
    );
  }

  Widget _buildNodeContent(_ValueTreeNode node, bool isDiff) {
    final textStyle = TextStyle(
      color: isDiff ? Colors.white : const Color(0xFFC9D1D9),
      fontSize: 12,
      fontFamily: 'monospace',
      fontWeight: isDiff ? FontWeight.w600 : FontWeight.normal,
      backgroundColor:
          isDiff ? widget.highlightColor.withValues(alpha: 0.3) : null,
    );

    switch (node.type) {
      case _NodeType.list:
        return SelectableText(
          node.hasChildren
              ? 'List (${node.children.length} items)'
              : node.value,
          style: textStyle.copyWith(color: const Color(0xFFFFA657)),
        );
      case _NodeType.object:
        return SelectableText(
          node.hasChildren ? '${node.name}(' : '${node.name}()',
          style: textStyle.copyWith(color: const Color(0xFF8B5CF6)),
        );
      case _NodeType.property:
        if (node.hasChildren) {
          return SelectableText(
            '${node.name}:',
            style: textStyle.copyWith(color: const Color(0xFF58A6FF)),
          );
        }
        return SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${node.name}: ',
                style: textStyle.copyWith(color: const Color(0xFF58A6FF)),
              ),
              TextSpan(
                text: node.value,
                style: textStyle,
              ),
            ],
          ),
        );
      case _NodeType.value:
        return SelectableText(
          node.value,
          style: textStyle,
        );
    }
  }
}
