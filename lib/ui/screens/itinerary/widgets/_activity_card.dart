part of '../itinerary_screen.dart';

/// A timeline activity: a B612Mono time label on a left rail, a node dot and
/// connecting line, and a parchment content card. Tapping expands the card to
/// show its note and the Maps / booking actions (step D).
class _ActivityCard extends StatefulWidget {
  const _ActivityCard({required this.activity, required this.trip, required this.isLast});
  final Activity activity;
  final Trip trip;
  final bool isLast;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                a.time,
                textAlign: TextAlign.right,
                style: $styles.text.monoTitleFont.copyWith(fontSize: 12 * $styles.scale, color: $styles.colors.accent2),
              ),
            ),
          ),
          Gap($styles.insets.xs),
          _Rail(isLast: widget.isLast),
          Gap($styles.insets.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: $styles.insets.sm),
              child: _buildCard(a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Activity a) {
    return AppBtn.basic(
      onPressed: () => setState(() => _expanded = !_expanded),
      semanticLabel: a.name,
      child: Container(
        decoration: BoxDecoration(
          color: $styles.colors.offWhite,
          borderRadius: BorderRadius.circular($styles.corners.md),
        ),
        padding: EdgeInsets.all($styles.insets.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(a.kind.icon, color: $styles.colors.accent1, size: 18),
                Gap($styles.insets.xs),
                Expanded(
                  child: Text(
                    a.name,
                    style: $styles.text.title1.copyWith(color: $styles.colors.body),
                    maxLines: _expanded ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: $styles.colors.caption),
              ],
            ),
            if (_expanded) ...[
              if (a.note.isNotEmpty) ...[
                Gap($styles.insets.xs),
                Text(a.note, style: $styles.text.caption.copyWith(color: $styles.colors.body)),
              ],
              Gap($styles.insets.sm),
              _buildActions(a),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Activity a) {
    final chips = <Widget>[
      _ActionChip(
        icon: Icons.map_outlined,
        label: $strings.itineraryOpenInMaps,
        onTap: () => DeepLinks.openInMaps(lat: a.lat, lng: a.lng, label: a.name),
      ),
      if (a.kind == PlaceKind.stay)
        _ActionChip(
          icon: Icons.hotel_outlined,
          label: $strings.itineraryBook,
          accent: true,
          onTap: () => DeepLinks.bookOnBooking(
            destination: a.name.isNotEmpty ? a.name : widget.trip.title,
            checkInMs: widget.trip.startDateMs,
            checkOutMs: widget.trip.endDateMs,
          ),
        ),
    ];
    return Wrap(spacing: $styles.insets.xs, runSpacing: $styles.insets.xs, children: chips);
  }
}

/// The vertical timeline rail: a node dot for this activity and a line down to
/// the next (omitted for the last card).
class _Rail extends StatelessWidget {
  const _Rail({required this.isLast});
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          const Gap(3),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: $styles.colors.accent1, shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : $styles.colors.accent2.withOpacity(.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap, this.accent = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final fg = accent ? $styles.colors.white : $styles.colors.accent1;
    return AppBtn.basic(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: $styles.insets.sm, vertical: $styles.insets.xs),
        decoration: BoxDecoration(
          color: accent ? $styles.colors.accent1 : Colors.transparent,
          borderRadius: BorderRadius.circular($styles.corners.md),
          border: Border.all(color: $styles.colors.accent1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            Gap($styles.insets.xs),
            Text(label, style: $styles.text.bodySmall.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
