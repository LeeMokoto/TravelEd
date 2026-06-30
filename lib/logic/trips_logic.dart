import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/save_load_mixin.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/data/trip_data.dart';

/// Owns the user's trips (build step B). A trip groups saved places under a
/// destination and dates. Registered as a `get_it` singleton in
/// [registerSingletons] and persisted to `SharedPreferences` via
/// [ThrottledSaveLoadMixin].
class TripsLogic with ThrottledSaveLoadMixin {
  @override
  String get fileName => 'trips.dat';

  /// All trips, ordered most-recently-created first. Views `watchX` this.
  late final ValueNotifier<List<Trip>> trips = ValueNotifier<List<Trip>>([]);

  List<Trip> get all => trips.value;

  bool get isEmpty => trips.value.isEmpty;

  Trip? fromId(String? id) => id == null ? null : trips.value.firstWhereOrNull((t) => t.id == id);

  /// Create and store a new trip, stamping a unique id and create-time. Returns
  /// the created [Trip].
  Trip create({required String title, int? startDateMs, int? endDateMs}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final trip = Trip(
      id: '$now-${title.hashCode.toRadixString(16)}',
      title: title,
      startDateMs: startDateMs,
      endDateMs: endDateMs,
      createdAtMs: now,
    );
    final list = List<Trip>.of(trips.value)..insert(0, trip);
    trips.value = list;
    scheduleSave();
    return trip;
  }

  /// Replace the stored trip that shares [trip]'s id. No-op if it isn't found.
  void update(Trip trip) {
    final list = List<Trip>.of(trips.value);
    final i = list.indexWhere((t) => t.id == trip.id);
    if (i == -1) return;
    list[i] = trip;
    trips.value = list;
    scheduleSave();
  }

  void removeById(String id) {
    if (fromId(id) == null) return;
    trips.value = List<Trip>.of(trips.value)..removeWhere((t) => t.id == id);
    itineraryLogic.removeForTrip(id); // drop any generated itinerary for this trip
    scheduleSave();
  }

  bool tripContains(String tripId, String placeId) => fromId(tripId)?.placeIds.contains(placeId) ?? false;

  void addPlace(String tripId, String placeId) {
    final trip = fromId(tripId);
    if (trip == null || trip.placeIds.contains(placeId)) return;
    update(trip.copyWith(placeIds: [...trip.placeIds, placeId]));
  }

  void removePlace(String tripId, String placeId) {
    final trip = fromId(tripId);
    if (trip == null || !trip.placeIds.contains(placeId)) return;
    update(trip.copyWith(placeIds: trip.placeIds.where((id) => id != placeId).toList()));
  }

  void togglePlace(String tripId, String placeId) =>
      tripContains(tripId, placeId) ? removePlace(tripId, placeId) : addPlace(tripId, placeId);

  /// Resolve a trip's place ids to live [Place]s via [PlacesLogic], preserving
  /// the trip's order and silently dropping any that are no longer saved.
  List<Place> placesFor(Trip trip) =>
      trip.placeIds.map((id) => placesLogic.fromId(id)).whereType<Place>().toList();

  @override
  void copyFromJson(Map<String, dynamic> value) {
    final raw = value['trips'];
    if (raw is! List) return;
    final list = raw
        .whereType<Map>()
        .map((m) => Trip.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    trips.value = list;
  }

  @override
  Map<String, dynamic> toJson() => {
        'trips': trips.value.map((t) => t.toJson()).toList(),
      };
}
