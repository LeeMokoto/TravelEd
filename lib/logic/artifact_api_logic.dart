import 'dart:collection';

import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/http_client.dart';
import 'package:wonders/logic/data/artifact_data.dart';
import 'package:wonders/logic/data/met_query.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/artifact_api_service.dart';

class ArtifactAPILogic {
  final HashMap<String, ArtifactData?> _artifactCache = HashMap();
  final HashMap<String, List<int>> _placeIdsCache = HashMap();

  ArtifactAPIService get service => GetIt.I.get<ArtifactAPIService>();

  /// Returns artifact data by ID. Returns null if artifact cannot be found. */
  Future<ArtifactData?> getArtifactByID(String id, {bool selfHosted = false}) async {
    if (_artifactCache.containsKey(id)) return _artifactCache[id];
    ServiceResult<ArtifactData?> result =
        (await (selfHosted ? service.getSelfHostedObjectByID(id) : service.getMetObjectByID(id)));
    if (!result.success) throw $strings.artifactDetailsErrorNotFound(id);
    ArtifactData? artifact = result.content;
    return _artifactCache[id] = artifact;
  }

  /// Returns the list of MET object ids for a [place], queried live and cached
  /// per query so re-opening the same place (or another place that resolves to
  /// the same country) doesn't re-hit the network. Metadata + images for each id
  /// are fetched lazily by the grid via [getArtifactByID].
  Future<List<int>> getObjectIdsForPlace(Place place) async {
    final query = MetQuery.buildPlaceQuery(place);
    final cached = _placeIdsCache[query];
    if (cached != null) return cached;
    final result = await service.searchObjectIds(query);
    // Throw (don't cache) on network/parse failure, so the screen can show an
    // error state and its retry can re-fetch. A successful-but-empty search
    // returns [] and is cached.
    if (!result.success) throw Exception('MET search failed for "$query"');
    final ids = result.content ?? const <int>[];
    return _placeIdsCache[query] = ids;
  }
}
