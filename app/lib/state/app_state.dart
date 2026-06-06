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
      var list = await repo.load(mineOnly: mineOnly);
      for (final reel in list.where((r) => r.isProcessing).toList()) {
        final fresh = await repo.refresh(reel);
        if (fresh != null) {
          final i = list.indexWhere((r) => r.id == fresh.id);
          if (i >= 0) list[i] = fresh;
        }
      }
      reels = list;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
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
