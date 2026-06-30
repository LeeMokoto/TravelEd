part of '../trips_screen.dart';

/// A trip in the list: title, date range (or a prompt to add dates), and a
/// place count, on a parchment card.
class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});
  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dates = formatTripDates(trip);
    return AppBtn.basic(
      onPressed: onTap,
      semanticLabel: trip.title,
      child: Container(
        decoration: BoxDecoration(
          color: $styles.colors.offWhite,
          borderRadius: BorderRadius.circular($styles.corners.md),
        ),
        padding: EdgeInsets.all($styles.insets.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trip.title,
                    style: $styles.text.h4.copyWith(color: $styles.colors.body),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap($styles.insets.xxs),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: $styles.colors.caption),
                      Gap($styles.insets.xs),
                      Flexible(
                        child: Text(
                          dates.isEmpty ? $strings.tripsNoDates : dates,
                          style: $styles.text.bodySmall.copyWith(color: $styles.colors.caption),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Gap($styles.insets.xxs),
                  Text(
                    $strings.tripsPlaceCount(trip.placeIds.length),
                    style: $styles.text.caption.copyWith(color: $styles.colors.accent1),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: $styles.colors.caption),
          ],
        ),
      ),
    );
  }
}
