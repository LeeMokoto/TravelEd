import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/deep_links.dart';
import 'package:wonders/logic/data/itinerary_data.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/data/trip_data.dart';
import 'package:wonders/logic/itinerary_logic.dart';
import 'package:wonders/logic/trips_logic.dart';
import 'package:wonders/ui/common/compass_divider.dart';
import 'package:wonders/ui/common/controls/app_header.dart';
import 'package:wonders/ui/common/place_kind_ui.dart';
import 'package:wonders/ui/screens/trips/widgets/trip_format.dart';

part 'widgets/_itinerary_hero.dart';
part 'widgets/_day_rail.dart';
part 'widgets/_day_section.dart';
part 'widgets/_activity_card.dart';

/// The expedition-journal itinerary (build step E) — the centerpiece. Structured
/// itinerary data (from Claude, or the offline sample generator) is rendered as
/// a designed screen: a photo hero, a rail of day "chapters", and a timeline of
/// activity cards with embedded Maps / booking handoffs (step D).
class ItineraryScreen extends StatefulWidget with GetItStatefulWidgetMixin {
  ItineraryScreen({super.key, required this.tripId});
  final String tripId;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> with GetItStateMixin {
  int _selectedDay = 0;

  Future<void> _handleGenerate(Trip trip) async {
    await itineraryLogic.generate(trip);
    if (mounted) setState(() => _selectedDay = 0);
  }

  Future<void> _handleRegenerateDay(Trip trip) => itineraryLogic.regenerateDay(trip, _selectedDay);

  @override
  Widget build(BuildContext context) {
    final trip = watchX((TripsLogic o) => o.trips).firstWhereOrNull((t) => t.id == widget.tripId);
    final itineraries = watchX((ItineraryLogic o) => o.byTripId);
    final busy = watchX((ItineraryLogic o) => o.isBusy);

    if (trip == null) return _MissingTrip();

    final itinerary = itineraries[widget.tripId];

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: $styles.colors.greyStrong,
          child: itinerary == null ? _buildEmpty(context, trip, busy) : _buildJournal(context, trip, itinerary),
        ),
        if (busy) const _BusyOverlay(),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, Trip trip, bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeader(title: $strings.itineraryTitle, isTransparent: true),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: $styles.colors.accent1, size: 56),
                  Gap($styles.insets.md),
                  Text(
                    $strings.itineraryGenerateTitle,
                    textAlign: TextAlign.center,
                    style: $styles.text.h3.copyWith(color: $styles.colors.offWhite),
                  ),
                  Gap($styles.insets.xs),
                  Text(
                    itineraryLogic.hasApiKey ? $strings.itineraryGenerateBodyAi : $strings.itineraryGenerateBodySample,
                    textAlign: TextAlign.center,
                    style: $styles.text.body.copyWith(color: $styles.colors.accent2),
                  ),
                  Gap($styles.insets.lg),
                  AppBtn.from(
                    onPressed: busy ? null : () => _handleGenerate(trip),
                    text: $strings.itineraryGenerate,
                    isSecondary: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJournal(BuildContext context, Trip trip, Itinerary itinerary) {
    final days = itinerary.days;
    final selected = _selectedDay.clamp(0, days.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            _ItineraryHero(trip: trip),
            Positioned(top: 0, left: 0, right: 0, child: AppHeader(isTransparent: true)),
          ],
        ),
        _DayRail(
          dayCount: days.length,
          selected: selected,
          onSelect: (i) => setState(() => _selectedDay = i),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: $styles.insets.xl),
            child: _DaySection(
              day: days[selected],
              onRegenerate: () => _handleRegenerateDay(trip),
              tripDates: trip,
            ),
          ),
        ),
      ],
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: $styles.colors.black.withOpacity(.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: $styles.colors.accent1),
              Gap($styles.insets.md),
              Text($strings.itineraryGenerating, style: $styles.text.bodySmall.copyWith(color: $styles.colors.offWhite)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingTrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: $styles.colors.greyStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(title: $strings.itineraryTitle, isTransparent: true),
          Expanded(
            child: Center(
              child: Text(
                $strings.tripDetailMissing,
                style: $styles.text.body.copyWith(color: $styles.colors.accent2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
