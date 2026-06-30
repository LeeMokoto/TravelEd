import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/itinerary_data.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/data/trip_data.dart';

/// Builds an [Itinerary] from a trip's places and dates, with no network or API
/// key required. This keeps the journal screen fully demonstrable offline and
/// is the fallback whenever the Claude generation path is unavailable.
class SampleItinerary {
  /// Distribute the trip's [places] across its days (derived from the date
  /// range, or ~3 places/day when undated) and lay them out as a plan.
  static Itinerary generate(Trip trip, List<Place> places, {int nowMs = 0}) {
    final dayCount = dayCountFor(trip, places.length);
    final chunks = _chunk(places, dayCount);
    final days = <ItineraryDay>[];
    for (var i = 0; i < dayCount; i++) {
      days.add(_buildDay(trip, chunks[i], i + 1, seed: i));
    }
    return Itinerary(tripId: trip.id, days: days, generatedAtMs: nowMs);
  }

  /// Re-roll a single day: keep its activities but vary their order and times,
  /// so "Regenerate day" produces a visibly different plan offline.
  static ItineraryDay reroll(ItineraryDay day, {required int seed}) {
    final shuffled = List<Activity>.of(day.activities);
    _seededShuffle(shuffled, seed);
    final retimed = <Activity>[];
    for (var i = 0; i < shuffled.length; i++) {
      retimed.add(Activity(
        time: _timeFor(i, seed: seed),
        kind: shuffled[i].kind,
        name: shuffled[i].name,
        note: shuffled[i].note,
        lat: shuffled[i].lat,
        lng: shuffled[i].lng,
      ));
    }
    return day.copyWith(activities: retimed);
  }

  /// Number of days for a trip: its date span, or ~3 places/day when undated.
  /// Clamped to a sane 1–14. Shared with the AI path so both agree.
  static int dayCountFor(Trip trip, int placeCount) {
    int count;
    if (trip.hasDates) {
      final start = DateTime.fromMillisecondsSinceEpoch(trip.startDateMs!);
      final end = DateTime.fromMillisecondsSinceEpoch(trip.endDateMs!);
      count = end.difference(start).inDays + 1;
    } else {
      count = (placeCount / 3).ceil();
    }
    return count.clamp(1, 14);
  }

  /// Split [items] into [bins] groups, as evenly as possible, order preserved.
  static List<List<Place>> _chunk(List<Place> items, int bins) {
    final out = List.generate(bins, (_) => <Place>[]);
    for (var i = 0; i < items.length; i++) {
      out[i % bins].add(items[i]);
    }
    return out;
  }

  static ItineraryDay _buildDay(Trip trip, List<Place> places, int dayNumber, {required int seed}) {
    final activities = <Activity>[];
    if (places.isEmpty) {
      activities.add(Activity(
        time: _timeFor(0, seed: seed),
        kind: PlaceKind.sight,
        name: $strings.itinerarySampleExplore(trip.title),
        note: _noteFor(PlaceKind.sight),
      ));
    } else {
      for (var i = 0; i < places.length; i++) {
        final p = places[i];
        activities.add(Activity(
          time: _timeFor(i, seed: seed),
          kind: p.kind,
          name: p.name,
          note: p.note.isNotEmpty ? p.note : _noteFor(p.kind),
          lat: p.lat,
          lng: p.lng,
        ));
      }
    }
    final area = places.isNotEmpty
        ? (places.first.country.isNotEmpty ? places.first.country : places.first.name)
        : trip.title;
    return ItineraryDay(day: dayNumber, area: area, activities: activities);
  }

  /// Times stepping ~2h from a morning start; the seed nudges the start so a
  /// re-roll reads differently.
  static String _timeFor(int index, {int seed = 0}) {
    final startHour = 9 + (seed % 2); // 09:00 or 10:00
    final minutes = (startHour * 60) + index * 135; // 2h15m steps
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String _noteFor(PlaceKind kind) {
    switch (kind) {
      case PlaceKind.sight:
        return $strings.itinerarySampleNoteSight;
      case PlaceKind.food:
        return $strings.itinerarySampleNoteFood;
      case PlaceKind.stay:
        return $strings.itinerarySampleNoteStay;
      case PlaceKind.transit:
        return $strings.itinerarySampleNoteTransit;
    }
  }

  /// Deterministic in-place shuffle (Fisher–Yates with a small LCG) so a given
  /// seed always yields the same order.
  static void _seededShuffle(List<Activity> list, int seed) {
    var state = (seed * 2654435761 + 1) & 0x7fffffff;
    int next(int max) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return max <= 0 ? 0 : state % max;
    }

    for (var i = list.length - 1; i > 0; i--) {
      final j = next(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
