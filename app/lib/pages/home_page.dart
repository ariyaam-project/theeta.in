import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/reel_repository.dart';
import '../models/reel.dart';
import '../services/google_auth_service.dart';
import '../services/instagram_link.dart';
import '../services/share_service.dart';
import '../widgets/reel_tile.dart';

const _ink = Color(0xFF2F231A);
const _paper = Color(0xFFFFF8EC);
const _accent = Color(0xFFE1306C);
const _gold = Color(0xFFF7AB3F);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = ReelRepository();
  final _googleAuth = GoogleAuthService();
  final _share = ShareService();
  final _manualController = TextEditingController();
  StreamSubscription<InstagramLink>? _sub;
  Future<void> _shareQueue = Future.value();

  List<Reel> _reels = [];
  bool _loading = true;
  bool _loggedIn = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final loggedIn = await _repo.isLoggedIn();
    final reels = loggedIn ? await _repo.load() : <Reel>[];
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _reels = reels;
      _loading = false;
      _error = null;
    });
    _sub = _share.links.listen(_queueShared);
    await _share.init();
  }

  void _queueShared(InstagramLink link) {
    _shareQueue = _shareQueue.then((_) => _onShared(link));
  }

  Future<bool> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final idToken = await _googleAuth.signInAndGetIdToken();
      await _repo.loginWithGoogleIdToken(idToken);
      final reels = await _repo.load();
      if (!mounted) return false;
      setState(() {
        _loggedIn = true;
        _reels = reels;
      });
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = 'Google login failed: $error');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _loginDev() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.loginDev();
      final reels = await _repo.load();
      if (!mounted) return false;
      setState(() {
        _loggedIn = true;
        _reels = reels;
      });
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = 'Login failed: $error');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _googleAuth.signOut();
    } catch (_) {
      // A dev session or failed Google init should still clear the API token.
    }
    await _repo.logout();
    if (!mounted) return;
    setState(() {
      _loggedIn = false;
      _reels = [];
      _error = null;
    });
  }

  Future<void> _onShared(InstagramLink link) async {
    if (!_loggedIn) {
      final loggedIn = await _login();
      if (!loggedIn) return;
    }
    try {
      await _addLink(link);
      if (!mounted) return;
      _snack('Reel saved for processing');
    } catch (error) {
      if (!mounted) return;
      _snack('Could not save reel: $error');
    }
  }

  Future<void> _addLink(InstagramLink link) async {
    setState(() => _busy = true);
    try {
      final reels = await _repo.addLink(link.url);
      if (mounted) {
        setState(() {
          _reels = reels;
          _error = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitManual() async {
    if (!_loggedIn) {
      _snack('Login first');
      return;
    }
    final link = parseInstagram(_manualController.text);
    if (link == null) {
      _snack('Paste a valid Instagram reel link');
      return;
    }
    try {
      await _addLink(link);
      _manualController.clear();
      _snack('Reel saved for processing');
    } catch (error) {
      _snack('Could not save reel: $error');
    }
  }

  Future<void> _remove(Reel reel) async {
    final reels = await _repo.remove(reel.id);
    if (mounted) setState(() => _reels = reels);
  }

  Future<void> _open(Reel reel) async {
    final ok = await launchUrl(
      Uri.parse(reel.url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) _snack('Could not open reel');
  }

  Future<void> _refresh() async {
    if (!_loggedIn) return;
    try {
      var reels = await _repo.load();
      for (final reel in reels.where((item) => item.isProcessing).toList()) {
        final fresh = await _repo.refresh(reel);
        if (fresh != null) {
          final index = reels.indexWhere((item) => item.id == fresh.id);
          if (index >= 0) reels[index] = fresh;
        }
      }
      if (mounted) {
        setState(() {
          _reels = reels;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _refreshOne(Reel reel) async {
    try {
      final fresh = await _repo.refresh(reel);
      if (fresh == null || !mounted) return;
      setState(() {
        final index = _reels.indexWhere((item) => item.id == fresh.id);
        if (index >= 0) {
          _reels[index] = fresh;
        } else {
          _reels = [fresh, ..._reels];
        }
        _error = null;
      });
    } catch (error) {
      if (mounted) _snack('Could not refresh reel: $error');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _manualController.dispose();
    _sub?.cancel();
    _share.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
                  children: [
                    _HeroHeader(
                      loggedIn: _loggedIn,
                      reelsCount: _reels.length,
                      onLogin: _busy ? null : _login,
                      onLogout: _logout,
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) _ErrorCard(message: _error!),
                    if (!_loggedIn)
                      _LoginCard(
                        onLogin: _busy ? null : _login,
                        onDevLogin: _busy ? null : _loginDev,
                      )
                    else
                      _InputCard(
                        controller: _manualController,
                        busy: _busy,
                        onSubmit: _submitManual,
                      ),
                    const SizedBox(height: 22),
                    _SectionTitle(
                      title: 'Saved reels',
                      subtitle: _reels.isEmpty
                          ? 'Share from Instagram or paste a link.'
                          : 'Pull to refresh processing status.',
                    ),
                    const SizedBox(height: 12),
                    if (_reels.isEmpty)
                      const _EmptyState()
                    else
                      ..._reels.map(
                        (reel) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: ReelTile(
                            reel: reel,
                            onOpen: () => _open(reel),
                            onRefresh: () => _refreshOne(reel),
                            onDelete: () => _remove(reel),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final bool loggedIn;
  final int reelsCount;
  final VoidCallback? onLogin;
  final VoidCallback onLogout;

  const _HeroHeader({
    required this.loggedIn,
    required this.reelsCount,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      color: _ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu, color: _ink),
              ),
              const Spacer(),
              TextButton(
                onPressed: loggedIn ? onLogout : onLogin,
                child: Text(loggedIn ? 'Logout' : 'Login'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'theeta.in',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              height: 0.95,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loggedIn
                ? '$reelsCount reel${reelsCount == 1 ? '' : 's'} saved for AI location analysis'
                : 'Login, share reels, and let AI resolve the food spot.',
            style: const TextStyle(
              color: Color(0xFFFFE3B5),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final VoidCallback? onLogin;
  final VoidCallback? onDevLogin;

  const _LoginCard({required this.onLogin, required this.onDevLogin});

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('Google auth'),
          const SizedBox(height: 8),
          const Text(
            'Sign in to save reels',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Google Sign-In returns an ID token, then the API exchanges it for a Theta bearer token.',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.account_circle),
              label: const Text('Continue with Google'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDevLogin,
              icon: const Icon(Icons.code),
              label: const Text('Use dev login'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;

  const _InputCard({
    required this.controller,
    required this.busy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('Reel input'),
          const SizedBox(height: 8),
          const Text(
            'Paste a reel link',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://www.instagram.com/reel/...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: _ink, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: _ink, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onSubmit,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _ShadowCard(
        color: _accent,
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      child: const Column(
        children: [
          Icon(Icons.movie_filter_outlined, size: 64, color: _ink),
          SizedBox(height: 14),
          Text(
            'No reels yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Share an Instagram reel to Theta, or paste a link above.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShadowCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const _ShadowCard({required this.child, this.color = _paper});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _ink),
      child: Transform.translate(
        offset: const Offset(-4, -4),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: _ink, width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  final String text;

  const _Kicker(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _accent,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}
