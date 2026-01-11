/// Provider network model for dependency graph visualization
///
/// This model infers provider dependencies based on temporal proximity of updates.
/// When providers update close in time, they are likely related through dependencies.
library;

/// Represents a node in the provider dependency graph
class ProviderNode {
  final String name;
  final String type;
  int updateCount = 0;
  DateTime? lastUpdate;

  ProviderNode({
    required this.name,
    required this.type,
  });

  void recordUpdate() {
    updateCount++;
    lastUpdate = DateTime.now();
  }
}

/// Represents a connection between two providers
class ProviderConnection {
  final String fromProvider;
  final String toProvider;
  int strength = 1; // Number of times they updated together

  ProviderConnection({
    required this.fromProvider,
    required this.toProvider,
  });

  void incrementStrength() {
    strength++;
  }
}

/// Provider network analyzer
///
/// Builds a dependency graph by analyzing temporal patterns in provider updates.
/// Providers that frequently update together (within a time window) are considered
/// potentially connected.
class ProviderNetwork {
  final Map<String, ProviderNode> _nodes = {};
  final List<ProviderConnection> _connections = [];

  /// Time window (in milliseconds) to consider updates as related
  static const int relationshipWindowMs = 100;

  /// Recent updates within the time window
  final List<_RecentUpdate> _recentUpdates = [];

  /// Add or update a provider node
  void recordProviderUpdate(String name, String type) {
    // Get or create node
    final node = _nodes.putIfAbsent(
      name,
      () => ProviderNode(name: name, type: type),
    );
    node.recordUpdate();

    final now = DateTime.now();

    // Find providers that updated recently (within time window)
    final recentProviders = _recentUpdates
        .where((update) {
          final timeDiff = now.difference(update.timestamp).inMilliseconds;
          return timeDiff <= relationshipWindowMs && update.provider != name;
        })
        .map((update) => update.provider)
        .toSet();

    // Create or strengthen connections
    for (final recentProvider in recentProviders) {
      _addOrStrengthenConnection(recentProvider, name);
    }

    // Add this update to recent updates
    _recentUpdates.add(_RecentUpdate(provider: name, timestamp: now));

    // Clean up old updates (older than time window)
    _recentUpdates.removeWhere((update) {
      return now.difference(update.timestamp).inMilliseconds > relationshipWindowMs;
    });
  }

  void _addOrStrengthenConnection(String from, String to) {
    // Check if connection already exists
    final existing = _connections.firstWhere(
      (conn) => conn.fromProvider == from && conn.toProvider == to,
      orElse: () {
        // Create new connection
        final newConn = ProviderConnection(
          fromProvider: from,
          toProvider: to,
        );
        _connections.add(newConn);
        return newConn;
      },
    );

    if (_connections.contains(existing)) {
      existing.incrementStrength();
    }
  }

  /// Get all nodes
  List<ProviderNode> get nodes => _nodes.values.toList();

  /// Get all connections
  List<ProviderConnection> get connections => List.unmodifiable(_connections);

  /// Get connections for a specific provider
  List<ProviderConnection> getConnectionsFor(String providerName) {
    return _connections
        .where((conn) =>
            conn.fromProvider == providerName ||
            conn.toProvider == providerName)
        .toList();
  }

  /// Clear the network
  void clear() {
    _nodes.clear();
    _connections.clear();
    _recentUpdates.clear();
  }

  /// Get network statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalProviders': _nodes.length,
      'totalConnections': _connections.length,
      'averageConnections':
          _connections.isEmpty ? 0.0 : _connections.length / _nodes.length,
      'mostActiveProvider': _getMostActiveProvider(),
      'strongestConnection': _getStrongestConnection(),
    };
  }

  String? _getMostActiveProvider() {
    if (_nodes.isEmpty) return null;
    final sorted = _nodes.values.toList()
      ..sort((a, b) => b.updateCount.compareTo(a.updateCount));
    return sorted.first.name;
  }

  Map<String, dynamic>? _getStrongestConnection() {
    if (_connections.isEmpty) return null;
    final sorted = _connections.toList()
      ..sort((a, b) => b.strength.compareTo(a.strength));
    final strongest = sorted.first;
    return {
      'from': strongest.fromProvider,
      'to': strongest.toProvider,
      'strength': strongest.strength,
    };
  }
}

/// Internal class to track recent updates
class _RecentUpdate {
  final String provider;
  final DateTime timestamp;

  _RecentUpdate({required this.provider, required this.timestamp});
}
