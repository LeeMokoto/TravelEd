import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/place_data.dart';

/// View-layer mapping for [PlaceKind]: the icon and localized label that the
/// kind drives across the travel features (saved places, trips, itinerary).
extension PlaceKindUi on PlaceKind {
  IconData get icon {
    switch (this) {
      case PlaceKind.sight:
        return Icons.photo_camera_outlined;
      case PlaceKind.food:
        return Icons.restaurant;
      case PlaceKind.stay:
        return Icons.hotel_outlined;
      case PlaceKind.transit:
        return Icons.directions_transit_outlined;
    }
  }

  String get label {
    switch (this) {
      case PlaceKind.sight:
        return $strings.savedPlacesKindSight;
      case PlaceKind.food:
        return $strings.savedPlacesKindFood;
      case PlaceKind.stay:
        return $strings.savedPlacesKindStay;
      case PlaceKind.transit:
        return $strings.savedPlacesKindTransit;
    }
  }
}
