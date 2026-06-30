import 'package:url_launcher/url_launcher.dart';

/// Outbound deep-links — the "book handoff" (build step D). Booking is not done
/// in-app (Airbnb has no public API; Booking.com is partner-gated); instead we
/// deep-link out to a pre-filled search and let the user complete it on the
/// provider's site. Maps links open the device's map app.
class DeepLinks {
  /// Open a location in the maps app, by coordinates when available, otherwise
  /// by [label] as a search query.
  static Future<bool> openInMaps({double lat = 0, double lng = 0, String label = ''}) {
    final query = (lat != 0 || lng != 0) ? '$lat,$lng' : label;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    return _launch(uri);
  }

  /// Open a Booking.com search pre-filled with destination, dates, and guests.
  static Future<bool> bookOnBooking({
    required String destination,
    int? checkInMs,
    int? checkOutMs,
    int guests = 2,
  }) {
    final params = <String, String>{
      'ss': destination,
      'group_adults': '$guests',
    };
    final checkIn = _ymd(checkInMs);
    final checkOut = _ymd(checkOutMs);
    if (checkIn != null) params['checkin'] = checkIn;
    if (checkOut != null) params['checkout'] = checkOut;
    final uri = Uri.https('www.booking.com', '/searchresults.html', params);
    return _launch(uri);
  }

  static String? _ymd(int? ms) {
    if (ms == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
