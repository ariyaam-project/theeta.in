import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/reel.dart';
import 'package:app/services/instagram_link.dart';

void main() {
  group('parseInstagram', () {
    test('parses a plain reel url', () {
      final link = parseInstagram('https://www.instagram.com/reel/ABC123_x/');
      expect(link, isNotNull);
      expect(link!.shortcode, 'ABC123_x');
      expect(link.url, 'https://www.instagram.com/reel/ABC123_x/');
    });

    test('extracts the url from shared caption text', () {
      final link = parseInstagram(
        'Check this out https://instagram.com/reels/XyZ-99?igshid=1 amazing food',
      );
      expect(link, isNotNull);
      expect(link!.shortcode, 'XyZ-99');
    });

    test('handles /p/ and /tv/ links', () {
      expect(parseInstagram('https://www.instagram.com/p/AAA/')?.shortcode, 'AAA');
      expect(parseInstagram('https://www.instagram.com/tv/BBB/')?.shortcode, 'BBB');
    });

    test('returns null for non-instagram text', () {
      expect(parseInstagram('https://youtube.com/watch?v=1'), isNull);
      expect(parseInstagram('just some text'), isNull);
    });
  });

  group('Reel json', () {
    test('round-trips through json', () {
      final reel = Reel(
        id: 'ABC',
        url: 'https://www.instagram.com/reel/ABC/',
        addedAt: DateTime.parse('2026-06-06T10:00:00.000'),
        note: 'tasty',
      );
      final decoded = Reel.decodeList(Reel.encodeList([reel]));
      expect(decoded.length, 1);
      expect(decoded.first.id, 'ABC');
      expect(decoded.first.note, 'tasty');
      expect(decoded.first.addedAt, reel.addedAt);
    });
  });
}
