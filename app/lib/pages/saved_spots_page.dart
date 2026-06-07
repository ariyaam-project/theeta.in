import 'package:flutter/material.dart';

import '../models/reel.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/spot_sheet.dart';

/// Full list of saved spots with search. Opened from "View all" on the home.
class SavedSpotsPage extends StatefulWidget {
  final AppState state;
  const SavedSpotsPage({super.key, required this.state});

  @override
  State<SavedSpotsPage> createState() => _SavedSpotsPageState();
}

class _SavedSpotsPageState extends State<SavedSpotsPage> {
  String _query = '';
  AppState get _state => widget.state;

  bool _match(Reel r) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return spotName(r).toLowerCase().contains(q) ||
        spotPlace(r).toLowerCase().contains(q) ||
        (r.caption ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: ink,
        title: const Text(
          'Saved spots',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          final items = _state.reels.where(_match).toList()
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search spots, areas…',
                      prefixIcon: Icon(Icons.search, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'No spots found.',
                          style: TextStyle(
                              color: Colors.black45, fontWeight: FontWeight.w700),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _SavedTile(
                          reel: items[i],
                          onTap: () =>
                              showSpotSheet(context, _state, items[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  final Reel reel;
  final VoidCallback onTap;
  const _SavedTile({required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final place = spotPlace(reel);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFECE9FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: ink, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spotName(reel),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    place.isEmpty ? reel.timeAgo : '$place · ${reel.timeAgo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (reel.isProcessing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: peach),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
