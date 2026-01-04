import 'package:flutter/material.dart';
import '../models/provider_state_info.dart';

class ProviderListTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final locationString = stateInfo.locationString;
    final triggerLocation = stateInfo.triggerLocation;
    final hasLocation = locationString != null || triggerLocation != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? const Color(0xFF6366F1).withOpacity(0.2)
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
                color: isSelected
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
                          color: const Color(0xFF8B949E).withOpacity(0.2),
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
                        color: _getTypeColor().withOpacity(0.2),
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
                if (hasLocation) ...[
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: const Color(0xFF8B949E).withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'auto-computed',
                        style: TextStyle(
                          color: const Color(0xFF8B949E).withOpacity(0.7),
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
        color: color.withOpacity(0.2),
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
