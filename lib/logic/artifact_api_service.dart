import 'package:wonders/logic/common/http_client.dart';
import 'package:wonders/logic/data/artifact_data.dart';

class ArtifactAPIService {
  final String _baseMETUrl = 'https://collectionapi.metmuseum.org/public/collection/v1';
  final String _baseSelfHostedUrl = 'https://www.wonderous.info/met';

  Future<ServiceResult<ArtifactData?>> getMetObjectByID(String id) async {
    HttpResponse? response = await HttpClient.send('$_baseMETUrl/objects/$id');
    return ServiceResult<ArtifactData?>(response, _parseArtifactData);
  }

  Future<ServiceResult<ArtifactData?>> getSelfHostedObjectByID(String id) async {
    HttpResponse? response = await HttpClient.send('$_baseSelfHostedUrl/$id.json');
    return ServiceResult<ArtifactData?>(response, _parseArtifactData);
  }

  /// Live MET search. [queryString] is a pre-built, url-encoded param string
  /// (eg. `geoLocation=Japan&q=Japan`). Returns the list of matching object ids.
  /// The MET search endpoint only returns ids; metadata + images for each must
  /// be fetched separately via [getMetObjectByID].
  Future<ServiceResult<List<int>>> searchObjectIds(String queryString) async {
    HttpResponse response = await HttpClient.send('$_baseMETUrl/search?hasImages=true&$queryString');
    return ServiceResult<List<int>>(response, _parseObjectIds);
  }

  List<int> _parseObjectIds(Map<String, dynamic> content) {
    final ids = content['objectIDs'];
    if (ids is! List) return const [];
    return ids.whereType<int>().toList(growable: false);
  }

  ArtifactData? _parseArtifactData(Map<String, dynamic> content) {
    // Source: https://metmuseum.github.io/
    return ArtifactData(
      objectId: content['objectID'].toString(),
      title: content['title'] ?? '',
      image: content['primaryImage'] ?? '',
      imageSmall: content['primaryImageSmall'] ?? '',
      date: content['objectDate'] ?? '',
      objectType: content['objectName'] ?? '',
      period: content['period'] ?? '',
      country: content['country'] ?? '',
      medium: content['medium'] ?? '',
      dimension: content['dimension'] ?? '',
      classification: content['classification'] ?? '',
      culture: content['culture'] ?? '',
      objectBeginYear: content['objectBeginDate'],
      objectEndYear: content['objectEndDate'],
    );
  }
}
