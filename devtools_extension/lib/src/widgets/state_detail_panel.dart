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

class _StateDetailPanelState extends State<StateDetailPanel> {
  bool _isBeforeExpanded = false;
  bool _isAfterExpanded = false;

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
          _buildTriggerLocationSection(),
          const SizedBox(height: 20),
          _buildValueComparison(),
          const SizedBox(height: 20),
          _buildStackTraceSection(),
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
                const Icon(Icons.location_on, color: Color(0xFF3FB950), size: 18),
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
                  AppLocalizations.of(context)!.itemsCount(stateInfo.callChain.length),
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
              const Icon(Icons.compare_arrows, color: Color(0xFF8B949E), size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.stateChange,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
                  const Color(0xFFF85149),
                  isExpanded: _isBeforeExpanded,
                  onToggle: () =>
                      setState(() => _isBeforeExpanded = !_isBeforeExpanded),
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
                  const Color(0xFF3FB950),
                  isExpanded: _isAfterExpanded,
                  onToggle: () =>
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
    Color labelColor, {
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final needsExpand = value.length > _collapsedMaxLength;
    final displayValue = !needsExpand || isExpanded
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
            if (needsExpand) ...[
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayValue,
                style: const TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
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
                        color: const Color(0xFF58A6FF).withValues(alpha: 0.1),
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

  Widget _buildStackTraceSection() {
    final hasCallChain = stateInfo.callChain.isNotEmpty;
    final hasStackTrace = stateInfo.stackTrace.isNotEmpty;
    final hasExplicitLocation =
        stateInfo.location != null || stateInfo.locationFile != null;

    // If no explicit location, call chain already shown above, no need to show again
    if (!hasExplicitLocation && hasCallChain) {
      return const SizedBox.shrink();
    }

    if (!hasCallChain && !hasStackTrace) return const SizedBox.shrink();

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
                hasCallChain
                    ? AppLocalizations.of(context)!.callChain
                    : AppLocalizations.of(context)!.stackTrace,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.itemsCount(
                  hasCallChain
                      ? stateInfo.callChain.length
                      : stateInfo.stackTrace.length,
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
            child:
                hasCallChain ? _buildCallChainList() : _buildStackTraceList(),
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
          (_, __) => const Divider(height: 1, color: Color(0xFF21262D)),
      itemBuilder: (context, index) {
        final entry = stateInfo.callChain[index];
        final isFirst = index == 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isFirst ? const Color(0xFF238636).withValues(alpha: 0.1) : null,
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

  Widget _buildStackTraceList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stateInfo.stackTrace.length,
      separatorBuilder:
          (_, __) => const Divider(height: 1, color: Color(0xFF21262D)),
      itemBuilder: (context, index) {
        final entry = stateInfo.stackTrace[index];
        final isUserCode = !entry.isFramework && !entry.isRiverpodInternal;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isUserCode ? const Color(0xFF238636).withValues(alpha: 0.1) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '#$index',
                  style: TextStyle(
                    color:
                        isUserCode
                            ? const Color(0xFF3FB950)
                            : const Color(0xFF484F58),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.shortFileName,
                      style: TextStyle(
                        color:
                            isUserCode
                                ? const Color(0xFF58A6FF)
                                : const Color(0xFF8B949E),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (entry.function != null)
                      Text(
                        entry.function!,
                        style: TextStyle(
                          color:
                              isUserCode
                                  ? const Color(0xFFD2A8FF)
                                  : const Color(0xFF6E7681),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),
              if (entry.line != null)
                Text(
                  ':${entry.line}',
                  style: TextStyle(
                    color:
                        isUserCode
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
