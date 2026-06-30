part of '../itinerary_screen.dart';

/// Horizontal rail of day "chapters". Tapping a pill switches the day shown
/// below.
class _DayRail extends StatelessWidget {
  const _DayRail({required this.dayCount, required this.selected, required this.onSelect});
  final int dayCount;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: $styles.colors.greyStrong,
      padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: $styles.insets.lg),
          itemCount: dayCount,
          separatorBuilder: (_, __) => Gap($styles.insets.xs),
          itemBuilder: (_, i) {
            final isSelected = i == selected;
            return AppBtn.basic(
              onPressed: () => onSelect(i),
              semanticLabel: $strings.itineraryDayLabel(i + 1),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: $styles.insets.md),
                decoration: BoxDecoration(
                  color: isSelected ? $styles.colors.accent1 : Colors.transparent,
                  borderRadius: BorderRadius.circular($styles.corners.lg),
                  border: Border.all(color: isSelected ? $styles.colors.accent1 : $styles.colors.greyMedium),
                ),
                child: Text(
                  $strings.itineraryDayLabel(i + 1).toUpperCase(),
                  style: $styles.text.quoteFont.copyWith(
                    fontSize: 13 * $styles.scale,
                    height: 1,
                    letterSpacing: 1,
                    color: isSelected ? $styles.colors.white : $styles.colors.accent2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
