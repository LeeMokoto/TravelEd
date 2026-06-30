import 'package:wonders/logic/data/place_data.dart';

/// Builds a Metropolitan Museum of Art `/search` query (url-encoded param
/// string) for a saved [Place].
///
/// The MET `geoLocation` filter is country/region level, so a place resolves to
/// its country's art and culture (eg. a place in Japan -> Japanese artifacts),
/// not city-specific objects. We pass the country as both the `geoLocation`
/// filter and the free-text `q` (MET requires a non-empty `q`), falling back to
/// the place name when no country is set.
class MetQuery {
  static String buildPlaceQuery(Place place) {
    final country = place.country.trim();
    final term = country.isNotEmpty ? country : place.name.trim();
    if (term.isEmpty) return 'q=*';
    final params = <String, String>{
      if (country.isNotEmpty) 'geoLocation': country,
      'q': term,
    };
    return params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
  }
}
