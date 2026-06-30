import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/ui/common/place_kind_ui.dart';

/// A place rendered as a parchment card in the inherited Wonderous aesthetic:
/// a terracotta kind-badge, name, country, and optional note. Shared by Saved
/// Places and Trips (and, later, the itinerary). Pass [trailing] for a
/// per-context action (remove, add, etc.) and [onTap] to make it tappable.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, this.onTap, this.trailing});
  final Place place;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: $styles.colors.offWhite,
        borderRadius: BorderRadius.circular($styles.corners.md),
      ),
      padding: EdgeInsets.all($styles.insets.sm),
      child: Row(
        children: [
          _Leading(place: place),
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
          if (trailing != null) ...[Gap($styles.insets.xs), trailing!],
        ],
      ),
    );

    if (onTap == null) return content;
    return AppBtn.basic(
      onPressed: onTap,
      semanticLabel: place.name,
      child: content,
    );
  }
}

/// The card's leading visual: the place's photo when it has one, otherwise a
/// terracotta kind-badge. Both are the same 44pt rounded square.
class _Leading extends StatelessWidget {
  const _Leading({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    if (place.imageUrl.isEmpty) return _KindBadge(kind: place.kind);
    return ClipRRect(
      borderRadius: BorderRadius.circular($styles.corners.sm),
      child: Image.network(
        place.imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _KindBadge(kind: place.kind),
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
