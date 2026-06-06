import 'package:flutter/material.dart';

import '../models/reel.dart';

const _ink = Color(0xFF2F231A);
const _paper = Color(0xFFFFF8EC);
const _accent = Color(0xFFE1306C);
const _gold = Color(0xFFF7AB3F);

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
      decoration: const BoxDecoration(color: _ink),
      child: Transform.translate(
        offset: const Offset(-3, -3),
        child: Material(
          color: _paper,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: _ink, width: 2),
          ),
          child: InkWell(
            onTap: onRefresh,
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
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w700,
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
                              _Pill(
                                '${(confidence * 100).round()}% confidence',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: processing ? _gold : _accent,
        border: Border.all(color: _ink, width: 2),
      ),
      child: Center(
        child: processing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ink, width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
