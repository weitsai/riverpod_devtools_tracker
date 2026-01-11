import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/provider_network.dart';

/// Interactive provider dependency graph visualization
class ProviderGraphView extends StatefulWidget {
  final ProviderNetwork network;

  const ProviderGraphView({
    super.key,
    required this.network,
  });

  @override
  State<ProviderGraphView> createState() => _ProviderGraphViewState();
}

class _ProviderGraphViewState extends State<ProviderGraphView> {
  String? _selectedProvider;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.network.nodes;

    if (nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No provider data yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interact with your app to see provider relationships',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.1,
            maxScale: 4.0,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ProviderGraphPainter(
                network: widget.network,
                selectedProvider: _selectedProvider,
                onNodeTap: (provider) {
                  setState(() {
                    _selectedProvider =
                        _selectedProvider == provider ? null : provider;
                  });
                },
              ),
            ),
          ),
        ),
        if (_selectedProvider != null) _buildSelectionInfo(),
      ],
    );
  }

  Widget _buildToolbar() {
    final stats = widget.network.getStatistics();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(
          bottom: BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hub,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Provider Network',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 24),
          _buildStatChip(
            'Providers',
            '${stats['totalProviders']}',
            Icons.circle,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            'Connections',
            '${stats['totalConnections']}',
            Icons.link,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Color(0xFF8B949E)),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            tooltip: 'Reset Zoom',
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Color(0xFF8B949E)),
            onPressed: () {
              setState(() {
                widget.network.clear();
                _selectedProvider = null;
              });
            },
            tooltip: 'Clear Network',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8B949E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionInfo() {
    final node = widget.network.nodes.firstWhere(
      (n) => n.name == _selectedProvider,
    );
    final connections = widget.network.getConnectionsFor(_selectedProvider!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(
          top: BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle,
                  color: Color(0xFF6366F1),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${node.type} • ${node.updateCount} updates',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8B949E)),
                onPressed: () {
                  setState(() {
                    _selectedProvider = null;
                  });
                },
              ),
            ],
          ),
          if (connections.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Connections:',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: connections.map((conn) {
                final otherProvider =
                    conn.fromProvider == _selectedProvider
                        ? conn.toProvider
                        : conn.fromProvider;
                return Chip(
                  label: Text(
                    '$otherProvider (${conn.strength})',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: const Color(0xFF0D1117),
                  side: const BorderSide(color: Color(0xFF30363D)),
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for provider graph
class _ProviderGraphPainter extends CustomPainter {
  final ProviderNetwork network;
  final String? selectedProvider;
  final Function(String) onNodeTap;

  _ProviderGraphPainter({
    required this.network,
    required this.selectedProvider,
    required this.onNodeTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = network.nodes;
    if (nodes.isEmpty) return;

    // Calculate node positions using force-directed layout
    final positions = _calculatePositions(nodes, size);

    // Draw connections first (behind nodes)
    _drawConnections(canvas, positions);

    // Draw nodes
    _drawNodes(canvas, positions);
  }

  Map<String, Offset> _calculatePositions(
    List<ProviderNode> nodes,
    Size size,
  ) {
    // Simple circular layout
    final positions = <String, Offset>{};
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    for (var i = 0; i < nodes.length; i++) {
      final angle = (2 * math.pi * i) / nodes.length;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      positions[nodes[i].name] = Offset(x, y);
    }

    return positions;
  }

  void _drawConnections(Canvas canvas, Map<String, Offset> positions) {
    final connections = network.connections;

    for (final conn in connections) {
      final from = positions[conn.fromProvider];
      final to = positions[conn.toProvider];
      if (from == null || to == null) continue;

      // Determine if this connection should be highlighted
      final isHighlighted = selectedProvider != null &&
          (conn.fromProvider == selectedProvider ||
              conn.toProvider == selectedProvider);

      final paint = Paint()
        ..color = isHighlighted
            ? const Color(0xFF6366F1).withValues(alpha: 0.8)
            : const Color(0xFF30363D).withValues(alpha: 0.5)
        ..strokeWidth = isHighlighted ? 2.0 : math.max(1.0, conn.strength / 2)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(from, to, paint);

      // Draw arrow head
      if (isHighlighted) {
        _drawArrowHead(canvas, from, to, paint);
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 8.0;
    final direction = (to - from).direction;

    final arrowPoint1 = Offset(
      to.dx - arrowSize * math.cos(direction - math.pi / 6),
      to.dy - arrowSize * math.sin(direction - math.pi / 6),
    );
    final arrowPoint2 = Offset(
      to.dx - arrowSize * math.cos(direction + math.pi / 6),
      to.dy - arrowSize * math.sin(direction + math.pi / 6),
    );

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  void _drawNodes(Canvas canvas, Map<String, Offset> positions) {
    final nodes = network.nodes;

    for (final node in nodes) {
      final position = positions[node.name];
      if (position == null) continue;

      final isSelected = node.name == selectedProvider;

      // Node size based on update count
      final baseRadius = 20.0;
      final radius = baseRadius + (math.log(node.updateCount + 1) * 3);

      // Draw node circle
      final paint = Paint()
        ..color = isSelected
            ? const Color(0xFF6366F1)
            : _getNodeColor(node.type)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, radius, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : const Color(0xFF30363D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 2.0;

      canvas.drawCircle(position, radius, borderPaint);

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _abbreviate(node.name),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8B949E),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy + radius + 6,
        ),
      );
    }
  }

  Color _getNodeColor(String type) {
    // Color-code by provider type
    switch (type) {
      case 'StateProvider':
        return const Color(0xFF3FB950);
      case 'FutureProvider':
        return const Color(0xFF1F6FEB);
      case 'StreamProvider':
        return const Color(0xFF8B5CF6);
      case 'NotifierProvider':
        return const Color(0xFFF85149);
      default:
        return const Color(0xFF8B949E);
    }
  }

  String _abbreviate(String name) {
    if (name.length <= 15) return name;
    return '${name.substring(0, 12)}...';
  }

  @override
  bool shouldRepaint(_ProviderGraphPainter oldDelegate) {
    return oldDelegate.selectedProvider != selectedProvider ||
        oldDelegate.network != network;
  }
}
