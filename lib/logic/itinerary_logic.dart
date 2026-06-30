import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/save_load_mixin.dart';
import 'package:wonders/logic/data/itinerary_data.dart';
import 'package:wonders/logic/data/trip_data.dart';
import 'package:wonders/logic/itinerary_service.dart';
import 'package:wonders/logic/sample_itinerary.dart';

/// Owns generated itineraries (build step E). Generation prefers Claude's
/// structured output via [ItineraryService] and falls back to the offline
/// [SampleItinerary] when no API key is configured or a call fails — so the
/// journal screen always has something to render.
///
/// Registered as a `get_it` singleton and persisted (by trip id) via
/// [ThrottledSaveLoadMixin].
class ItineraryLogic with ThrottledSaveLoadMixin {
  @override
  String get fileName => 'itineraries.dat';

  final _service = ItineraryService();

  /// Whether a real Claude key is wired in. The UI uses this to label the
  /// generate action ("Generate with AI" vs "Generate sample").
  bool get hasApiKey => _service.hasApiKey;

  /// Generated itineraries keyed by trip id. Views `watchX` this.
  late final ValueNotifier<Map<String, Itinerary>> byTripId = ValueNotifier<Map<String, Itinerary>>({});

  /// True while a generate / regenerate call is in flight.
  late final ValueNotifier<bool> isBusy = ValueNotifier<bool>(false);

  Itinerary? forTrip(String tripId) => byTripId.value[tripId];

  bool hasItinerary(String tripId) => byTripId.value.containsKey(tripId);

  /// Generate (or re-generate) the whole itinerary for [trip]. Tries Claude,
  /// falls back to the sample generator. Stores and returns the result.
  Future<Itinerary?> generate(Trip trip) async {
    isBusy.value = true;
    try {
      final places = tripsLogic.placesFor(trip);
      final now = DateTime.now().millisecondsSinceEpoch;
      final dayCount = SampleItinerary.dayCountFor(trip, places.length);
      final itinerary = await _service.generate(trip, places, dayCount: dayCount, nowMs: now) ??
          SampleItinerary.generate(trip, places, nowMs: now);
      _store(itinerary);
      return itinerary;
    } finally {
      isBusy.value = false;
    }
  }

  /// Re-roll a single day in place. Tries Claude, falls back to a local re-roll.
  Future<void> regenerateDay(Trip trip, int dayIndex) async {
    final existing = forTrip(trip.id);
    if (existing == null || dayIndex < 0 || dayIndex >= existing.days.length) return;
    isBusy.value = true;
    try {
      final places = tripsLogic.placesFor(trip);
      final current = existing.days[dayIndex];
      final newDay = await _service.regenerateDay(trip, current, places) ??
          SampleItinerary.reroll(current, seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff);
      _store(existing.withDay(dayIndex, newDay));
    } finally {
      isBusy.value = false;
    }
  }

  void removeForTrip(String tripId) {
    if (!byTripId.value.containsKey(tripId)) return;
    byTripId.value = Map.of(byTripId.value)..remove(tripId);
    scheduleSave();
  }

  void _store(Itinerary itinerary) {
    byTripId.value = Map.of(byTripId.value)..[itinerary.tripId] = itinerary;
    scheduleSave();
  }

  @override
  void copyFromJson(Map<String, dynamic> value) {
    final raw = value['items'];
    if (raw is! List) return;
    final map = <String, Itinerary>{};
    for (final m in raw.whereType<Map>()) {
      final it = Itinerary.fromJson(Map<String, dynamic>.from(m));
      map[it.tripId] = it;
    }
    byTripId.value = map;
  }

  @override
  Map<String, dynamic> toJson() => {
        'items': byTripId.value.values.map((i) => i.toJson()).toList(),
      };
}
