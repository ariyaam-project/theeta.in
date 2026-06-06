/// A parsed Instagram reel link.
class InstagramLink {
  final String url; // canonical https://www.instagram.com/reel/<code>/
  final String shortcode;

  const InstagramLink(this.url, this.shortcode);
}

// Matches reel / reels / p / tv links, with or without www, query, trailing slash.
final RegExp _igRegex = RegExp(
  r'https?://(?:www\.)?instagram\.com/(?:reel|reels|p|tv)/([A-Za-z0-9_-]+)',
  caseSensitive: false,
);

/// Extract the first Instagram reel link from arbitrary shared text.
/// Returns null if no Instagram link is present.
InstagramLink? parseInstagram(String text) {
  final match = _igRegex.firstMatch(text);
  if (match == null) return null;
  final code = match.group(1)!;
  return InstagramLink('https://www.instagram.com/reel/$code/', code);
}
