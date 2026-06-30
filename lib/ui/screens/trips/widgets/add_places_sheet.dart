import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/places_logic.dart';
import 'package:wonders/logic/trips_logic.dart';
import 'package:wonders/ui/common/place_kind_ui.dart';

/// Bottom sheet that lists the user's saved places and toggles their membership
/// in a trip. Changes apply immediately via [TripsLogic]; the sheet just reads
/// live state so the checkmarks stay in sync.
class AddPlacesSheet extends StatelessWidget with GetItMixin {
  AddPlacesSheet({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    final places = watchX((PlacesLogic o) => o.saved);
    // Rebuild when the trip's place list changes.
    final trip = watchX((TripsLogic o) => o.trips).firstWhereOrNull((t) => t.id == tripId);
    if (trip == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all($styles.insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text($strings.tripDetailAddPlacesTitle, style: $styles.text.h3.copyWith(color: $styles.colors.offWhite)),
          Gap($styles.insets.md),
          if (places.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.lg),
              child: Text(
                $strings.tripDetailNoSavedPlaces,
                textAlign: TextAlign.center,
                style: $styles.text.body.copyWith(color: $styles.colors.accent2),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: context.heightPx * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: places.length,
                separatorBuilder: (_, __) => Gap($styles.insets.xs),
                itemBuilder: (_, i) {
                  final place = places[i];
                  final selected = trip.placeIds.contains(place.id);
                  return _SelectableRow(
                    place: place,
                    selected: selected,
                    onTap: () => tripsLogic.togglePlace(tripId, place.id),
                  );
                },
              ),
            ),
          Gap($styles.insets.md),
          AppBtn.from(
            text: $strings.tripDetailDone,
            expand: true,
            isSecondary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({required this.place, required this.selected, required this.onTap});
  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppBtn.basic(
      onPressed: onTap,
      semanticLabel: place.name,
      child: Container(
        padding: EdgeInsets.all($styles.insets.sm),
        decoration: BoxDecoration(
          color: selected ? $styles.colors.accent1.withOpacity(.15) : Colors.transparent,
          borderRadius: BorderRadius.circular($styles.corners.md),
          border: Border.all(color: selected ? $styles.colors.accent1 : $styles.colors.greyMedium),
        ),
        child: Row(
          children: [
            Icon(place.kind.icon, color: $styles.colors.accent1, size: 20),
            Gap($styles.insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(place.name,
                      style: $styles.text.bodySmallBold.copyWith(color: $styles.colors.offWhite),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (place.country.isNotEmpty)
                    Text(place.country,
                        style: $styles.text.caption.copyWith(color: $styles.colors.greyMedium),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.add_circle_outline,
              color: selected ? $styles.colors.accent1 : $styles.colors.greyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
