import 'package:flutter/material.dart';

import '../models/reel.dart';
import '../theme.dart';

class ReelTile extends StatelessWidget {
  final Reel reel;
  final VoidCallback onOpen;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const ReelTile({
    super.key,
    required this.reel,
    required this.onOpen,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final restaurant = reel.restaurant;
    final extraction = reel.locationExtraction;
    final locationName =
        restaurant?.name ?? extraction?.restaurantName ?? 'Location pending';
    final locationAddress =
        restaurant?.address ?? extraction?.suggestedAddress ?? _statusLabel;
    final confidence =
        restaurant?.confidence ?? extraction?.suggestedLocationConfidence;

    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -14,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRefresh,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusIcon(processing: reel.isProcessing),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(reel.shortcode),
                          _Pill(_statusLabel),
                          if (confidence != null)
                            _Pill('${(confidence * 100).round()}% confidence'),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  iconColor: muted,
                  onSelected: (v) {
                    if (v == 'open') onOpen();
                    if (v == 'refresh') onRefresh();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Text('Refresh status'),
                    ),
                    PopupMenuItem(
                      value: 'open',
                      child: Text('Open in Instagram'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _statusLabel => reel.savedStatus ?? reel.status;
}

class _StatusIcon extends StatelessWidget {
  final bool processing;

  const _StatusIcon({required this.processing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: processing ? softPurple : accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: processing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            : const Icon(Icons.place, color: Colors.white),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: softPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
