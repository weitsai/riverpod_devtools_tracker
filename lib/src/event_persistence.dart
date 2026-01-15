import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Handles persistent storage of Riverpod state change events.
///
/// Events are stored as JSON Lines (one JSON object per line) in a file
/// in the application documents directory. This allows event history to
/// be preserved across DevTools disconnections and app sessions.
///
/// Features:
/// - Automatic file size management (max 10 MB)
/// - JSON Lines format for efficient append operations
/// - Robust error handling for corrupted lines
/// - Easy event loading and clearing
class EventPersistence {
  /// Maximum file size before clearing (10 MB)
  static const _maxFileSize = 10 * 1024 * 1024;

  /// File name for storing events
  static const _fileName = 'riverpod_events.jsonl';

  /// Whether to clear events on first save
  final bool _clearOnStart;

  /// Whether the initial clear has been done
  bool _hasCleared = false;

  /// Creates an EventPersistence instance.
  ///
  /// If [clearOnStart] is true, all existing events will be cleared
  /// before the first event is saved.
  EventPersistence({bool clearOnStart = false}) : _clearOnStart = clearOnStart;

  /// Save a single event to persistent storage.
  ///
  /// Events are appended to the file as JSON Lines (one JSON per line).
  /// If the file exceeds [_maxFileSize], it will be cleared before saving.
  ///
  /// Example:
  /// ```dart
  /// await persistence.saveEvent({
  ///   'type': 'UPDATE',
  ///   'providerName': 'counterProvider',
  ///   'timestamp': DateTime.now().toIso8601String(),
  ///   'value': 42,
  /// });
  /// ```
  Future<void> saveEvent(Map<String, dynamic> event) async {
    try {
      final file = await _getEventFile();

      // Clear on first save if configured
      if (_clearOnStart && !_hasCleared) {
        _hasCleared = true;
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Check file size and clear if too large
      if (await file.exists()) {
        final size = await file.length();
        if (size > _maxFileSize) {
          await file.delete();
        }
      }

      // Append event as JSON line
      final eventJson = json.encode(event);
      await file.writeAsString(
        '$eventJson\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // Silent failure - persistence is optional
      // In production, you might want to log this
      // print('Failed to save event: $e');
    }
  }

  /// Load all events from persistent storage.
  ///
  /// Returns a list of event maps. Corrupted JSON lines are skipped silently.
  /// If the file doesn't exist or is empty, returns an empty list.
  ///
  /// Example:
  /// ```dart
  /// final events = await persistence.loadEvents();
  /// print('Loaded ${events.length} events');
  /// ```
  Future<List<Map<String, dynamic>>> loadEvents() async {
    try {
      final file = await _getEventFile();

      if (!await file.exists()) {
        return [];
      }

      final lines = await file.readAsLines();
      final events = <Map<String, dynamic>>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        try {
          final event = json.decode(line) as Map<String, dynamic>;
          events.add(event);
        } catch (_) {
          // Skip corrupted lines silently
          continue;
        }
      }

      return events;
    } catch (e) {
      // Silent failure - return empty list
      return [];
    }
  }

  /// Load a limited number of recent events from persistent storage.
  ///
  /// Returns the last [maxEvents] events. Useful for limiting memory usage
  /// when there are many stored events.
  ///
  /// Example:
  /// ```dart
  /// final recentEvents = await persistence.loadRecentEvents(maxEvents: 100);
  /// ```
  Future<List<Map<String, dynamic>>> loadRecentEvents({
    required int maxEvents,
  }) async {
    final allEvents = await loadEvents();

    if (allEvents.length <= maxEvents) {
      return allEvents;
    }

    // Return last N events
    return allEvents.sublist(allEvents.length - maxEvents);
  }

  /// Clear all stored events.
  ///
  /// Deletes the event storage file. Use this to reset the event history.
  ///
  /// Example:
  /// ```dart
  /// await persistence.clearEvents();
  /// print('Event history cleared');
  /// ```
  Future<void> clearEvents() async {
    try {
      final file = await _getEventFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silent failure
      // print('Failed to clear events: $e');
    }
  }

  /// Get the number of stored events.
  ///
  /// Counts the number of valid JSON lines in the storage file.
  ///
  /// Example:
  /// ```dart
  /// final count = await persistence.getEventCount();
  /// print('Total events: $count');
  /// ```
  Future<int> getEventCount() async {
    try {
      final file = await _getEventFile();

      if (!await file.exists()) {
        return 0;
      }

      final lines = await file.readAsLines();
      return lines.where((line) => line.trim().isNotEmpty).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get the storage file size in bytes.
  ///
  /// Returns 0 if the file doesn't exist or on error.
  ///
  /// Example:
  /// ```dart
  /// final size = await persistence.getFileSize();
  /// print('Storage size: ${size / 1024} KB');
  /// ```
  Future<int> getFileSize() async {
    try {
      final file = await _getEventFile();

      if (!await file.exists()) {
        return 0;
      }

      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Get the event storage file.
  ///
  /// Returns a [File] object pointing to the events file in the
  /// application documents directory.
  Future<File> _getEventFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }
}
