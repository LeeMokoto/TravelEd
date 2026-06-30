import 'package:flutter/foundation.dart';

/// The kind of a saved place. Deliberately mirrors the activity "kind" used by
/// the itinerary journal (sight / food / stay / transit) so a saved place can
/// flow straight into a trip and itinerary without remapping.
enum PlaceKind {
  sight,
  food,
  stay,
  transit;

  static PlaceKind fromName(String? name) => PlaceKind.values.asNameMap()[name] ?? PlaceKind.sight;
}

/// A user-saved place — the foundation of the travel features.
///
/// Unlike the base app's fixed [WonderType] enum, places are dynamic and
/// id-based so the saved list can grow at runtime (saved from the map, search,
/// or added by hand). Trips group these, and the itinerary is generated from
/// them.
@immutable
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.country,
    this.lat = 0,
    this.lng = 0,
    this.kind = PlaceKind.sight,
    this.note = '',
    this.imageUrl = '',
    this.savedAtMs = 0,
  });

  /// Stable, unique identifier. Generated when a place is first saved (see
  /// [PlacesLogic.addNew]); persisted so the same place keeps its id.
  final String id;
  final String name;
  final String country;

  /// Coordinates power the map and the "Open in Maps" deep-link. Default 0/0
  /// when a place is added without a precise location yet.
  final double lat;
  final double lng;

  final PlaceKind kind;
  final String note;
  final String imageUrl;

  /// Epoch millis the place was saved; used to order the saved list.
  final int savedAtMs;

  Place copyWith({
    String? id,
    String? name,
    String? country,
    double? lat,
    double? lng,
    PlaceKind? kind,
    String? note,
    String? imageUrl,
    int? savedAtMs,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      kind: kind ?? this.kind,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      savedAtMs: savedAtMs ?? this.savedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'lat': lat,
        'lng': lng,
        'kind': kind.name,
        'note': note,
        'imageUrl': imageUrl,
        'savedAtMs': savedAtMs,
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        country: (json['country'] ?? '') as String,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        kind: PlaceKind.fromName(json['kind'] as String?),
        note: (json['note'] ?? '') as String,
        imageUrl: (json['imageUrl'] ?? '') as String,
        savedAtMs: (json['savedAtMs'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) => other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Place($id, $name, $country)';
}
