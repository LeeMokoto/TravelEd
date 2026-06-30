import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/save_load_mixin.dart';
import 'package:wonders/logic/data/place_data.dart';

/// Owns the user's saved places — the foundation that Trips and the AI
/// itinerary build on. Registered as a `get_it` singleton in [registerSingletons]
/// and persisted as JSON to `SharedPreferences` via [ThrottledSaveLoadMixin].
class PlacesLogic with ThrottledSaveLoadMixin {
  @override
  String get fileName => 'places.dat';

  /// All saved places, ordered most-recently-saved first. Reactive: views
  /// `watchX` this to rebuild when the list changes.
  late final ValueNotifier<List<Place>> saved = ValueNotifier<List<Place>>([]);

  List<Place> get all => saved.value;

  bool get isEmpty => saved.value.isEmpty;

  bool isSaved(String id) => saved.value.any((p) => p.id == id);

  Place? fromId(String? id) => id == null ? null : saved.value.firstWhereOrNull((p) => p.id == id);

  /// Save [place], placing it at the top of the list. If a place with the same
  /// id already exists it is replaced (so this doubles as an update).
  void add(Place place) {
    final list = List<Place>.of(saved.value)..removeWhere((p) => p.id == place.id);
    list.insert(0, place);
    saved.value = list;
    scheduleSave();
  }

  /// Build and save a new place, stamping a unique id and save-time. Returns the
  /// created [Place] so callers can reference it (eg. to add it to a trip).
  Place addNew({
    required String name,
    required String country,
    double lat = 0,
    double lng = 0,
    PlaceKind kind = PlaceKind.sight,
    String note = '',
    String imageUrl = '',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final place = Place(
      id: '$now-${name.hashCode.toRadixString(16)}',
      name: name,
      country: country,
      lat: lat,
      lng: lng,
      kind: kind,
      note: note,
      imageUrl: imageUrl,
      savedAtMs: now,
    );
    add(place);
    return place;
  }

  void removeById(String id) {
    if (!isSaved(id)) return;
    saved.value = List<Place>.of(saved.value)..removeWhere((p) => p.id == id);
    scheduleSave();
  }

  /// Add the place if it isn't saved, remove it if it is.
  void toggle(Place place) => isSaved(place.id) ? removeById(place.id) : add(place);

  void clear() {
    if (isEmpty) return;
    saved.value = [];
    scheduleSave();
  }

  @override
  void copyFromJson(Map<String, dynamic> value) {
    final raw = value['places'];
    if (raw is! List) return;
    final list = raw
        .whereType<Map>()
        .map((m) => Place.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.savedAtMs.compareTo(a.savedAtMs));
    saved.value = list;
  }

  @override
  Map<String, dynamic> toJson() => {
        'places': saved.value.map((p) => p.toJson()).toList(),
      };
}
