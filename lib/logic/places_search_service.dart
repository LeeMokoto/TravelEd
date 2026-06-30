import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// A place returned by search — enough to drop a pin and save a [Place].
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.lat,
    required this.lng,
    this.country = '',
    this.address = '',
  });

  final String name;
  final double lat;
  final double lng;
  final String country;
  final String address;
}

/// Place/POI search for map discovery (build step C), via the Google Places
/// Text Search API.
///
/// The key is provided at build time:
///   flutter run --dart-define=GOOGLE_PLACES_API_KEY=...
/// When absent (or a call fails) [search] returns an empty list — the map's
/// tap-to-pin flow still works without it.
class PlacesSearchService {
  static const String _key = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  static const Duration _timeout = Duration(seconds: 20);

  bool get hasApiKey => _key.isNotEmpty;

  Future<List<PlaceSuggestion>> search(String query) async {
    final q = query.trim();
    if (!hasApiKey || q.isEmpty) return const [];
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/textsearch/json', {
      'query': q,
      'key': _key,
    });
    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        dev.log('Places search failed (${res.statusCode})');
        return const [];
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final results = decoded['results'];
      if (results is! List) return const [];
      return results.whereType<Map>().map(_parse).whereType<PlaceSuggestion>().toList();
    } catch (e) {
      dev.log('Places search error: $e');
      return const [];
    }
  }

  PlaceSuggestion? _parse(Map result) {
    final loc = (result['geometry'] as Map?)?['location'] as Map?;
    final lat = (loc?['lat'] as num?)?.toDouble();
    final lng = (loc?['lng'] as num?)?.toDouble();
    final name = (result['name'] ?? '') as String;
    if (lat == null || lng == null || name.isEmpty) return null;
    final address = (result['formatted_address'] ?? '') as String;
    return PlaceSuggestion(
      name: name,
      lat: lat,
      lng: lng,
      address: address,
      country: _countryFrom(address),
    );
  }

  /// Best-effort country from a formatted address (its last comma-separated part).
  static String _countryFrom(String address) {
    if (address.isEmpty) return '';
    final parts = address.split(',');
    return parts.last.trim();
  }
}
