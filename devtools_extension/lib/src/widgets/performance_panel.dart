import 'package:flutter/material.dart';

/// Performance metrics panel for DevTools extension
class PerformancePanel extends StatelessWidget {
  final Map<String, dynamic>? performanceStats;

  const PerformancePanel({
    super.key,
    this.performanceStats,
  });

  @override
  Widget build(BuildContext context) {
    if (performanceStats == null || performanceStats!.isEmpty) {
      return const Center(
        child: Text(
          'Performance metrics collection is disabled.\n\n'
          'Enable it by setting collectPerformanceMetrics: true in TrackerConfig',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final totalOperations = performanceStats!['totalOperations'] as int? ?? 0;
    final totalTimeMs = performanceStats!['totalTimeMs'] as double? ?? 0.0;
    final averageTimeMs = performanceStats!['averageTimeMs'] as double? ?? 0.0;
    final providerStats =
        performanceStats!['providerStats'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Overall statistics card
        Card(
          margin: const EdgeInsets.all(16),
          color: const Color(0xFF1E1E1E),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Operations',
                      totalOperations.toString(),
                      Icons.functions,
                    ),
                    _buildStatItem(
                      'Total Time',
                      '${totalTimeMs.toStringAsFixed(2)} ms',
                      Icons.timer,
                    ),
                    _buildStatItem(
                      'Average Time',
                      '${averageTimeMs.toStringAsFixed(3)} ms',
                      Icons.speed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Provider statistics header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Provider Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Provider statistics table
        Expanded(
          child: providerStats.isEmpty
              ? const Center(
                  child: Text(
                    'No provider statistics available yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: providerStats.length,
                  itemBuilder: (context, index) {
                    final stats = providerStats[index] as Map<String, dynamic>;
                    return _buildProviderCard(stats);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> stats) {
    final providerName = stats['providerName'] as String? ?? 'Unknown';
    final updateCount = stats['updateCount'] as int? ?? 0;
    final averageTimeMs = stats['averageTimeMs'] as double? ?? 0.0;
    final maxTimeMs = stats['maxTimeMs'] as double? ?? 0.0;
    final minTimeMs = stats['minTimeMs'] as double? ?? 0.0;
    final averageStackTraceMs =
        stats['averageStackTraceMs'] as double? ?? 0.0;
    final averageSerializationMs =
        stats['averageSerializationMs'] as double? ?? 0.0;
    final totalTimeMs = stats['totalTimeMs'] as double? ?? 0.0;

    // Determine performance level based on average time
    Color performanceColor;
    String performanceLabel;
    if (averageTimeMs < 1.0) {
      performanceColor = Colors.green;
      performanceLabel = 'Excellent';
    } else if (averageTimeMs < 5.0) {
      performanceColor = Colors.blue;
      performanceLabel = 'Good';
    } else if (averageTimeMs < 10.0) {
      performanceColor = Colors.orange;
      performanceLabel = 'Fair';
    } else {
      performanceColor = Colors.red;
      performanceLabel = 'Slow';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1E1E1E),
      child: ExpansionTile(
        leading: Icon(Icons.analytics, color: performanceColor),
        title: Text(
          providerName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$performanceLabel - $updateCount updates, ${averageTimeMs.toStringAsFixed(3)} ms avg',
          style: TextStyle(
            color: performanceColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Update Count', updateCount.toString()),
                _buildDetailRow('Total Time',
                    '${totalTimeMs.toStringAsFixed(2)} ms'),
                _buildDetailRow('Average Time',
                    '${averageTimeMs.toStringAsFixed(3)} ms'),
                _buildDetailRow(
                    'Max Time', '${maxTimeMs.toStringAsFixed(3)} ms'),
                _buildDetailRow(
                    'Min Time', '${minTimeMs.toStringAsFixed(3)} ms'),
                const Divider(color: Colors.grey),
                _buildDetailRow('Avg Stack Trace Parsing',
                    '${averageStackTraceMs.toStringAsFixed(3)} ms'),
                _buildDetailRow('Avg Value Serialization',
                    '${averageSerializationMs.toStringAsFixed(3)} ms'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
