import 'package:flutter/foundation.dart';

/// A trip groups saved places under a destination and a date range. It is the
/// middle layer of the travel features: built on saved [Place]s (step A) and
/// the input the AI itinerary (step E) is generated from.
///
/// Places are referenced by id rather than embedded, so a trip always reflects
/// the current saved place (and silently drops any that were removed).
@immutable
class Trip {
  const Trip({
    required this.id,
    required this.title,
    this.startDateMs,
    this.endDateMs,
    this.placeIds = const [],
    this.coverImageUrl = '',
    this.createdAtMs = 0,
  });

  /// Stable, unique identifier, stamped when the trip is created.
  final String id;

  /// Trip name / destination, eg. "Kyoto, Spring". Shown in lists and as the
  /// itinerary hero title.
  final String title;

  /// Epoch millis for the trip's first/last day. Null until the user sets dates
  /// — a trip can exist before it's scheduled.
  final int? startDateMs;
  final int? endDateMs;

  /// Ordered ids referencing saved [Place]s. Resolve via [TripsLogic.placesFor].
  final List<String> placeIds;

  final String coverImageUrl;

  /// Epoch millis the trip was created; used to order the trip list.
  final int createdAtMs;

  bool get hasDates => startDateMs != null && endDateMs != null;

  Trip copyWith({
    String? id,
    String? title,
    int? startDateMs,
    int? endDateMs,
    List<String>? placeIds,
    String? coverImageUrl,
    int? createdAtMs,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      startDateMs: startDateMs ?? this.startDateMs,
      endDateMs: endDateMs ?? this.endDateMs,
      placeIds: placeIds ?? this.placeIds,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  /// [copyWith] can't set dates back to null (a null arg means "unchanged").
  /// Use this to explicitly clear the date range.
  Trip withClearedDates() => Trip(
        id: id,
        title: title,
        startDateMs: null,
        endDateMs: null,
        placeIds: placeIds,
        coverImageUrl: coverImageUrl,
        createdAtMs: createdAtMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startDateMs': startDateMs,
        'endDateMs': endDateMs,
        'placeIds': placeIds,
        'coverImageUrl': coverImageUrl,
        'createdAtMs': createdAtMs,
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        title: (json['title'] ?? '') as String,
        startDateMs: (json['startDateMs'] as num?)?.toInt(),
        endDateMs: (json['endDateMs'] as num?)?.toInt(),
        placeIds: (json['placeIds'] as List?)?.whereType<String>().toList() ?? const [],
        coverImageUrl: (json['coverImageUrl'] ?? '') as String,
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) => other is Trip && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Trip($id, $title, ${placeIds.length} places)';
}
