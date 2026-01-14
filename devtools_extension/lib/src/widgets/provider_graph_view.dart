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

  // Store calculated positions for hit testing
  Map<String, Offset> _nodePositions = {};
  Map<String, double> _nodeRadii = {};
  Size _lastSize = Size.zero;
  int _lastNodeCount = 0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Calculate node positions based on current size
  void _calculateNodePositions(Size size) {
    final currentNodeCount = widget.network.nodes.length;

    // Recalculate if size changed or node count changed
    if (size == _lastSize &&
        currentNodeCount == _lastNodeCount &&
        _nodePositions.isNotEmpty) {
      return;
    }

    _lastSize = size;
    _lastNodeCount = currentNodeCount;
    final nodes = widget.network.nodes;
    if (nodes.isEmpty) {
      _nodePositions = {};
      _nodeRadii = {};
      return;
    }

    final positions = <String, Offset>{};
    final radii = <String, double>{};
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    for (var i = 0; i < nodes.length; i++) {
      final angle = (2 * math.pi * i) / nodes.length;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      positions[nodes[i].name] = Offset(x, y);

      // Calculate node radius based on update count
      const baseRadius = 20.0;
      radii[nodes[i].name] =
          baseRadius + (math.log(nodes[i].updateCount + 1) * 3);
    }

    _nodePositions = positions;
    _nodeRadii = radii;
  }

  /// Find which node was tapped at the given local position
  String? _findNodeAtPosition(Offset localPosition) {
    // Transform the position based on current InteractiveViewer state
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final transformedPosition =
        MatrixUtils.transformPoint(inverseMatrix, localPosition);

    for (final entry in _nodePositions.entries) {
      final nodePosition = entry.value;
      final nodeRadius = _nodeRadii[entry.key] ?? 20.0;
      final distance = (transformedPosition - nodePosition).distance;
      if (distance <= nodeRadius) {
        return entry.key;
      }
    }
    return null;
  }

  void _handleTap(TapUpDetails details) {
    final tappedNode = _findNodeAtPosition(details.localPosition);
    if (tappedNode != null) {
      setState(() {
        _selectedProvider =
            _selectedProvider == tappedNode ? null : tappedNode;
      });
    }
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
          child: Row(
            children: [
              // Left: Graph view
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    _calculateNodePositions(size);

                    return GestureDetector(
                      onTapUp: _handleTap,
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
                            nodePositions: _nodePositions,
                            nodeRadii: _nodeRadii,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Right: Detail panel (when selected)
              if (_selectedProvider != null) ...[
                Container(width: 1, color: const Color(0xFF30363D)),
                SizedBox(
                  width: 320,
                  child: _buildDetailPanel(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final stats = widget.network.getStatistics();
    final providersByType = stats['providersByType'] as Map<String, int>? ?? {};

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
          // Display provider count by type with colors
          ...providersByType.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildTypeStatChip(
                _getTypeLabel(entry.key),
                '${entry.value}',
                _getNodeColor(entry.key),
              ),
            );
          }),
          if (providersByType.isNotEmpty) const SizedBox(width: 12),
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
                _nodePositions = {};
                _nodeRadii = {};
                _lastNodeCount = 0;
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

  Widget _buildTypeStatChip(String label, String value, Color color) {
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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
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

  String _getTypeLabel(String type) {
    // Convert provider type to short label
    switch (type) {
      case 'StateNotifierProvider':
        return 'StateNotifier';
      case 'ChangeNotifierProvider':
        return 'ChangeNotifier';
      case 'AsyncNotifierProvider':
        return 'AsyncNotifier';
      case 'StreamNotifierProvider':
        return 'StreamNotifier';
      case 'NotifierProvider':
        return 'Notifier';
      case 'FutureProvider':
        return 'Future';
      case 'StreamProvider':
        return 'Stream';
      case 'StateProvider':
        return 'State';
      case 'Provider':
        return 'Provider';
      default:
        return type;
    }
  }

  Widget _buildDetailPanel() {
    final node = widget.network.nodes.firstWhere(
      (n) => n.name == _selectedProvider,
    );
    final connections = widget.network.getConnectionsFor(_selectedProvider!);
    final nodeColor = _getNodeColor(node.type);

    return Container(
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF30363D)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Provider Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8B949E)),
                  iconSize: 18,
                  onPressed: () {
                    setState(() {
                      _selectedProvider = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider name
                  const Text(
                    'Name',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    node.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Provider type
                  const Text(
                    'Type',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: nodeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      node.type,
                      style: TextStyle(
                        color: nodeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Update count
                  const Text(
                    'Update Count',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${node.updateCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Last update
                  if (node.lastUpdate != null) ...[
                    const Text(
                      'Last Update',
                      style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(node.lastUpdate!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Connections
                  if (connections.isNotEmpty) ...[
                    Text(
                      'Connections (${connections.length})',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...connections.map((conn) {
                      final otherProvider = conn.fromProvider == _selectedProvider
                          ? conn.toProvider
                          : conn.fromProvider;
                      final otherNode = widget.network.nodes.firstWhere(
                        (n) => n.name == otherProvider,
                        orElse: () => ProviderNode(name: otherProvider, type: 'Unknown'),
                      );
                      final otherColor = _getNodeColor(otherNode.type);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: otherColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SelectableText(
                                  otherProvider,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conn.strength}x',
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ] else
                    const Text(
                      'No connections detected',
                      style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }

  Color _getNodeColor(String type) {
    // Match exact types returned by RiverpodDevToolsObserver.getProviderType()
    switch (type) {
      case 'StateNotifierProvider':
        return const Color(0xFFA5D6FF); // Lighter blue
      case 'ChangeNotifierProvider':
        return const Color(0xFFB4A7D6); // Light purple
      case 'AsyncNotifierProvider':
      case 'StreamNotifierProvider':
      case 'NotifierProvider':
        return const Color(0xFFFF7B72); // Red
      case 'FutureProvider':
        return const Color(0xFFD2A8FF); // Purple
      case 'StreamProvider':
        return const Color(0xFF7EE787); // Green
      case 'StateProvider':
        return const Color(0xFF79C0FF); // Light blue
      case 'Provider':
        return const Color(0xFFFFA657); // Orange
      default:
        return const Color(0xFF8B949E); // Gray for Unknown
    }
  }
}

/// Custom painter for provider graph
class _ProviderGraphPainter extends CustomPainter {
  final ProviderNetwork network;
  final String? selectedProvider;
  final Map<String, Offset> nodePositions;
  final Map<String, double> nodeRadii;

  _ProviderGraphPainter({
    required this.network,
    required this.selectedProvider,
    required this.nodePositions,
    required this.nodeRadii,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = network.nodes;
    if (nodes.isEmpty || nodePositions.isEmpty) return;

    // Draw connections first (behind nodes)
    _drawConnections(canvas);

    // Draw nodes
    _drawNodes(canvas);
  }

  void _drawConnections(Canvas canvas) {
    final connections = network.connections;

    for (final conn in connections) {
      final from = nodePositions[conn.fromProvider];
      final to = nodePositions[conn.toProvider];
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

  void _drawNodes(Canvas canvas) {
    final nodes = network.nodes;

    for (final node in nodes) {
      final position = nodePositions[node.name];
      if (position == null) continue;

      final isSelected = node.name == selectedProvider;
      final radius = nodeRadii[node.name] ?? 20.0;

      // Draw node circle
      final paint = Paint()
        ..color = isSelected ? const Color(0xFF6366F1) : _getNodeColor(node.type)
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
    // Match exact types returned by RiverpodDevToolsObserver.getProviderType()
    switch (type) {
      case 'StateNotifierProvider':
        return const Color(0xFFA5D6FF); // Lighter blue
      case 'ChangeNotifierProvider':
        return const Color(0xFFB4A7D6); // Light purple
      case 'AsyncNotifierProvider':
      case 'StreamNotifierProvider':
      case 'NotifierProvider':
        return const Color(0xFFFF7B72); // Red
      case 'FutureProvider':
        return const Color(0xFFD2A8FF); // Purple
      case 'StreamProvider':
        return const Color(0xFF7EE787); // Green
      case 'StateProvider':
        return const Color(0xFF79C0FF); // Light blue
      case 'Provider':
        return const Color(0xFFFFA657); // Orange
      default:
        return const Color(0xFF8B949E); // Gray for Unknown
    }
  }

  String _abbreviate(String name) {
    if (name.length <= 15) return name;
    return '${name.substring(0, 12)}...';
  }

  @override
  bool shouldRepaint(_ProviderGraphPainter oldDelegate) {
    return oldDelegate.selectedProvider != selectedProvider ||
        oldDelegate.network != network ||
        oldDelegate.nodePositions != nodePositions;
  }
}
