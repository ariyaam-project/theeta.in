import 'package:shared_preferences/shared_preferences.dart';

import '../models/reel.dart';

/// Local persistence for saved reels.
///
/// MVP storage = shared_preferences (one JSON blob). Swap this class for an
/// API-backed implementation later without touching the UI.
class ReelRepository {
  static const _key = 'reels.v1';

  Future<List<Reel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Reel.decodeList(raw)
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Reel> reels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Reel.encodeList(reels));
  }

  /// Add a reel, deduped by id. Returns the updated list (newest first).
  Future<List<Reel>> add(Reel reel) async {
    final reels = await load();
    reels.removeWhere((r) => r.id == reel.id);
    reels.add(reel);
    reels.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    await _save(reels);
    return reels;
  }

  Future<List<Reel>> remove(String id) async {
    final reels = await load();
    reels.removeWhere((r) => r.id == id);
    await _save(reels);
    return reels;
  }
}
