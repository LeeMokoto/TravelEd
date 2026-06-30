import 'package:flutter/foundation.dart';
import 'package:wonders/logic/data/place_data.dart';

/// A single activity in a day's plan. The model (Claude, or the offline sample
/// generator) fills the *content*; the journal screen owns the *presentation*.
/// [kind] drives the card's icon and accent, and [lat]/[lng] power "Open in
/// Maps".
@immutable
class Activity {
  const Activity({
    required this.time,
    required this.kind,
    required this.name,
    this.note = '',
    this.lat = 0,
    this.lng = 0,
  });

  /// 24h time label, eg. "09:30". Free-form so the model can leave it blank.
  final String time;
  final PlaceKind kind;
  final String name;
  final String note;
  final double lat;
  final double lng;

  bool get hasLocation => lat != 0 || lng != 0;

  Map<String, dynamic> toJson() => {
        'time': time,
        'kind': kind.name,
        'name': name,
        'note': note,
        'lat': lat,
        'lng': lng,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        time: (json['time'] ?? '') as String,
        kind: PlaceKind.fromName(json['kind'] as String?),
        name: (json['name'] ?? '') as String,
        note: (json['note'] ?? '') as String,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
      );
}

/// One day of the itinerary — a "chapter" in the journal.
@immutable
class ItineraryDay {
  const ItineraryDay({
    required this.day,
    required this.area,
    required this.activities,
  });

  /// 1-based day number.
  final int day;

  /// The area / theme of the day, eg. "Arashiyama & the West".
  final String area;
  final List<Activity> activities;

  ItineraryDay copyWith({int? day, String? area, List<Activity>? activities}) => ItineraryDay(
        day: day ?? this.day,
        area: area ?? this.area,
        activities: activities ?? this.activities,
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'area': area,
        'activities': activities.map((a) => a.toJson()).toList(),
      };

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        day: (json['day'] as num?)?.toInt() ?? 1,
        area: (json['area'] ?? '') as String,
        activities: (json['activities'] as List?)
                ?.whereType<Map>()
                .map((m) => Activity.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
      );
}

/// A generated itinerary for a trip: the structured data the journal screen
/// renders. Persisted by `ItineraryLogic`, keyed by [tripId].
@immutable
class Itinerary {
  const Itinerary({
    required this.tripId,
    required this.days,
    this.generatedAtMs = 0,
  });

  final String tripId;
  final List<ItineraryDay> days;

  /// Epoch millis the itinerary was generated.
  final int generatedAtMs;

  Itinerary copyWith({String? tripId, List<ItineraryDay>? days, int? generatedAtMs}) => Itinerary(
        tripId: tripId ?? this.tripId,
        days: days ?? this.days,
        generatedAtMs: generatedAtMs ?? this.generatedAtMs,
      );

  /// Replace a single day (used by "Regenerate day with AI").
  Itinerary withDay(int index, ItineraryDay day) {
    if (index < 0 || index >= days.length) return this;
    final next = List<ItineraryDay>.of(days);
    next[index] = day;
    return copyWith(days: next);
  }

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'generatedAtMs': generatedAtMs,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory Itinerary.fromJson(Map<String, dynamic> json) => Itinerary(
        tripId: json['tripId'] as String,
        generatedAtMs: (json['generatedAtMs'] as num?)?.toInt() ?? 0,
        days: (json['days'] as List?)
                ?.whereType<Map>()
                .map((m) => ItineraryDay.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
      );
}
