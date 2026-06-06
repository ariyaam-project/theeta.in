import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/reel_repository.dart';
import '../models/reel.dart';
import '../services/instagram_link.dart';
import '../services/share_service.dart';
import '../widgets/reel_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = ReelRepository();
  final _share = ShareService();
  StreamSubscription<InstagramLink>? _sub;
  Future<void> _shareQueue = Future.value();

  List<Reel> _reels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final reels = await _repo.load();
    if (!mounted) return;
    setState(() {
      _reels = reels;
      _loading = false;
    });
    _sub = _share.links.listen(_queueShared);
    await _share.init();
  }

  void _queueShared(InstagramLink link) {
    _shareQueue = _shareQueue.then((_) => _onShared(link));
  }

  Future<void> _onShared(InstagramLink link) async {
    await _addLink(link);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Reel added')));
  }

  Future<void> _addLink(InstagramLink link) async {
    final reel = Reel(
      id: link.shortcode,
      url: link.url,
      addedAt: DateTime.now(),
    );
    final reels = await _repo.add(reel);
    if (mounted) setState(() => _reels = reels);
  }

  Future<void> _remove(Reel reel) async {
    final reels = await _repo.remove(reel.id);
    if (mounted) setState(() => _reels = reels);
  }

  Future<void> _open(Reel reel) async {
    final uri = Uri.parse(reel.url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open reel')));
    }
  }

  Future<void> _addManually() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add reel link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'Paste Instagram reel URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final link = parseInstagram(text);
    if (link == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not a valid Instagram reel link')),
        );
      }
      return;
    }
    await _addLink(link);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _share.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theta'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                _reels.isEmpty ? 'No reels yet' : '${_reels.length} reels',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManually,
        icon: const Icon(Icons.add_link),
        label: const Text('Add reel'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reels.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: () async {
        final reels = await _repo.load();
        if (mounted) setState(() => _reels = reels);
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _reels.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final reel = _reels[i];
          return ReelTile(
            reel: reel,
            onOpen: () => _open(reel),
            onDelete: () => _remove(reel),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'No reels yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Share an Instagram reel to Theta, or tap "Add reel" to paste a link.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
