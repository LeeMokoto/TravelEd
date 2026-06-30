import 'package:intl/intl.dart';
import 'package:wonders/logic/data/trip_data.dart';

/// A localized date-range label for a trip, eg. "Mar 3 – Mar 10, 2026".
/// Returns an empty string when the trip has no dates set.
String formatTripDates(Trip trip) {
  if (!trip.hasDates) return '';
  final start = DateTime.fromMillisecondsSinceEpoch(trip.startDateMs!);
  final end = DateTime.fromMillisecondsSinceEpoch(trip.endDateMs!);
  return '${DateFormat.MMMd().format(start)} – ${DateFormat.yMMMd().format(end)}';
}
