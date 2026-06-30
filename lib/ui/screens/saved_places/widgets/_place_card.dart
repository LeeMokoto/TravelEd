part of '../saved_places_screen.dart';

/// A single saved place, rendered as a parchment card in the inherited
/// Wonderous aesthetic: a terracotta kind-badge, place name, and country.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.onRemove});
  final Place place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: $styles.colors.offWhite,
        borderRadius: BorderRadius.circular($styles.corners.md),
      ),
      padding: EdgeInsets.all($styles.insets.sm),
      child: Row(
        children: [
          _KindBadge(kind: place.kind),
          Gap($styles.insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  style: $styles.text.title1.copyWith(color: $styles.colors.body),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (place.country.isNotEmpty)
                  Text(
                    place.country,
                    style: $styles.text.bodySmall.copyWith(color: $styles.colors.caption),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (place.note.isNotEmpty) ...[
                  Gap($styles.insets.xxs),
                  Text(
                    place.note,
                    style: $styles.text.caption.copyWith(color: $styles.colors.body),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          AppBtn.basic(
            onPressed: onRemove,
            semanticLabel: $strings.savedPlacesRemove(place.name),
            child: Padding(
              padding: EdgeInsets.all($styles.insets.xs),
              child: Icon(Icons.delete_outline, color: $styles.colors.caption),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});
  final PlaceKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: $styles.colors.accent1,
        borderRadius: BorderRadius.circular($styles.corners.sm),
      ),
      child: Icon(kind.icon, color: $styles.colors.white, size: 22),
    );
  }
}

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
