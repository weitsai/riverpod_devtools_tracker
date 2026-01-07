import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../models/provider_state_info.dart';

/// Diff result
class _DiffResult {
  final String previous;
  final String current;
  final bool showArrow;

  _DiffResult({
    required this.previous,
    required this.current,
    this.showArrow = true,
  });
}

class ProviderListTile extends StatefulWidget {
  final ProviderStateInfo stateInfo;
  final bool isSelected;
  final int? changeNumber;
  final VoidCallback onTap;

  const ProviderListTile({
    super.key,
    required this.stateInfo,
    required this.isSelected,
    this.changeNumber,
    required this.onTap,
  });

  @override
  State<ProviderListTile> createState() => _ProviderListTileState();
}

class _ProviderListTileState extends State<ProviderListTile> {
  bool _isValueExpanded = false;

  ProviderStateInfo get stateInfo => widget.stateInfo;
  bool get isSelected => widget.isSelected;
  int? get changeNumber => widget.changeNumber;
  VoidCallback get onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final locationString = stateInfo.locationString;
    final triggerLocation = stateInfo.triggerLocation;
    final hasLocation = locationString != null || triggerLocation != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color:
            isSelected
                ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF21262D),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF30363D),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildChangeTypeIcon(),
                    if (changeNumber != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B949E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$changeNumber',
                          style: const TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stateInfo.providerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildTimestamp(),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        stateInfo.providerType,
                        style: TextStyle(
                          color: _getTypeColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // Show state change preview
                if (stateInfo.changeType == 'update' ||
                    stateInfo.changeType == 'add') ...[
                  const SizedBox(height: 8),
                  _buildValueChangePreview(),
                ],
                if (hasLocation) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.code,
                        size: 12,
                        color: Color(0xFF58A6FF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationString ??
                              triggerLocation?.formattedLocation ??
                              '',
                          style: const TextStyle(
                            color: Color(0xFF58A6FF),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else if (stateInfo.changeType == 'update') ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: const Color(0xFF8B949E).withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.autoComputed,
                        style: TextStyle(
                          color: const Color(0xFF8B949E).withValues(alpha: 0.7),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build value change preview
  Widget _buildValueChangePreview() {
    // For 'add' type, only show current value
    if (stateInfo.changeType == 'add') {
      final currValueShort = _formatPreviewValue(stateInfo.currentValue);
      final currValueFull = _formatFullValue(stateInfo.currentValue);
      final needsExpand = currValueFull.length > currValueShort.length;

      return GestureDetector(
        onTap:
            needsExpand
                ? () => setState(() => _isValueExpanded = !_isValueExpanded)
                : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF3FB950).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add, size: 12, color: Color(0xFF3FB950)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isValueExpanded ? currValueFull : currValueShort,
                      style: const TextStyle(
                        color: Color(0xFF3FB950),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      maxLines: _isValueExpanded ? null : 2,
                      overflow: _isValueExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  if (needsExpand)
                    Icon(
                      _isValueExpanded ? Icons.unfold_less : Icons.unfold_more,
                      size: 14,
                      color: const Color(0xFF8B949E),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // For 'update' type, try smart diff display
    final diffResult = _extractDiff(
      stateInfo.previousValue,
      stateInfo.currentValue,
    );
    final fullDiffResult = _extractDiff(
      stateInfo.previousValue,
      stateInfo.currentValue,
      expanded: true,
    );
    final needsExpand =
        fullDiffResult.previous.length > diffResult.previous.length ||
        fullDiffResult.current.length > diffResult.current.length;

    // If no arrow needed (already in diff format), show diff directly
    if (!diffResult.showArrow) {
      return GestureDetector(
        onTap:
            needsExpand
                ? () => setState(() => _isValueExpanded = !_isValueExpanded)
                : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _isValueExpanded
                      ? fullDiffResult.previous
                      : diffResult.previous,
                  style: const TextStyle(
                    color: Color(0xFFFFA657),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: _isValueExpanded ? null : 3,
                  overflow: _isValueExpanded ? null : TextOverflow.ellipsis,
                ),
              ),
              if (needsExpand)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    _isValueExpanded ? Icons.unfold_less : Icons.unfold_more,
                    size: 14,
                    color: const Color(0xFF8B949E),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap:
          needsExpand
              ? () => setState(() => _isValueExpanded = !_isValueExpanded)
              : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _isValueExpanded
                        ? fullDiffResult.previous
                        : diffResult.previous,
                    style: const TextStyle(
                      color: Color(0xFFF85149),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: _isValueExpanded ? null : 2,
                    overflow: _isValueExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: Color(0xFF8B949E),
                  ),
                ),
                Expanded(
                  child: Text(
                    _isValueExpanded
                        ? fullDiffResult.current
                        : diffResult.current,
                    style: const TextStyle(
                      color: Color(0xFF3FB950),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: _isValueExpanded ? null : 2,
                    overflow: _isValueExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                if (needsExpand)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      _isValueExpanded ? Icons.unfold_less : Icons.unfold_more,
                      size: 14,
                      color: const Color(0xFF8B949E),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Extract differences between two values
  _DiffResult _extractDiff(
    dynamic prev,
    dynamic curr, {
    bool expanded = false,
  }) {
    // Extract actual values (handle {type, value} format)
    final prevExtracted = _extractValue(prev);
    final currExtracted = _extractValue(curr);

    // Decide truncate length based on expanded
    String truncateVal(dynamic val) =>
        expanded ? val.toString() : _truncate(val);

    // If both are Maps, find changed fields
    if (prevExtracted is Map && currExtracted is Map) {
      final changes = <String>[];
      final allKeys = {...prevExtracted.keys, ...currExtracted.keys};

      for (final key in allKeys) {
        final prevVal = prevExtracted[key];
        final currVal = currExtracted[key];
        if (prevVal != currVal) {
          changes.add(
            '$key: ${truncateVal(prevVal)} → ${truncateVal(currVal)}',
          );
        }
      }

      if (changes.isNotEmpty) {
        // Only show changed parts
        final displayChanges = expanded ? changes : changes.take(2).toList();
        final changeStr = displayChanges.join(expanded ? '\n' : ', ');
        final suffix = !expanded && changes.length > 2 ? ', ...' : '';
        return _DiffResult(
          previous: '$changeStr$suffix',
          current: '',
          showArrow: false,
        );
      }
    }

    // If same type object strings (e.g. User(...)), try parsing diff
    final prevStr = prevExtracted.toString();
    final currStr = currExtracted.toString();

    // Check if it's ClassName(...) format
    final classPattern = RegExp(r'^(\w+)\((.*)\)$');
    final prevMatch = classPattern.firstMatch(prevStr);
    final currMatch = classPattern.firstMatch(currStr);

    if (prevMatch != null && currMatch != null) {
      final prevClass = prevMatch.group(1);
      final currClass = currMatch.group(1);

      if (prevClass == currClass) {
        // Same class, parse and compare properties
        final prevProps = _parseProperties(prevMatch.group(2) ?? '');
        final currProps = _parseProperties(currMatch.group(2) ?? '');

        final changes = <String>[];
        final allKeys = {...prevProps.keys, ...currProps.keys};

        for (final key in allKeys) {
          if (prevProps[key] != currProps[key]) {
            changes.add(
              '$key: ${truncateVal(prevProps[key])} → ${truncateVal(currProps[key])}',
            );
          }
        }

        if (changes.isNotEmpty) {
          final displayChanges = expanded ? changes : changes.take(2).toList();
          final changeStr = displayChanges.join('\n');
          final suffix = !expanded && changes.length > 2 ? '\n...' : '';
          return _DiffResult(
            previous: '$changeStr$suffix',
            current: '',
            showArrow: false,
          );
        }
      }
    }

    // Default: show truncated values directly
    return _DiffResult(
      previous: expanded ? _formatFullValue(prev) : _formatPreviewValue(prev),
      current: expanded ? _formatFullValue(curr) : _formatPreviewValue(curr),
    );
  }

  /// Parse "key: value, key2: value2" format properties
  Map<String, String> _parseProperties(String propsStr) {
    final result = <String, String>{};
    // Simple parsing, handle key: value format
    final pattern = RegExp(r'(\w+):\s*([^,]+)');
    for (final match in pattern.allMatches(propsStr)) {
      result[match.group(1)!] = match.group(2)!.trim();
    }
    return result;
  }

  /// Extract actual value from {type, value} format
  dynamic _extractValue(dynamic value) {
    if (value is Map) {
      // If has value field, extract it
      if (value.containsKey('value')) {
        return value['value'];
      }
    }
    return value;
  }

  /// Truncate string
  String _truncate(dynamic value, [int maxLen = 20]) {
    if (value == null) return 'null';
    final str = value.toString();
    if (str.length > maxLen) {
      return '${str.substring(0, maxLen - 3)}...';
    }
    return str;
  }

  /// Format full value (no truncation)
  String _formatFullValue(dynamic value) {
    if (value == null) return 'null';
    final extracted = _extractValue(value);
    return extracted.toString();
  }

  /// Format preview value (short version)
  String _formatPreviewValue(dynamic value) {
    if (value == null) return 'null';

    // Extract actual value first
    final extracted = _extractValue(value);
    final str = extracted.toString();

    // If is Map, show key content
    if (extracted is Map) {
      if (extracted.isEmpty) return '{}';
      final entries = extracted.entries
          .take(2)
          .map((e) {
            return '${e.key}: ${_truncate(e.value, 15)}';
          })
          .join(', ');
      return extracted.length > 2 ? '$entries, ...' : entries;
    }

    // If is List, show length and first few elements
    if (extracted is List) {
      if (extracted.isEmpty) return '[]';
      if (extracted.length <= 3) {
        return '[${extracted.map((e) => _truncate(e, 10)).join(', ')}]';
      }
      return '[${extracted.length} items]';
    }

    // Truncate long strings
    if (str.length > 40) {
      return '${str.substring(0, 37)}...';
    }

    return str;
  }

  Widget _buildChangeTypeIcon() {
    IconData icon;
    Color color;

    switch (stateInfo.changeType) {
      case 'add':
        icon = Icons.add_circle_outline;
        color = const Color(0xFF3FB950);
        break;
      case 'update':
        icon = Icons.edit_outlined;
        color = const Color(0xFFF0883E);
        break;
      case 'dispose':
        icon = Icons.remove_circle_outline;
        color = const Color(0xFFF85149);
        break;
      default:
        icon = Icons.info_outline;
        color = const Color(0xFF8B949E);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }

  Widget _buildTimestamp() {
    final now = DateTime.now();
    final diff = now.difference(stateInfo.timestamp);

    String timeText;
    if (diff.inSeconds < 60) {
      timeText = '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      timeText = '${diff.inMinutes}m ago';
    } else {
      timeText =
          '${stateInfo.timestamp.hour.toString().padLeft(2, '0')}:${stateInfo.timestamp.minute.toString().padLeft(2, '0')}';
    }

    return Text(
      timeText,
      style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10),
    );
  }

  Color _getTypeColor() {
    switch (stateInfo.providerType.toLowerCase()) {
      case 'stateprovider':
        return const Color(0xFF79C0FF);
      case 'statenotifierprovider':
        return const Color(0xFFA5D6FF);
      case 'futureprovider':
        return const Color(0xFFD2A8FF);
      case 'streamprovider':
        return const Color(0xFF7EE787);
      case 'provider':
        return const Color(0xFFFFA657);
      case 'notifierprovider':
        return const Color(0xFFFF7B72);
      default:
        return const Color(0xFF8B949E);
    }
  }
}
