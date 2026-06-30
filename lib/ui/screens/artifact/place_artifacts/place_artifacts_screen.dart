import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/data/artifact_data.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/ui/common/controls/app_header.dart';
import 'package:wonders/ui/common/controls/app_loading_indicator.dart';
import 'package:wonders/ui/screens/artifact/artifact_details/artifact_details_screen.dart';

/// Live, per-place artifact browser. Resolves the saved [Place] by id, queries
/// the MET collection for its country/culture, then lazily fetches each object's
/// metadata + thumbnail as the user scrolls (the MET search endpoint returns
/// only ids). Tapping a tile opens the shared artifact details screen sourced
/// live from MET.
class PlaceArtifactsScreen extends StatefulWidget {
  const PlaceArtifactsScreen({super.key, required this.placeId});
  final String placeId;

  @override
  State<PlaceArtifactsScreen> createState() => _PlaceArtifactsScreenState();
}

class _PlaceArtifactsScreenState extends State<PlaceArtifactsScreen> {
  Place? _place;
  late Future<List<int>> _idsFuture;

  @override
  void initState() {
    super.initState();
    _place = placesLogic.fromId(widget.placeId);
    _idsFuture = _loadIds();
  }

  Future<List<int>> _loadIds() {
    final place = _place;
    if (place == null) return Future.value(const []);
    return artifactLogic.getObjectIdsForPlace(place);
  }

  void _retry() => setState(() => _idsFuture = _loadIds());

  void _handleArtifactPressed(ArtifactData data) {
    context.go(ScreenPaths.artifact(data.objectId, src: ArtifactSource.met.name));
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;
    return ColoredBox(
      color: $styles.colors.greyStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: place?.name ?? $strings.placeArtifactsTitle,
            subtitle: place?.country,
          ),
          Expanded(
            child: place == null
                ? _Message(icon: Icons.error_outline, text: $strings.placeArtifactsMissing)
                : FutureBuilder<List<int>>(
                    future: _idsFuture,
                    builder: (_, snapshot) {
                      if (snapshot.hasError) {
                        return _Message(
                          icon: Icons.wifi_off_outlined,
                          text: $strings.placeArtifactsError,
                          onRetry: _retry,
                        );
                      }
                      if (snapshot.connectionState != ConnectionState.done) {
                        return Center(child: AppLoadingIndicator());
                      }
                      final ids = snapshot.data ?? const [];
                      if (ids.isEmpty) {
                        return _Message(
                          icon: Icons.search_off_outlined,
                          text: $strings.placeArtifactsEmpty(place.country.isEmpty ? place.name : place.country),
                          onRetry: _retry,
                        );
                      }
                      return _ArtifactGrid(ids: ids, onPressed: _handleArtifactPressed);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Progressively loads artifact metadata for a list of MET object ids, a page at
/// a time, appending tiles as the user nears the bottom of the grid.
class _ArtifactGrid extends StatefulWidget {
  const _ArtifactGrid({required this.ids, required this.onPressed});
  final List<int> ids;
  final void Function(ArtifactData) onPressed;

  @override
  State<_ArtifactGrid> createState() => _ArtifactGridState();
}

class _ArtifactGridState extends State<_ArtifactGrid> {
  static const int _pageSize = 24;

  final List<ArtifactData> _loaded = [];
  final ScrollController _controller = ScrollController();
  int _nextIndex = 0;
  bool _isLoading = false;

  bool get _hasMore => _nextIndex < widget.ids.length;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    if (mounted) setState(() {});

    final end = min(_nextIndex + _pageSize, widget.ids.length);
    final pageIds = widget.ids.sublist(_nextIndex, end);
    _nextIndex = end;

    final results = await Future.wait(pageIds.map(_tryFetch));
    final fetched = results.whereType<ArtifactData>().where((a) => a.imageSmall.isNotEmpty);
    _loaded.addAll(fetched);
    _isLoading = false;

    if (!mounted) return;
    setState(() {});
    // If a whole page yielded no displayable images, keep pulling so the grid
    // isn't left looking empty while ids remain.
    if (fetched.isEmpty && _hasMore) _loadNextPage();
  }

  Future<ArtifactData?> _tryFetch(int id) async {
    try {
      return await artifactLogic.getArtifactByID(id.toString(), selfHosted: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded.isEmpty && _isLoading) {
      return Center(child: AppLoadingIndicator());
    }
    return ScrollDecorator.shadow(
      controller: _controller,
      builder: (controller) => CustomScrollView(
        controller: controller,
        scrollBehavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        clipBehavior: Clip.hardEdge,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all($styles.insets.sm),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: (context.widthPx / 300).ceil(),
              mainAxisSpacing: $styles.insets.sm,
              crossAxisSpacing: $styles.insets.sm,
              childCount: _loaded.length,
              itemBuilder: (_, index) => _ArtifactTile(data: _loaded[index], onPressed: widget.onPressed),
            ),
          ),
          if (_hasMore || _isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all($styles.insets.lg),
                child: Center(child: AppLoadingIndicator()),
              ),
            ),
          SliverToBoxAdapter(child: Gap($styles.insets.offset)),
        ],
      ),
    );
  }
}

class _ArtifactTile extends StatelessWidget {
  const _ArtifactTile({required this.data, required this.onPressed});
  final ArtifactData data;
  final void Function(ArtifactData) onPressed;

  @override
  Widget build(BuildContext context) {
    final int id = int.tryParse(data.objectId) ?? data.objectId.hashCode;
    return AspectRatio(
      aspectRatio: (id % 10) / 15 + 0.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular($styles.insets.xs),
        child: AppBtn.basic(
          semanticLabel: data.title,
          onPressed: () => onPressed(data),
          child: Container(
            color: $styles.colors.black,
            width: double.infinity,
            height: double.infinity,
            child: AppImage(
              key: ValueKey(data.objectId),
              image: NetworkImage(data.imageSmall),
              fit: BoxFit.cover,
              scale: 0.5,
              distractor: true,
              color: $styles.colors.greyMedium.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: $styles.colors.accent1, size: 64),
            Gap($styles.insets.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: $styles.text.body.copyWith(color: $styles.colors.offWhite),
            ),
            if (onRetry != null) ...[
              Gap($styles.insets.lg),
              AppBtn.from(onPressed: onRetry!, text: $strings.placeArtifactsRetry),
            ],
          ],
        ),
      ),
    );
  }
}
