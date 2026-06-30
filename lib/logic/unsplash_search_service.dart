import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// Finds a representative photo for an arbitrary place by name, via the Unsplash
/// Search API. This is what lets *any* place (Mount Fuji, a ramen shop, ...) get
/// a hero/thumbnail image — the curated landmark assets only cover the fixed
/// wonders.
///
/// The access key is provided at build time:
///   flutter run --dart-define=UNSPLASH_ACCESS_KEY=...
/// Without it (or on any failure) [findPhotoUrl] returns null and the UI keeps
/// its gradient / kind-badge fallback.
class UnsplashSearchService {
  static const String _key = String.fromEnvironment('UNSPLASH_ACCESS_KEY');
  static const Duration _timeout = Duration(seconds: 20);

  bool get hasApiKey => _key.isNotEmpty;

  /// Return a landscape photo URL for [query], or null if no key / no match /
  /// error.
  Future<String?> findPhotoUrl(String query) async {
    final q = query.trim();
    if (!hasApiKey || q.isEmpty) return null;
    final uri = Uri.https('api.unsplash.com', '/search/photos', {
      'query': q,
      'per_page': '1',
      'orientation': 'landscape',
      'content_filter': 'high',
    });
    try {
      final res = await http.get(uri, headers: {
        'Authorization': 'Client-ID $_key',
        'Accept-Version': 'v1',
      }).timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        dev.log('Unsplash search failed (${res.statusCode})');
        return null;
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final results = decoded['results'];
      if (results is! List || results.isEmpty) return null;
      final urls = (results.first as Map)['urls'] as Map?;
      final url = urls?['regular'] ?? urls?['small'] ?? urls?['full'];
      return url is String ? url : null;
    } catch (e) {
      dev.log('Unsplash search error: $e');
      return null;
    }
  }
}
