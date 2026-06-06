import 'package:flutter/material.dart';

import '../../models/reel.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// At-a-glance numbers derived client-side from the saved reels.
class AnalyticsTab extends StatelessWidget {
  final AppState state;
  const AnalyticsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final reels = state.reels;
        final located = state.located;
        final processing = reels.where((r) => r.isProcessing).length;
        final cities = located
            .map((r) => r.restaurant?.city)
            .whereType<String>()
            .toSet();
        final confidences = located
            .map((r) => r.restaurant?.confidence)
            .whereType<double>()
            .toList();
        final avgConfidence = confidences.isEmpty
            ? null
            : confidences.reduce((a, b) => a + b) / confidences.length;

        return RefreshIndicator(
          onRefresh: state.refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              const SectionTitle(
                title: 'Analytics',
                subtitle: 'Your saved spots at a glance.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _stat('Saved', '${reels.length}', Icons.bookmark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stat(
                      'Resolved',
                      '${located.length}',
                      Icons.place,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Processing',
                      '$processing',
                      Icons.hourglass_bottom,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stat('Cities', '${cities.length}', Icons.location_city),
                  ),
                ],
              ),
              if (avgConfidence != null) ...[
                const SizedBox(height: 12),
                _stat(
                  'Avg resolution confidence',
                  '${(avgConfidence * 100).round()}%',
                  Icons.verified,
                ),
              ],
              const SizedBox(height: 22),
              _statusBreakdown(reels),
              const SizedBox(height: 22),
              _topCities(located),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBreakdown(List<Reel> reels) {
    final counts = <String, int>{};
    for (final reel in reels) {
      final key = reel.savedStatus == 'processed' ? 'complete' : reel.status;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = reels.length;

    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Kicker('By status'),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'No reels yet.',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            )
          else
            ...entries.map((e) => _bar(_pretty(e.key), e.value, total)),
        ],
      ),
    );
  }

  Widget _bar(String label, int value, int total) {
    final fraction = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.04, 1.0),
                child: Container(height: 8, color: gold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topCities(List<Reel> located) {
    final counts = <String, int>{};
    for (final reel in located) {
      final city = reel.restaurant?.city;
      if (city != null && city.isNotEmpty) {
        counts[city] = (counts[city] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Kicker('Top cities'),
          const SizedBox(height: 12),
          if (top.isEmpty)
            const Text(
              'No located spots yet.',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            )
          else
            ...top.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _pretty(String status) =>
      status.isEmpty ? 'unknown' : status[0].toUpperCase() + status.substring(1);
}
