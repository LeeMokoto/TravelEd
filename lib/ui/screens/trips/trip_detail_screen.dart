import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/trip_data.dart';
import 'package:wonders/logic/places_logic.dart';
import 'package:wonders/logic/trips_logic.dart';
import 'package:wonders/ui/common/controls/app_header.dart';
import 'package:wonders/ui/common/controls/place_card.dart';
import 'package:wonders/ui/common/modals/app_modals.dart';
import 'package:wonders/ui/screens/trips/widgets/add_places_sheet.dart';
import 'package:wonders/ui/screens/trips/widgets/trip_editor_sheet.dart';
import 'package:wonders/ui/screens/trips/widgets/trip_format.dart';

/// A single trip: its dates, the places grouped into it, and actions to edit
/// the trip, add/remove places, or delete it.
class TripDetailScreen extends StatelessWidget with GetItMixin {
  TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  Future<void> _handleEdit(BuildContext context, Trip trip) async {
    await showModal(context, child: TripEditorSheet(existing: trip));
  }

  Future<void> _handleDelete(BuildContext context, Trip trip) async {
    final result = await showModal(context, child: OkCancelModal(msg: $strings.tripDetailDeleteConfirm(trip.title)));
    if (result == true) {
      tripsLogic.removeById(trip.id);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _handleAddPlaces(BuildContext context) async {
    await showModal(context, child: AddPlacesSheet(tripId: tripId));
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild on trip changes (dates, place membership) and on place changes.
    final trip = watchX((TripsLogic o) => o.trips).firstWhereOrNull((t) => t.id == tripId);
    watchX((PlacesLogic o) => o.saved);

    if (trip == null) {
      // The trip was deleted (eg. from elsewhere) — fall back to the list.
      return _MissingTrip();
    }

    final places = tripsLogic.placesFor(trip);
    final dates = formatTripDates(trip);

    return ColoredBox(
      color: $styles.colors.greyStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: trip.title,
            isTransparent: true,
            trailing: (_) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBtn.basic(
                  onPressed: () => _handleEdit(context, trip),
                  semanticLabel: $strings.tripDetailEdit,
                  child: Icon(Icons.edit_outlined, color: $styles.colors.offWhite, size: 20),
                ),
                Gap($styles.insets.sm),
                AppBtn.basic(
                  onPressed: () => _handleDelete(context, trip),
                  semanticLabel: $strings.tripDetailDelete,
                  child: Icon(Icons.delete_outline, color: $styles.colors.offWhite, size: 20),
                ),
                Gap($styles.insets.xs),
              ],
            ),
          ),
          _SummaryBar(dates: dates, placeCount: places.length),
          Expanded(
            child: places.isEmpty
                ? _EmptyPlaces(onAdd: () => _handleAddPlaces(context))
                : ListView.separated(
                    padding: EdgeInsets.all($styles.insets.lg),
                    itemCount: places.length,
                    separatorBuilder: (_, __) => Gap($styles.insets.sm),
                    itemBuilder: (_, i) => PlaceCard(
                      place: places[i],
                      trailing: AppBtn.basic(
                        onPressed: () => tripsLogic.removePlace(tripId, places[i].id),
                        semanticLabel: $strings.tripDetailRemovePlace(places[i].name),
                        child: Padding(
                          padding: EdgeInsets.all($styles.insets.xs),
                          child: Icon(Icons.remove_circle_outline, color: $styles.colors.caption),
                        ),
                      ),
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: AppBtn.from(
                onPressed: () => _handleAddPlaces(context),
                text: $strings.tripDetailAddPlaces,
                expand: true,
                isSecondary: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.dates, required this.placeCount});
  final String dates;
  final int placeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: $styles.insets.lg, vertical: $styles.insets.sm),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: $styles.colors.accent2),
          Gap($styles.insets.xs),
          Text(
            dates.isEmpty ? $strings.tripsNoDates : dates,
            style: $styles.text.bodySmall.copyWith(color: $styles.colors.accent2),
          ),
          Gap($styles.insets.md),
          Text(
            $strings.tripsPlaceCount(placeCount),
            style: $styles.text.bodySmall.copyWith(color: $styles.colors.accent1),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  const _EmptyPlaces({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_outlined, color: $styles.colors.accent1, size: 56),
            Gap($styles.insets.md),
            Text(
              $strings.tripDetailEmptyTitle,
              textAlign: TextAlign.center,
              style: $styles.text.h4.copyWith(color: $styles.colors.offWhite),
            ),
            Gap($styles.insets.xs),
            Text(
              $strings.tripDetailEmptyBody,
              textAlign: TextAlign.center,
              style: $styles.text.bodySmall.copyWith(color: $styles.colors.accent2),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingTrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: $styles.colors.greyStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(title: $strings.tripsTitle, isTransparent: true),
          Expanded(
            child: Center(
              child: Text(
                $strings.tripDetailMissing,
                style: $styles.text.body.copyWith(color: $styles.colors.accent2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
