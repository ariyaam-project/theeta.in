import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/reel_repository.dart';
import '../models/reel.dart';

/// Single source of truth for auth + saved reels, shared across all tabs.
/// Plain [ChangeNotifier] — no external state-management dependency.
class AppState extends ChangeNotifier {
  final ReelRepository repo;

  AppState({ReelRepository? repository}) : repo = repository ?? ReelRepository();

  bool bootstrapped = false;
  bool loggedIn = false;
  Map<String, dynamic>? user;
  List<Reel> reels = [];
  bool busy = false;
  String? error;

  /// false = show reels saved by anyone; true = only the current user's saves.
  bool mineOnly = false;

  // Auto-poll while any reel is still processing (the API resolves async).
  Timer? _poll;
  int _pollTicks = 0;
  static const _maxPollTicks = 45; // ~3 min at 4s

  void _ensurePolling() {
    if (reels.any((r) => r.isProcessing) && _pollTicks < _maxPollTicks) {
      _poll ??= Timer.periodic(const Duration(seconds: 4), (_) => _pollTick());
    } else {
      _stopPolling();
    }
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _pollTick() async {
    _pollTicks++;
    final processing = reels.where((r) => r.isProcessing).toList();
    if (processing.isEmpty) {
      _stopPolling();
      return;
    }
    var changed = false;
    for (final r in processing) {
      final fresh = await repo.refresh(r);
      if (fresh == null) continue;
      final i = reels.indexWhere((x) => x.id == fresh.id);
      if (i >= 0) {
        reels[i] = fresh;
        changed = true;
      }
    }
    if (changed) notifyListeners();
    if (_pollTicks >= _maxPollTicks || !reels.any((r) => r.isProcessing)) {
      _stopPolling();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  String get displayName => (user?['displayName'] as String?) ?? 'You';
  String get email => (user?['email'] as String?) ?? '';

  /// Resolved spots (have map coordinates).
  List<Reel> get located => reels
      .where((r) => r.restaurant?.lat != null && r.restaurant?.lng != null)
      .toList();

  Future<void> bootstrap() async {
    loggedIn = await repo.isLoggedIn();
    if (loggedIn) {
      user = await repo.currentUser();
      reels = await _safeLoad();
    }
    bootstrapped = true;
    notifyListeners();
    _pollTicks = 0;
    _ensurePolling();
  }

  Future<List<Reel>> _safeLoad() async {
    try {
      return await repo.load(mineOnly: mineOnly);
    } catch (_) {
      return reels;
    }
  }

  /// Toggle between everyone's saves and only mine, then reload.
  Future<void> setMineOnly(bool value) async {
    if (mineOnly == value) return;
    mineOnly = value;
    busy = true;
    notifyListeners();
    reels = await _safeLoad();
    busy = false;
    notifyListeners();
    _ensurePolling();
  }

  Future<bool> _auth(Future<void> Function() action, String label) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      user = await repo.currentUser();
      reels = await _safeLoad();
      loggedIn = true;
      _pollTicks = 0;
      _ensurePolling();
      return true;
    } catch (e) {
      error = '$label: $e';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail(String email, String password) =>
      _auth(() => repo.loginWithEmail(email, password), 'Login failed');

  Future<bool> register(String name, String email, String password) =>
      _auth(() => repo.register(name, email, password), 'Sign up failed');

  Future<bool> loginDev() => _auth(repo.loginDev, 'Dev login failed');

  Future<void> logout() async {
    await repo.logout();
    loggedIn = false;
    user = null;
    reels = [];
    error = null;
    notifyListeners();
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  /// Add a reel by url. Returns an error string on failure, null on success.
  Future<String?> addLink(String url) async {
    busy = true;
    notifyListeners();
    try {
      reels = await repo.addLink(url);
      error = null;
      _pollTicks = 0;
      _ensurePolling();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    try {
      final list = await repo.load(mineOnly: mineOnly);
      reels = list;
      notifyListeners(); // show the fresh saved list right away
      // Force-pull detail for anything still processing OR not yet resolved,
      // so names/locations that landed after completion show up.
      for (final reel
          in list.where((r) => r.isProcessing || r.restaurant == null).toList()) {
        final fresh = await repo.refresh(reel);
        if (fresh == null) continue;
        final i = reels.indexWhere((r) => r.id == fresh.id);
        if (i >= 0) reels[i] = fresh;
      }
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
    _pollTicks = 0;
    _ensurePolling();
  }

  Future<void> refreshOne(Reel reel) async {
    try {
      final fresh = await repo.refresh(reel);
      if (fresh == null) return;
      final i = reels.indexWhere((r) => r.id == fresh.id);
      if (i >= 0) {
        reels[i] = fresh;
      } else {
        reels = [fresh, ...reels];
      }
      notifyListeners();
    } catch (_) {
      // keep last-known state
    }
  }

  Future<void> remove(Reel reel) async {
    reels = await repo.remove(reel.id);
    notifyListeners();
  }
}
