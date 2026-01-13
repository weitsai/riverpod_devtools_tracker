import 'package:flutter/material.dart';
import '../models/provider_state_info.dart';

/// Configuration constants for timeline visualization
class TimelineConfig {
  /// Minimum zoom level
  static const double minZoom = 0.1;
  /// Maximum zoom level
  static const double maxZoom = 10.0;
  /// Zoom step factor
  static const double zoomFactor = 1.2;
  /// Maximum number of provider lanes to display
  static const int maxLanes = 10;
  /// Event point radius when not selected
  static const double eventRadius = 4.0;
  /// Event point radius when selected
  static const double selectedEventRadius = 6.0;
  /// Selection ring additional radius
  static const double selectionRingRadius = 2.0;
  /// Horizontal padding ratio (5% on each side)
  static const double horizontalPadding = 0.05;
  /// Content width ratio (90% of total width)
  static const double contentWidthRatio = 0.9;
  /// Lane height factor
  static const double laneHeightFactor = 0.8;
  /// Hit test radius for event detection
  static const double hitTestRadius = 12.0;
  /// Minimum duration in milliseconds (for zero-duration edge case)
  static const int minDurationMs = 100;

  /// Calculate X position for an event based on timestamp
  /// This is a unified method used by both TimelineView and TimelinePainter
  static double calculateXPosition({
    required DateTime eventTime,
    required DateTime startTime,
    required Duration duration,
    required double width,
    double zoomLevel = 1.0,
  }) {
    // Handle zero duration edge case
    if (duration.inMilliseconds == 0) return width / 2;

    final offset = eventTime.difference(startTime);
    final ratio = offset.inMilliseconds / duration.inMilliseconds;

    // Apply zoom to the content width
    final zoomedContentWidth = width * contentWidthRatio * zoomLevel;
    final paddingWidth = width * horizontalPadding;

    return (ratio * zoomedContentWidth) + paddingWidth;
  }
}

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

  // Cached provider lanes for hit testing
  Map<String, int>? _providerLanes;
  DateTime? _startTime;
  Duration? _duration;

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
            onPressed: () => setState(() {
              _zoomLevel = (_zoomLevel * TimelineConfig.zoomFactor)
                  .clamp(TimelineConfig.minZoom, TimelineConfig.maxZoom);
            }),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Color(0xFF8B949E)),
            iconSize: 20,
            onPressed: () => setState(() {
              _zoomLevel = (_zoomLevel / TimelineConfig.zoomFactor)
                  .clamp(TimelineConfig.minZoom, TimelineConfig.maxZoom);
            }),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            final event = _findEventAtPosition(
              details.localPosition,
              constraints.biggest,
            );
            if (event != null) {
              widget.onEventSelected(event);
            }
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _panOffset += details.delta.dx;
              // Limit pan offset to reasonable bounds
              final maxPan = constraints.maxWidth * _zoomLevel;
              _panOffset = _panOffset.clamp(-maxPan, maxPan);
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
                onLanesCalculated: (lanes, start, duration) {
                  // Cache for hit testing
                  _providerLanes = lanes;
                  _startTime = start;
                  _duration = duration;
                },
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  /// Find the event at the given position for hit testing
  ProviderStateInfo? _findEventAtPosition(Offset position, Size size) {
    if (widget.events.isEmpty ||
        _providerLanes == null ||
        _startTime == null ||
        _duration == null) {
      return null;
    }

    final axisY = size.height / 2;
    final laneCount = _providerLanes!.length;
    final laneHeight = size.height / (laneCount.clamp(1, TimelineConfig.maxLanes) + 2);

    // Check each event for collision
    for (final event in widget.events) {
      final lane = _providerLanes![event.providerName];
      if (lane == null) continue;

      final x = TimelineConfig.calculateXPosition(
        eventTime: event.timestamp,
        startTime: _startTime!,
        duration: _duration!,
        width: size.width,
        zoomLevel: _zoomLevel,
      );

      final y = axisY + (lane - laneCount / 2) * laneHeight * TimelineConfig.laneHeightFactor;

      // Apply pan offset
      final adjustedX = x + _panOffset;

      // Check if click is within hit test radius
      final dx = position.dx - adjustedX;
      final dy = position.dy - y;
      final distance = dx * dx + dy * dy;

      if (distance <= TimelineConfig.hitTestRadius * TimelineConfig.hitTestRadius) {
        return event;
      }
    }

    return null;
  }
}

/// Custom painter for timeline visualization
class TimelinePainter extends CustomPainter {
  final List<ProviderStateInfo> events;
  final ProviderStateInfo? selectedEvent;
  final double zoomLevel;
  final double panOffset;
  final Function(Map<String, int>, DateTime, Duration)? onLanesCalculated;

  // Cached sorted events to avoid repeated sorting
  List<ProviderStateInfo>? _cachedSortedEvents;

  TimelinePainter({
    required this.events,
    required this.selectedEvent,
    required this.zoomLevel,
    required this.panOffset,
    this.onLanesCalculated,
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

    // Get time range (use cached sorted events)
    _cachedSortedEvents ??= events.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sortedEvents = _cachedSortedEvents!;
    final startTime = sortedEvents.first.timestamp;
    final endTime = sortedEvents.last.timestamp;
    final duration = endTime.difference(startTime);

    // Draw time labels
    _drawTimeLabels(canvas, size, startTime, duration, paint);

    // Group events by provider and count events per provider
    final Map<String, List<ProviderStateInfo>> eventsByProvider = {};
    for (final event in events) {
      eventsByProvider.putIfAbsent(event.providerName, () => []).add(event);
    }

    // Sort providers by event count (most active first) and limit to maxLanes
    final sortedProviderNames = eventsByProvider.keys.toList()
      ..sort((a, b) => eventsByProvider[b]!.length.compareTo(eventsByProvider[a]!.length));

    final displayedProviders = sortedProviderNames.take(TimelineConfig.maxLanes).toList();
    final totalProviderCount = sortedProviderNames.length;

    // Assign lanes to displayed providers
    final Map<String, int> providerLanes = {};
    for (int i = 0; i < displayedProviders.length; i++) {
      providerLanes[displayedProviders[i]] = i;
    }

    // Notify parent of lane calculations for hit testing
    onLanesCalculated?.call(providerLanes, startTime, duration);

    final laneCount = displayedProviders.length;
    final laneHeight = size.height / (laneCount.clamp(1, TimelineConfig.maxLanes) + 2);

    // Draw warning if too many providers
    if (totalProviderCount > TimelineConfig.maxLanes) {
      final hiddenCount = totalProviderCount - TimelineConfig.maxLanes;
      _drawWarning(
        canvas,
        size,
        'Showing top ${TimelineConfig.maxLanes} most active providers ($hiddenCount hidden)',
      );
    }

    // Draw events (only for displayed providers)
    for (final event in events) {
      final lane = providerLanes[event.providerName];
      if (lane == null) continue; // Skip events from hidden providers

      final x = TimelineConfig.calculateXPosition(
        eventTime: event.timestamp,
        startTime: startTime,
        duration: duration,
        width: size.width,
        zoomLevel: zoomLevel,
      );

      final y = axisY + (lane - laneCount / 2) * laneHeight * TimelineConfig.laneHeightFactor;

      _drawEvent(canvas, event, x, y, paint);
    }

    // Draw provider lane labels
    _drawLaneLabels(canvas, size, providerLanes, laneHeight, axisY, laneCount);
  }

  /// Draw warning message for too many providers
  void _drawWarning(Canvas canvas, Size size, String message) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚠️ $message',
        style: const TextStyle(
          color: Color(0xFFFFA657),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, 8),
    );
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
      final y = axisY + (lane - laneCount / 2) * laneHeight * TimelineConfig.laneHeightFactor;

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
    final radius = isSelected
        ? TimelineConfig.selectedEventRadius
        : TimelineConfig.eventRadius;

    // Apply pan offset (zoom is already applied in calculateXPosition)
    final adjustedX = x + panOffset;

    // Draw event point
    canvas.drawCircle(
      Offset(adjustedX, y),
      radius,
      paint
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw selection ring if selected
    if (isSelected) {
      canvas.drawCircle(
        Offset(adjustedX, y),
        radius + TimelineConfig.selectionRingRadius,
        paint
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
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
