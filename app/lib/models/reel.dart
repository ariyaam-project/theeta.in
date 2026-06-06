import 'dart:convert';

/// A saved Instagram reel awaiting / holding analysis.
class Reel {
  /// Instagram shortcode — stable id used for dedupe.
  final String id;

  /// Canonical reel url.
  final String url;

  /// When the user shared/added it.
  final DateTime addedAt;

  /// Optional caption/message that came with the share.
  final String? note;

  Reel({
    required this.id,
    required this.url,
    required this.addedAt,
    this.note,
  });

  String get shortcode => id;

  String get timeAgo {
    final d = DateTime.now().difference(addedAt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'addedAt': addedAt.toIso8601String(),
        'note': note,
      };

  factory Reel.fromJson(Map<String, dynamic> j) => Reel(
        id: j['id'] as String,
        url: j['url'] as String,
        addedAt: DateTime.parse(j['addedAt'] as String),
        note: j['note'] as String?,
      );

  static String encodeList(List<Reel> reels) =>
      jsonEncode(reels.map((r) => r.toJson()).toList());

  static List<Reel> decodeList(String s) => (jsonDecode(s) as List)
      .map((e) => Reel.fromJson(e as Map<String, dynamic>))
      .toList();
}
