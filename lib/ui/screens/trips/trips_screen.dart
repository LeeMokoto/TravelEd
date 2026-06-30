import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/trip_data.dart';
import 'package:wonders/logic/trips_logic.dart';
import 'package:wonders/ui/common/app_icons.dart';
import 'package:wonders/ui/common/controls/app_header.dart';
import 'package:wonders/ui/common/modals/app_modals.dart';
import 'package:wonders/ui/screens/trips/widgets/trip_editor_sheet.dart';
import 'package:wonders/ui/screens/trips/widgets/trip_format.dart';

part 'widgets/_trip_card.dart';

/// Lists the user's trips (build step B). Each trip groups saved places under a
/// destination and dates; opening one leads to its detail, where places are
/// managed and (step E) an itinerary is generated.
class TripsScreen extends StatelessWidget with GetItMixin {
  TripsScreen({super.key});

  Future<void> _handleNewPressed(BuildContext context) async {
    await showModal(context, child: const TripEditorSheet());
  }

  void _handleOpen(BuildContext context, Trip trip) => context.push(ScreenPaths.tripDetails(trip.id));

  @override
  Widget build(BuildContext context) {
    final trips = watchX((TripsLogic o) => o.trips);
    return ColoredBox(
      color: $styles.colors.greyStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: $strings.tripsTitle,
            isTransparent: true,
            trailing: (_) => AppBtn.basic(
              onPressed: () => _handleNewPressed(context),
              semanticLabel: $strings.tripsNew,
              child: Padding(
                padding: EdgeInsets.all($styles.insets.md),
                child: Icon(Icons.add, color: $styles.colors.offWhite),
              ),
            ),
          ),
          Expanded(
            child: trips.isEmpty
                ? _EmptyState(onNew: () => _handleNewPressed(context))
                : ListView.separated(
                    padding: EdgeInsets.all($styles.insets.lg),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => Gap($styles.insets.sm),
                    itemBuilder: (_, i) => _TripCard(
                      trip: trips[i],
                      onTap: () => _handleOpen(context, trips[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: $styles.colors.accent1, size: 64),
            Gap($styles.insets.md),
            Text(
              $strings.tripsEmptyTitle,
              textAlign: TextAlign.center,
              style: $styles.text.h3.copyWith(color: $styles.colors.offWhite),
            ),
            Gap($styles.insets.xs),
            Text(
              $strings.tripsEmptyBody,
              textAlign: TextAlign.center,
              style: $styles.text.body.copyWith(color: $styles.colors.accent2),
            ),
            Gap($styles.insets.lg),
            AppBtn.from(onPressed: onNew, text: $strings.tripsNew, icon: AppIcons.north),
          ],
        ),
      ),
    );
  }
}
