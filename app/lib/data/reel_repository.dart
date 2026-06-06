import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reel.dart';

const _apiBaseOverride = String.fromEnvironment('THETA_API_BASE');

class ReelRepository {
  static const _cacheKey = 'reels.v2';
  static const _tokenKey = 'theta.api.token';
  static const _userKey = 'theta.api.user';
  static const _devEmail = String.fromEnvironment(
    'THETA_DEV_EMAIL',
    defaultValue: 'dev@theta.local',
  );

  final http.Client _client;
  final String apiBase;

  ReelRepository({http.Client? client, String? apiBase})
    : _client = client ?? http.Client(),
      apiBase = apiBase ?? _defaultApiBase();

  Future<List<Reel>> load() async {
    try {
      final token = await _token();
      final response = await _request(
        'GET',
        '/api/reels/saved/list',
        token: token,
      );
      _ensureOk(response, 'load saved reels');
      final items =
          (jsonDecode(response.body)['items'] as List)
              .map((item) => _savedItemToReel(item as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      await _saveCache(items);
      return items;
    } catch (_) {
      return _loadCache();
    }
  }

  Future<List<Reel>> addLink(String url) async {
    final token = await _token();
    final response = await _request(
      'POST',
      '/api/reels',
      token: token,
      body: {'url': url},
    );
    _ensureOk(response, 'save reel');
    final saved = await load();
    return saved;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> loginDev() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    final response = await _request(
      'POST',
      '/api/dev/login',
      body: {'email': _devEmail, 'name': 'Theta Mobile Dev'},
    );
    _ensureOk(response, 'dev login');
    await _storeSession(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> register(String name, String email, String password) async {
    final response = await _request(
      'POST',
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    _ensureOk(response, 'register');
    await _storeSession(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> loginWithEmail(String email, String password) async {
    final response = await _request(
      'POST',
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    _ensureOk(response, 'login');
    await _storeSession(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_cacheKey);
  }

  Future<Reel?> refresh(Reel reel) async {
    final token = await _token();
    final detail = await _request('GET', '/api/reels/${reel.id}', token: token);
    _ensureOk(detail, 'load reel detail');
    final fresh = _detailToReel(
      jsonDecode(detail.body) as Map<String, dynamic>,
      reel,
    );
    final reels = await _loadCache();
    final index = reels.indexWhere((item) => item.id == reel.id);
    if (index >= 0) {
      reels[index] = fresh;
    } else {
      reels.add(fresh);
    }
    reels.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    await _saveCache(reels);
    return fresh;
  }

  Future<List<Reel>> remove(String id) async {
    final reels = await _loadCache();
    reels.removeWhere((r) => r.id == id);
    await _saveCache(reels);
    return reels;
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_tokenKey);
    if (existing != null && existing.isNotEmpty) return existing;
    throw StateError('Not logged in');
  }

  Future<void> _storeSession(Map<String, dynamic> session) async {
    final token = session['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Auth response did not include a bearer token.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    final user = session['user'];
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  Future<http.Response> _request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) {
    final uri = Uri.parse('$apiBase$path');
    final headers = <String, String>{
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);
    return switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(uri, headers: headers, body: encoded),
      _ => throw UnsupportedError(method),
    };
  }

  void _ensureOk(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] is String) {
          detail = decoded['message'] as String;
        }
      } catch (_) {}
      throw StateError('$action failed: $detail');
    }
  }

  Future<List<Reel>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Reel.decodeList(raw)
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache(List<Reel> reels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, Reel.encodeList(reels));
  }
}

String _defaultApiBase() {
  if (_apiBaseOverride.isNotEmpty) {
    return _apiBaseOverride.replaceAll(RegExp(r'/$'), '');
  }
  if (Platform.isAndroid) return 'http://10.0.2.2:8787';
  return 'https://aerosol-reformer-twirl.ngrok-free.dev';
}

Reel _savedItemToReel(Map<String, dynamic> item) {
  final reel = item['reel'] as Map<String, dynamic>;
  return Reel(
    id: item['reelId'] as String,
    shortcode: reel['shortcode'] as String,
    url: reel['url'] as String,
    status: reel['status'] as String,
    savedStatus: item['savedStatus'] as String?,
    caption: reel['caption'] as String?,
    restaurant: reel['restaurant'] == null
        ? null
        : RestaurantLocation.fromJson(
            reel['restaurant'] as Map<String, dynamic>,
          ),
    addedAt: DateTime.parse(item['savedAt'] as String),
  );
}

Reel _detailToReel(Map<String, dynamic> detail, Reel previous) {
  final reel = detail['reel'] as Map<String, dynamic>;
  return Reel(
    id: reel['id'] as String,
    shortcode: reel['shortcode'] as String,
    url: reel['url'] as String,
    status: reel['status'] as String,
    savedStatus: previous.savedStatus,
    caption: reel['caption'] as String?,
    restaurant: reel['restaurant'] == null
        ? null
        : RestaurantLocation.fromJson(
            reel['restaurant'] as Map<String, dynamic>,
          ),
    locationExtraction: reel['locationExtraction'] == null
        ? null
        : LocationExtraction.fromJson(
            reel['locationExtraction'] as Map<String, dynamic>,
          ),
    addedAt: previous.addedAt,
    note: previous.note,
  );
}
