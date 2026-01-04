import 'tracker_config.dart';

/// Location information for code
class LocationInfo {
  /// Full location description (file:line in function)
  final String location;

  /// File path
  final String file;

  /// Line number
  final int line;

  /// Function name
  final String function;

  /// Column (if available)
  final int? column;

  const LocationInfo({
    required this.location,
    required this.file,
    required this.line,
    required this.function,
    this.column,
  });

  Map<String, dynamic> toJson() => {
    'location': location,
    'file': file,
    'line': line,
    'function': function,
    if (column != null) 'column': column,
  };

  @override
  String toString() => location;
}

/// Stack Trace Parser
class StackTraceParser {
  final TrackerConfig config;

  /// Regex for parsing stack trace lines
  /// Matches format: #0 FunctionName (package:path/file.dart:123:45)
  static final _stackLineRegex = RegExp(
    r'#(\d+)\s+(.+?)\s+\((.+?):(\d+)(?::(\d+))?\)',
  );

  StackTraceParser(this.config);

  /// Parse call chain from stack trace
  List<LocationInfo> parseCallChain(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final chain = <LocationInfo>[];

    for (final line in lines) {
      if (chain.length >= config.maxCallChainDepth) break;

      final match = _stackLineRegex.firstMatch(line);
      if (match == null) continue;

      final function = match.group(2)?.trim() ?? '';
      final file = match.group(3) ?? '';
      final lineNum = int.tryParse(match.group(4) ?? '') ?? 0;
      final column = int.tryParse(match.group(5) ?? '');

      // Check if should be ignored
      if (_shouldIgnore(file)) continue;

      // Shorten file path
      final shortFile = _shortenFilePath(file);

      chain.add(
        LocationInfo(
          location: '$shortFile:$lineNum',
          file: shortFile,
          line: lineNum,
          function: function,
          column: column,
        ),
      );
    }

    return chain;
  }

  /// Find the user code location that triggered the change
  LocationInfo? findTriggerLocation(StackTrace stackTrace) {
    final callChain = parseCallChain(stackTrace);

    if (callChain.isEmpty) return null;

    // Strategy: find the first location that's not a provider file
    // Since provider files are usually intermediate layers
    for (final loc in callChain) {
      if (!_isProviderFile(loc.file)) {
        return loc;
      }
    }

    // If all are provider files, return the first one
    return callChain.first;
  }

  /// Check if this file should be ignored
  bool _shouldIgnore(String file) {
    // Check ignored package prefixes
    for (final prefix in config.ignoredPackagePrefixes) {
      if (file.startsWith(prefix)) return true;
    }

    // Check ignored file patterns
    for (final pattern in config.ignoredFilePatterns) {
      if (file.contains(pattern)) return true;
    }

    // If package prefixes are set, only keep code from those packages
    if (config.packagePrefixes.isNotEmpty) {
      bool matchesAny = false;
      for (final prefix in config.packagePrefixes) {
        if (file.startsWith(prefix)) {
          matchesAny = true;
          break;
        }
      }
      if (!matchesAny) return true;
    }

    return false;
  }

  /// Shorten file path
  String _shortenFilePath(String file) {
    for (final prefix in config.packagePrefixes) {
      if (file.startsWith(prefix)) {
        return file.substring(prefix.length);
      }
    }
    // Remove package: prefix for readability
    if (file.startsWith('package:')) {
      final parts = file.split('/');
      if (parts.length > 1) {
        return parts.sublist(1).join('/');
      }
    }
    return file;
  }

  /// Check if it's a provider file
  bool _isProviderFile(String file) {
    return file.contains('_provider.dart') ||
        file.contains('/providers/') ||
        file.endsWith('.g.dart');
  }
}
