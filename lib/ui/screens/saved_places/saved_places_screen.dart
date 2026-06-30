import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/places_logic.dart';
import 'package:wonders/ui/common/app_icons.dart';
import 'package:wonders/ui/common/controls/app_header.dart';
import 'package:wonders/ui/common/controls/place_card.dart';
import 'package:wonders/ui/common/modals/app_modals.dart';
import 'package:wonders/ui/common/place_kind_ui.dart';

part 'widgets/_add_place_sheet.dart';

/// Lists the user's saved places. The foundation feature (build step A): a
/// place can be saved, viewed, and removed here, with everything persisted by
/// [PlacesLogic]. Trips (step B) and the AI itinerary (step E) build on this.
class SavedPlacesScreen extends StatelessWidget with GetItMixin {
  SavedPlacesScreen({super.key});

  Future<void> _handleAddPressed(BuildContext context) async {
    // The sheet saves the new place itself via [PlacesLogic.addNew].
    await showModal(context, child: const _AddPlaceSheet());
  }

  Future<void> _handleRemovePressed(BuildContext context, Place place) async {
    final result = await showModal(
      context,
      child: OkCancelModal(msg: $strings.savedPlacesRemoveConfirm(place.name)),
    );
    if (result == true) placesLogic.removeById(place.id);
  }

  @override
  Widget build(BuildContext context) {
    final places = watchX((PlacesLogic o) => o.saved);
    return ColoredBox(
      color: $styles.colors.greyStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: $strings.savedPlacesTitle,
            isTransparent: true,
            trailing: (_) => AppBtn.basic(
              onPressed: () => _handleAddPressed(context),
              semanticLabel: $strings.savedPlacesAdd,
              child: Padding(
                padding: EdgeInsets.all($styles.insets.md),
                child: Icon(Icons.add, color: $styles.colors.offWhite),
              ),
            ),
          ),
          Expanded(
            child: places.isEmpty
                ? _EmptyState(onAdd: () => _handleAddPressed(context))
                : ListView.separated(
                    padding: EdgeInsets.all($styles.insets.lg),
                    itemCount: places.length,
                    separatorBuilder: (_, __) => Gap($styles.insets.sm),
                    itemBuilder: (_, i) => PlaceCard(
                      place: places[i],
                      trailing: AppBtn.basic(
                        onPressed: () => _handleRemovePressed(context, places[i]),
                        semanticLabel: $strings.savedPlacesRemove(places[i].name),
                        child: Padding(
                          padding: EdgeInsets.all($styles.insets.xs),
                          child: Icon(Icons.delete_outline, color: $styles.colors.caption),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore, color: $styles.colors.accent1, size: 64),
            Gap($styles.insets.md),
            Text(
              $strings.savedPlacesEmptyTitle,
              textAlign: TextAlign.center,
              style: $styles.text.h3.copyWith(color: $styles.colors.offWhite),
            ),
            Gap($styles.insets.xs),
            Text(
              $strings.savedPlacesEmptyBody,
              textAlign: TextAlign.center,
              style: $styles.text.body.copyWith(color: $styles.colors.accent2),
            ),
            Gap($styles.insets.lg),
            AppBtn.from(
              onPressed: onAdd,
              text: $strings.savedPlacesAdd,
              icon: AppIcons.collection,
            ),
          ],
        ),
      ),
    );
  }
}
