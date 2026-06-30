part of '../itinerary_screen.dart';

/// A day "chapter": a serif day title + area subtitle + compass divider, then
/// the day's timeline of activity cards and a per-day regenerate action.
class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.onRegenerate, required this.tripDates});
  final ItineraryDay day;
  final VoidCallback onRegenerate;
  final Trip tripDates;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all($styles.insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            $strings.itineraryDayLabel(day.day),
            textAlign: TextAlign.center,
            style: $styles.text.wonderTitleFont.copyWith(
              fontSize: 30 * $styles.scale,
              height: 1,
              color: $styles.colors.offWhite,
            ),
          ),
          if (day.area.isNotEmpty) ...[
            Gap($styles.insets.xs),
            Text(
              day.area.toUpperCase(),
              textAlign: TextAlign.center,
              style: $styles.text.title2.copyWith(color: $styles.colors.accent2, letterSpacing: 1),
            ),
          ],
          Gap($styles.insets.md),
          CompassDivider(isExpanded: true),
          Gap($styles.insets.lg),
          if (day.activities.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.lg),
              child: Text(
                $strings.itineraryDayEmpty,
                textAlign: TextAlign.center,
                style: $styles.text.body.copyWith(color: $styles.colors.accent2),
              ),
            )
          else
            ...List.generate(
              day.activities.length,
              (i) => _ActivityCard(
                activity: day.activities[i],
                trip: tripDates,
                isLast: i == day.activities.length - 1,
              ),
            ),
          Gap($styles.insets.md),
          Center(
            child: AppBtn.from(
              onPressed: onRegenerate,
              text: $strings.itineraryRegenerateDay,
            ),
          ),
        ],
      ),
    );
  }
}
