import 'package:flutter/material.dart';
import '../models/provider_state_info.dart';

/// Timeline view for visualizing provider state changes over time
class TimelineView extends StatefulWidget {
  final List<ProviderStateInfo> events;
  final ProviderStateInfo? selectedEvent;
  final Function(ProviderStateInfo) onEventSelected;

  const TimelineView({
    super.key,
    required this.events,
    required this.selectedEvent,
    required this.onEventSelected,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  // Zoom and pan controls
  double _zoomLevel = 1.0;
  double _panOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No events to display',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTimelineControls(),
        Expanded(
          child: _buildTimelineChart(),
        ),
      ],
    );
  }

  Widget _buildTimelineControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(bottom: BorderSide(color: Color(0xFF30363D), width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: Color(0xFF8B949E), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Timeline View',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.events.length} events',
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Color(0xFF8B949E)),
            iconSize: 20,
            onPressed: () => setState(() => _zoomLevel *= 1.2),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Color(0xFF8B949E)),
            iconSize: 20,
            onPressed: () => setState(() => _zoomLevel /= 1.2),
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
            iconSize: 20,
            onPressed: () => setState(() {
              _zoomLevel = 1.0;
              _panOffset = 0.0;
            }),
            tooltip: 'Reset View',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _panOffset += details.delta.dx;
        });
      },
      child: Container(
        color: const Color(0xFF0D1117),
        child: CustomPaint(
          painter: TimelinePainter(
            events: widget.events,
            selectedEvent: widget.selectedEvent,
            zoomLevel: _zoomLevel,
            panOffset: _panOffset,
            onEventTap: widget.onEventSelected,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Custom painter for timeline visualization
class TimelinePainter extends CustomPainter {
  final List<ProviderStateInfo> events;
  final ProviderStateInfo? selectedEvent;
  final double zoomLevel;
  final double panOffset;
  final Function(ProviderStateInfo) onEventTap;

  TimelinePainter({
    required this.events,
    required this.selectedEvent,
    required this.zoomLevel,
    required this.panOffset,
    required this.onEventTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty) return;

    final paint = Paint()..strokeWidth = 2.0;

    // Draw background grid
    _drawGrid(canvas, size, paint);

    // Draw timeline axis
    final axisY = size.height / 2;
    canvas.drawLine(
      Offset(0, axisY),
      Offset(size.width, axisY),
      paint
        ..color = const Color(0xFF30363D)
        ..strokeWidth = 2.0,
    );

    // Get time range
    final sortedEvents = events.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final startTime = sortedEvents.first.timestamp;
    final endTime = sortedEvents.last.timestamp;
    final duration = endTime.difference(startTime);

    // Draw time labels
    _drawTimeLabels(canvas, size, startTime, duration, paint);

    // Group events by provider for lane assignment
    final Map<String, int> providerLanes = {};
    int laneCount = 0;
    for (final event in events) {
      if (!providerLanes.containsKey(event.providerName)) {
        providerLanes[event.providerName] = laneCount++;
      }
    }

    final laneHeight = size.height / (laneCount.clamp(1, 10) + 2);

    // Draw events
    for (final event in events) {
      final x = _getXPosition(event.timestamp, startTime, duration, size.width);
      final lane = providerLanes[event.providerName]!;
      final y = axisY + (lane - laneCount / 2) * laneHeight * 0.8;

      _drawEvent(canvas, event, x, y, paint);
    }

    // Draw provider lane labels
    _drawLaneLabels(canvas, size, providerLanes, laneHeight, axisY, laneCount);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    paint
      ..color = const Color(0xFF30363D).withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Vertical grid lines
    for (int i = 0; i < 10; i++) {
      final x = (size.width / 10) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawTimeLabels(
    Canvas canvas,
    Size size,
    DateTime startTime,
    Duration duration,
    Paint paint,
  ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      final offset = duration * (i / 10);
      final time = startTime.add(offset);
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

      textPainter.text = TextSpan(
        text: timeStr,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 20),
      );
    }
  }

  void _drawLaneLabels(
    Canvas canvas,
    Size size,
    Map<String, int> providerLanes,
    double laneHeight,
    double axisY,
    int laneCount,
  ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    for (final entry in providerLanes.entries) {
      final lane = entry.value;
      final y = axisY + (lane - laneCount / 2) * laneHeight * 0.8;

      textPainter.text = TextSpan(
        text: entry.key,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 10,
        ),
      );
      textPainter.layout(maxWidth: 150);
      textPainter.paint(canvas, Offset(8, y - 5));
    }
  }

  void _drawEvent(
    Canvas canvas,
    ProviderStateInfo event,
    double x,
    double y,
    Paint paint,
  ) {
    final isSelected = selectedEvent?.id == event.id;
    final color = _getEventColor(event.changeType);
    final radius = isSelected ? 6.0 : 4.0;

    // Draw event point
    canvas.drawCircle(
      Offset(x + panOffset * zoomLevel, y),
      radius,
      paint
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw selection ring if selected
    if (isSelected) {
      canvas.drawCircle(
        Offset(x + panOffset * zoomLevel, y),
        radius + 2,
        paint
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  double _getXPosition(
    DateTime eventTime,
    DateTime startTime,
    Duration duration,
    double width,
  ) {
    if (duration.inMilliseconds == 0) return width / 2;
    final offset = eventTime.difference(startTime);
    final ratio = offset.inMilliseconds / duration.inMilliseconds;
    return (ratio * width * 0.9) + (width * 0.05); // Add 5% padding on sides
  }

  Color _getEventColor(String changeType) {
    switch (changeType.toLowerCase()) {
      case 'add':
        return const Color(0xFF3FB950); // Green
      case 'update':
        return const Color(0xFF6366F1); // Purple/Blue
      case 'dispose':
        return const Color(0xFFFFA657); // Orange
      case 'error':
        return const Color(0xFFF85149); // Red
      default:
        return const Color(0xFF8B949E); // Gray
    }
  }

  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.selectedEvent != selectedEvent ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.panOffset != panOffset;
  }
}
