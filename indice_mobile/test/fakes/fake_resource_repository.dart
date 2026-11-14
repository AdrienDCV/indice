import 'package:indice_mobile/models/common/paginated_data.dart';
import 'package:indice_mobile/models/resource/media_data.dart';
import 'package:indice_mobile/models/resource/media_type.dart';
import 'package:indice_mobile/models/resource/resource_data.dart';
import 'package:indice_mobile/models/resource/resource_detail_data.dart';
import 'package:indice_mobile/models/resource/resource_level.dart';
import 'package:indice_mobile/models/resource/resource_type.dart';
import 'package:indice_mobile/repositories/cached_result.dart';
import 'package:indice_mobile/repositories/resource_repository.dart';

const feesArticle = ResourceData(
  id: 'fees',
  title: 'Comprendre les frais',
  description: 'Les frais d’un ETF.',
  type: ResourceType.article,
  durationMinutes: 7,
  level: ResourceLevel.beginner,
  favourite: false,
);

const diversificationVideo = ResourceData(
  id: 'diversification',
  title: 'La diversification',
  description: 'Répartir son investissement.',
  type: ResourceType.video,
  durationMinutes: 4,
  level: ResourceLevel.intermediate,
  media: MediaData(
    url: 'https://www.youtube.com/watch?v=eq537XjLofw',
    type: MediaType.video,
  ),
  favourite: true,
);

PaginatedData<ResourceData> buildResourcePage({
  List<ResourceData> resources = const [feesArticle, diversificationVideo],
  int page = 0,
  int totalPages = 1,
}) {
  return PaginatedData(
    content: resources,
    page: page,
    size: 20,
    totalElements: resources.length,
    totalPages: totalPages,
  );
}

ResourceDetailData buildResourceDetail({
  ResourceData resource = feesArticle,
  String content = 'Texte complet de l’article.',
}) {
  return ResourceDetailData(
    id: resource.id,
    title: resource.title,
    description: resource.description,
    content: content,
    type: resource.type,
    durationMinutes: resource.durationMinutes,
    level: resource.level,
    media: resource.media,
    favourite: resource.favourite,
  );
}

Future<PaginatedData<ResourceData>> _defaultPage() async => buildResourcePage();

Future<ResourceDetailData> _unexpectedRetrieveResource(String id) {
  throw UnimplementedError('retrieveResource($id) was not expected');
}

Future<void> _succeed(String id) async {}

typedef ResourceRequest = ({
  int page,
  int size,
  String search,
  Set<ResourceLevel> levels,
  bool favouritesOnly,
});

class FakeResourceRepository implements ResourceRepository {
  FakeResourceRepository({
    this.onRetrieveResources = _defaultPage,
    this.onRetrieveResource = _unexpectedRetrieveResource,
    this.onAddFavourite = _succeed,
    this.onRemoveFavourite = _succeed,
    this.catalogOffline = false,
    this.detailCachedAt,
  });

  Future<PaginatedData<ResourceData>> Function() onRetrieveResources;
  Future<ResourceDetailData> Function(String id) onRetrieveResource;
  Future<void> Function(String id) onAddFavourite;
  Future<void> Function(String id) onRemoveFavourite;
  bool catalogOffline;
  DateTime? detailCachedAt;
  final requests = <ResourceRequest>[];
  final retrievedIds = <String>[];
  final addedFavourites = <String>[];
  final removedFavourites = <String>[];

  @override
  Future<CachedResult<PaginatedData<ResourceData>>> retrieveResources({
    int page = 0,
    int size = 20,
    String search = '',
    Set<ResourceLevel> levels = const {},
    bool favouritesOnly = false,
  }) async {
    requests.add((
      page: page,
      size: size,
      search: search,
      levels: levels,
      favouritesOnly: favouritesOnly,
    ));
    return CachedResult(await onRetrieveResources(), offline: catalogOffline);
  }

  @override
  Future<CachedResult<ResourceDetailData>> retrieveResource(String id) async {
    retrievedIds.add(id);
    return CachedResult(
      await onRetrieveResource(id),
      offline: detailCachedAt != null,
      cachedAt: detailCachedAt,
    );
  }

  @override
  Future<void> addFavourite(String id) {
    addedFavourites.add(id);
    return onAddFavourite(id);
  }

  @override
  Future<void> removeFavourite(String id) {
    removedFavourites.add(id);
    return onRemoveFavourite(id);
  }

  int syncFavouriteDownloadsCalls = 0;

  @override
  Future<void> syncFavouriteDownloads() async {
    syncFavouriteDownloadsCalls++;
  }
}
