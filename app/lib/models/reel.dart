import 'dart:convert';

/// A saved Instagram reel awaiting / holding analysis.
class Reel {
  /// Canonical API reel id.
  final String id;

  /// Instagram shortcode — stable id used for dedupe.
  final String shortcode;

  /// Canonical reel url.
  final String url;

  final String status;
  final String? savedStatus;
  final String? caption;
  final RestaurantLocation? restaurant;
  final LocationExtraction? locationExtraction;

  /// When the user shared/added it.
  final DateTime addedAt;

  /// Optional caption/message that came with the share.
  final String? note;

  Reel({
    required this.id,
    required this.shortcode,
    required this.url,
    required this.status,
    required this.addedAt,
    this.savedStatus,
    this.caption,
    this.restaurant,
    this.locationExtraction,
    this.note,
  });

  bool get isProcessing =>
      status == 'pending' ||
      status == 'downloading' ||
      status == 'transcribing' ||
      status == 'detecting' ||
      status == 'resolving' ||
      status == 'analyzing_comments' ||
      status == 'summarizing' ||
      savedStatus == 'processing';

  String get timeAgo {
    final d = DateTime.now().difference(addedAt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  static String encodeList(List<Reel> reels) =>
      jsonEncode(reels.map((r) => r.toJson()).toList());

  static List<Reel> decodeList(String s) => (jsonDecode(s) as List)
      .map((e) => Reel.fromJson(e as Map<String, dynamic>))
      .toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'shortcode': shortcode,
    'url': url,
    'status': status,
    'savedStatus': savedStatus,
    'caption': caption,
    'restaurant': restaurant?.toJson(),
    'locationExtraction': locationExtraction?.toJson(),
    'addedAt': addedAt.toIso8601String(),
    'note': note,
  };

  factory Reel.fromJson(Map<String, dynamic> j) => Reel(
    id: j['id'] as String,
    shortcode: (j['shortcode'] ?? j['id']) as String,
    url: j['url'] as String,
    status: (j['status'] ?? 'saved') as String,
    savedStatus: j['savedStatus'] as String?,
    caption: j['caption'] as String?,
    restaurant: j['restaurant'] == null
        ? null
        : RestaurantLocation.fromJson(j['restaurant'] as Map<String, dynamic>),
    locationExtraction: j['locationExtraction'] == null
        ? null
        : LocationExtraction.fromJson(
            j['locationExtraction'] as Map<String, dynamic>,
          ),
    addedAt: DateTime.parse(j['addedAt'] as String),
    note: j['note'] as String?,
  );
}

class RestaurantLocation {
  final String? name;
  final String? address;
  final String? area;
  final String? city;
  final double? lat;
  final double? lng;
  final double? confidence;

  RestaurantLocation({
    this.name,
    this.address,
    this.area,
    this.city,
    this.lat,
    this.lng,
    this.confidence,
  });

  factory RestaurantLocation.fromJson(Map<String, dynamic> j) =>
      RestaurantLocation(
        name: j['name'] as String?,
        address: j['address'] as String?,
        area: j['area'] as String?,
        city: j['city'] as String?,
        lat: _numToDouble(j['lat']),
        lng: _numToDouble(j['lng']),
        confidence: _numToDouble(j['confidence']),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'area': area,
    'city': city,
    'lat': lat,
    'lng': lng,
    'confidence': confidence,
  };
}

class LocationExtraction {
  final String? restaurantName;
  final String? suggestedAddress;
  final double? suggestedLat;
  final double? suggestedLng;
  final double? suggestedLocationConfidence;
  final String? resolutionStatus;

  LocationExtraction({
    this.restaurantName,
    this.suggestedAddress,
    this.suggestedLat,
    this.suggestedLng,
    this.suggestedLocationConfidence,
    this.resolutionStatus,
  });

  factory LocationExtraction.fromJson(Map<String, dynamic> j) =>
      LocationExtraction(
        restaurantName: j['restaurantName'] as String?,
        suggestedAddress: j['suggestedAddress'] as String?,
        suggestedLat: _numToDouble(j['suggestedLat']),
        suggestedLng: _numToDouble(j['suggestedLng']),
        suggestedLocationConfidence: _numToDouble(
          j['suggestedLocationConfidence'],
        ),
        resolutionStatus: j['resolutionStatus'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'restaurantName': restaurantName,
    'suggestedAddress': suggestedAddress,
    'suggestedLat': suggestedLat,
    'suggestedLng': suggestedLng,
    'suggestedLocationConfidence': suggestedLocationConfidence,
    'resolutionStatus': resolutionStatus,
  };
}

double? _numToDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return null;
}
