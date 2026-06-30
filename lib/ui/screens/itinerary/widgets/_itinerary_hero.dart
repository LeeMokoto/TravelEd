part of '../itinerary_screen.dart';

/// Full-bleed photo header with a dark scrim and a serif (Yeseva) destination
/// title — the inherited Wonderous hero motif.
class _ItineraryHero extends StatelessWidget {
  const _ItineraryHero({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final dates = formatTripDates(trip);
    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, $styles.colors.black.withOpacity(.85)],
                stops: const [0.35, 1],
              ),
            ),
          ),
          Positioned(
            left: $styles.insets.lg,
            right: $styles.insets.lg,
            bottom: $styles.insets.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dates.isNotEmpty)
                  Text(
                    dates.toUpperCase(),
                    style: $styles.text.title2.copyWith(color: $styles.colors.accent2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Gap($styles.insets.xxs),
                Text(
                  trip.title,
                  style: $styles.text.wonderTitleFont.copyWith(
                    fontSize: 40 * $styles.scale,
                    height: 1,
                    color: $styles.colors.offWhite,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (trip.coverImageUrl.isNotEmpty) {
      return Image.network(
        trip.coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradient(),
      );
    }
    return _gradient();
  }

  Widget _gradient() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [$styles.colors.greyStrong, $styles.colors.black],
          ),
        ),
      );
}
