import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/reel.dart';
import '../../services/instagram_link.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/spot_sheet.dart';
import '../saved_spots_page.dart';

// Web palette (web/pages/index.vue): purple primary + lavender soft.
const _purple = Color(0xFF8B80D6);
const _soft = Color(0xFFECE9FB);

enum _Filter { all, located, mine }

/// Home: a soft, card-based discovery view — trending spots, recent saves,
/// and quick actions. Replaces the old plain list.
class FoodListTab extends StatefulWidget {
  final AppState state;
  final VoidCallback? onOpenMap;
  const FoodListTab({super.key, required this.state, this.onOpenMap});

  @override
  State<FoodListTab> createState() => _FoodListTabState();
}

class _FoodListTabState extends State<FoodListTab> {
  final _addInput = TextEditingController();
  _Filter _filter = _Filter.all;

  AppState get _state => widget.state;

  @override
  void dispose() {
    _addInput.dispose();
    super.dispose();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  String _name(Reel r) =>
      r.restaurant?.name ?? r.locationExtraction?.restaurantName ?? 'Spot pending';

  String _place(Reel r) =>
      [r.restaurant?.area, r.restaurant?.city].whereType<String>().join(', ');

  bool _located(Reel r) =>
      r.restaurant?.lat != null && r.restaurant?.lng != null;

  List<Reel> get _visible {
    var list = _state.reels.toList();
    if (_filter == _Filter.located) list = list.where(_located).toList();
    return list;
  }

  List<Reel> get _trending {
    final located = _visible.where(_located).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    if (located.isNotEmpty) return located;
    return _visible.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  List<Reel> get _recent =>
      (_visible.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt)))
          .take(12)
          .toList();

  Future<void> _setFilter(_Filter f) async {
    if (f == _filter) return;
    setState(() => _filter = f);
    await _state.setMineOnly(f == _Filter.mine);
  }

  // ---- actions ----------------------------------------------------------

  void _surprise() {
    final pool = _trending;
    if (pool.isEmpty) {
      _snack('No spots yet — add a reel first');
      return;
    }
    showSpotSheet(context, _state, pool[Random().nextInt(pool.length)]);
  }

  void _showAddSheet() {
    _addInput.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a spot',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink),
            ),
            const SizedBox(height: 4),
            const Text(
              'Paste an Instagram reel link.',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _addInput,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'https://www.instagram.com/reel/...',
                filled: true,
                fillColor: _soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submitAdd(ctx),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _submitAdd(ctx),
                icon: const Icon(Icons.add_link),
                label: const Text('Save and process'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAdd(BuildContext sheetCtx) async {
    final link = parseInstagram(_addInput.text);
    if (link == null) {
      _snack('Paste a valid Instagram reel link');
      return;
    }
    Navigator.pop(sheetCtx);
    final err = await _state.addLink(link.url);
    if (!mounted) return;
    _snack(err == null ? 'Reel saved for processing' : 'Could not save: $err');
  }

  // ---- build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final hasAny = _state.reels.isNotEmpty;
        return RefreshIndicator(
          onRefresh: _state.refreshAll,
          color: ink,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              _hero(),
              const SizedBox(height: 18),
              _chips(),
              if (!hasAny) ...[
                const SizedBox(height: 28),
                _emptyState(),
              ] else ...[
                const SizedBox(height: 22),
                _sectionHeader(
                  'Trending spots',
                  '${_trending.length} place${_trending.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 12),
                _trendingRow(),
                const SizedBox(height: 26),
                _recentHeader(),
                const SizedBox(height: 12),
                _recentRow(),
                const SizedBox(height: 26),
                _sectionHeader('Discover', null),
                const SizedBox(height: 12),
                _discover(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _hero() {
    final highlight = Paint()..color = _soft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE TASTIEST REELS, RESOLVED',
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              color: ink,
              fontSize: 33,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
            children: [
              const TextSpan(text: 'Turn reels\ninto '),
              TextSpan(text: 'real', style: TextStyle(background: highlight)),
              const TextSpan(text: '\n'),
              const TextSpan(
                text: 'food spots',
                style: TextStyle(color: accent),
              ),
              const TextSpan(text: ' !'),
            ],
          ),
        ),
      ],
    );
  }

  void _openSaved() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SavedSpotsPage(state: _state)),
    );
  }

  Widget _recentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent saves',
          style: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        GestureDetector(
          onTap: _openSaved,
          child: const Row(
            children: [
              Text(
                'View all',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.arrow_forward, size: 16, color: accent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chips() {
    Widget chip(String label, _Filter f) {
      final selected = _filter == f;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () => _setFilter(f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _purple : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? _purple : Colors.black12,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', _Filter.all),
          chip('Located', _Filter.located),
          chip('Saved by me', _Filter.mine),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _trendingRow() {
    final items = _trending;
    if (items.isEmpty) return _noMatch();
    return SizedBox(
      height: 212,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _bigCard(items[i]),
      ),
    );
  }

  Widget _recentRow() {
    final items = _recent;
    if (items.isEmpty) return _noMatch();
    return Column(
      children: [
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _recentCard(r),
          ),
      ],
    );
  }

  Widget _bigCard(Reel r) {
    final conf = r.restaurant?.confidence ??
        r.locationExtraction?.suggestedLocationConfidence;
    return GestureDetector(
      onTap: () => showSpotSheet(context, _state, r),
      child: Container(
        width: 256,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 84,
              width: double.infinity,
              decoration: BoxDecoration(
                color: r.isProcessing ? const Color(0x55F3A18B) : _soft,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Stack(
                children: [
                  const Center(
                    child:
                        Icon(Icons.restaurant, size: 28, color: Colors.black26),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _badge(r.isProcessing ? 'Processing' : 'Trending'),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.favorite_border,
                          size: 17, color: ink),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(r),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 15, color: Colors.black38),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _place(r).isEmpty ? 'Location pending' : _place(r),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (conf != null)
                        _infoPill(Icons.star_rounded,
                            (conf * 5).toStringAsFixed(1)),
                      if (conf != null) const SizedBox(width: 8),
                      _infoPill(Icons.movie_outlined, 'Reel'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentCard(Reel r) {
    return GestureDetector(
      onTap: () => showSpotSheet(context, _state, r),
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
                color: _soft,
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
                    _name(r),
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
                    _place(r).isEmpty ? r.timeAgo : '${_place(r)} · ${r.timeAgo}',
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
            if (r.isProcessing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: gold),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _discover() {
    return Row(
      children: [
        Expanded(
          child: _ctaTile(Icons.casino_outlined, 'Surprise me', _purple, _surprise),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ctaTile(Icons.map_outlined, 'Explore map', peach,
              () => widget.onOpenMap?.call()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ctaTile(Icons.add_link, 'Add a reel', _soft, _showAddSheet),
        ),
      ],
    );
  }

  Widget _ctaTile(IconData icon, String label, Color color, VoidCallback onTap) {
    final fg = color == _purple ? Colors.white : ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ink),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noMatch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Text(
          'Nothing here yet.',
          style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.movie_filter_outlined, size: 56, color: ink),
          const SizedBox(height: 14),
          const Text(
            'No spots yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share an Instagram food reel to Theeta, or add a link.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _showAddSheet,
              icon: const Icon(Icons.add_link),
              label: const Text('Add a reel'),
            ),
          ),
        ],
      ),
    );
  }
}
