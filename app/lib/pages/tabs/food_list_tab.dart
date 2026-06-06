import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/reel.dart';
import '../../services/instagram_link.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/reel_tile.dart';
import '../../widgets/ui.dart';

/// The food spots: paste/share a reel, watch it resolve, browse saved spots.
class FoodListTab extends StatefulWidget {
  final AppState state;
  const FoodListTab({super.key, required this.state});

  @override
  State<FoodListTab> createState() => _FoodListTabState();
}

class _FoodListTabState extends State<FoodListTab> {
  final _input = TextEditingController();

  AppState get _state => widget.state;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final link = parseInstagram(_input.text);
    if (link == null) {
      _snack('Paste a valid Instagram reel link');
      return;
    }
    final err = await _state.addLink(link.url);
    if (!mounted) return;
    if (err == null) {
      _input.clear();
      _snack('Reel saved for processing');
    } else {
      _snack('Could not save reel: $err');
    }
  }

  Future<void> _open(Reel reel) async {
    final ok = await launchUrl(
      Uri.parse(reel.url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) _snack('Could not open reel');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final reels = _state.reels;
        return RefreshIndicator(
          onRefresh: _state.refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              const SectionTitle(
                title: 'Add a spot',
                subtitle: 'Share from Instagram or paste a reel link.',
              ),
              const SizedBox(height: 12),
              _inputCard(),
              const SizedBox(height: 22),
              SectionTitle(
                title: 'Saved reels',
                subtitle: reels.isEmpty
                    ? 'Nothing yet — add your first spot above.'
                    : 'Pull to refresh processing status.',
              ),
              const SizedBox(height: 12),
              if (reels.isEmpty)
                const _EmptyState()
              else
                ...reels.map(
                  (reel) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ReelTile(
                      reel: reel,
                      onOpen: () => _open(reel),
                      onRefresh: () => _state.refreshOne(reel),
                      onDelete: () => _state.remove(reel),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputCard() {
    final busy = _state.busy;
    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Kicker('Reel input'),
          const SizedBox(height: 10),
          TextField(
            controller: _input,
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'https://www.instagram.com/reel/...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: ink, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: ink, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : _submit,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_link),
              label: const Text('Save and process'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const ShadowCard(
      child: Column(
        children: [
          Icon(Icons.movie_filter_outlined, size: 64, color: ink),
          SizedBox(height: 14),
          Text(
            'No reels yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Share an Instagram reel to Theta, or paste a link above.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
