import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/places_logic.dart';
import 'package:wonders/logic/places_search_service.dart';
import 'package:wonders/ui/common/modals/app_modals.dart';
import 'package:wonders/ui/common/place_kind_ui.dart';

part 'widgets/_save_pin_sheet.dart';

/// Map discovery (build step C): browse a map, search for places, and pin the
/// ones worth visiting — each saved as a [Place] via [PlacesLogic], the same
/// foundation Trips and the itinerary build on.
///
/// The map uses the app's existing Google Maps SDK key. Text search uses the
/// Google Places API behind GOOGLE_PLACES_API_KEY (--dart-define); without it,
/// tapping the map to drop a pin still works.
class MapDiscoveryScreen extends StatefulWidget with GetItStatefulWidgetMixin {
  MapDiscoveryScreen({super.key});

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen> with GetItStateMixin {
  final _search = PlacesSearchService();
  final _searchController = TextEditingController();

  GoogleMapController? _controller;
  LatLng? _pending;
  List<PlaceSuggestion> _results = const [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  CameraPosition _initialCamera(List<Place> places) {
    final located = places.firstWhereOrNull((p) => p.lat != 0 || p.lng != 0);
    if (located != null) return CameraPosition(target: LatLng(located.lat, located.lng), zoom: 11);
    return const CameraPosition(target: LatLng(20, 0), zoom: 2);
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    final results = await _search.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _pending = LatLng(s.lat, s.lng);
      _results = const [];
    });
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(_pending!, 14));
    if (mounted) _openSaveSheet(name: s.name, country: s.country);
  }

  void _handleMapTap(LatLng pos) {
    setState(() {
      _pending = pos;
      _results = const [];
    });
    _openSaveSheet();
  }

  Future<void> _openSaveSheet({String name = '', String country = ''}) async {
    if (_pending == null) return;
    final saved = await showModal(
      context,
      child: _SavePinSheet(position: _pending!, initialName: name, initialCountry: country),
    );
    // Clear the pending pin whether saved (now a real marker) or cancelled.
    if (mounted) setState(() => _pending = null);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text($strings.discoverSaved), duration: const Duration(seconds: 2)),
      );
    }
  }

  Set<Marker> _buildMarkers(List<Place> places) {
    final markers = <Marker>{
      for (final p in places)
        if (p.lat != 0 || p.lng != 0)
          Marker(
            markerId: MarkerId(p.id),
            position: LatLng(p.lat, p.lng),
            icon: AppBitmaps.mapMarker,
            infoWindow: InfoWindow(title: p.name, snippet: p.country),
          ),
    };
    if (_pending != null) {
      markers.add(Marker(
        markerId: const MarkerId('pending'),
        position: _pending!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final places = watchX((PlacesLogic o) => o.saved);
    return ColoredBox(
      color: $styles.colors.greyStrong,
      child: Column(
        children: [
          SafeArea(bottom: false, child: _buildTopBar(context)),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: _initialCamera(places),
                    markers: _buildMarkers(places),
                    onMapCreated: (c) => _controller = c,
                    onTap: _handleMapTap,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
                if (_results.isNotEmpty) Positioned(left: 0, right: 0, top: 0, child: _buildResults()),
                if (_results.isEmpty) Positioned(left: 0, right: 0, bottom: 0, child: _buildHint()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all($styles.insets.sm),
      child: Row(
        children: [
          BackBtn(),
          Gap($styles.insets.sm),
          Expanded(
            child: _search.hasApiKey
                ? _buildSearchField()
                : Text(
                    $strings.discoverTapHint,
                    style: $styles.text.bodySmall.copyWith(color: $styles.colors.accent2),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _runSearch(),
      cursorColor: $styles.colors.accent1,
      style: $styles.text.body.copyWith(color: $styles.colors.offWhite),
      decoration: InputDecoration(
        isDense: true,
        hintText: $strings.discoverSearchHint,
        hintStyle: $styles.text.bodySmall.copyWith(color: $styles.colors.greyMedium),
        prefixIcon: _searching
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: $styles.colors.accent1)),
              )
            : Icon(Icons.search, color: $styles.colors.accent2, size: 20),
        filled: true,
        fillColor: $styles.colors.black.withOpacity(.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular($styles.corners.md),
          borderSide: BorderSide(color: $styles.colors.greyMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular($styles.corners.md),
          borderSide: BorderSide(color: $styles.colors.accent1),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      color: $styles.colors.greyStrong.withOpacity(.97),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      child: ListView.separated(
        padding: EdgeInsets.all($styles.insets.sm),
        shrinkWrap: true,
        itemCount: _results.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: $styles.colors.greyMedium.withOpacity(.3)),
        itemBuilder: (_, i) {
          final s = _results[i];
          return AppBtn.basic(
            onPressed: () => _selectSuggestion(s),
            semanticLabel: s.name,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.sm, horizontal: $styles.insets.xs),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, color: $styles.colors.accent1, size: 20),
                  Gap($styles.insets.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.name,
                            style: $styles.text.bodyBold.copyWith(color: $styles.colors.offWhite),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (s.address.isNotEmpty)
                          Text(s.address,
                              style: $styles.text.caption.copyWith(color: $styles.colors.greyMedium),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHint() {
    return IgnorePointer(
      child: Container(
        margin: EdgeInsets.all($styles.insets.md),
        padding: EdgeInsets.symmetric(horizontal: $styles.insets.md, vertical: $styles.insets.sm),
        decoration: BoxDecoration(
          color: $styles.colors.black.withOpacity(.55),
          borderRadius: BorderRadius.circular($styles.corners.md),
        ),
        child: Text(
          $strings.discoverTapHint,
          textAlign: TextAlign.center,
          style: $styles.text.caption.copyWith(color: $styles.colors.offWhite),
        ),
      ),
    );
  }
}
