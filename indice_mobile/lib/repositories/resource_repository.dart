import '../http.dart';
import '../models/common/paginated_data.dart';
import '../models/resource/resource_data.dart';
import '../models/resource/resource_detail_data.dart';
import '../models/resource/resource_level.dart';

class ResourceRepository {
  Future<PaginatedData<ResourceData>> retrieveResources({
    int page = 0,
    int size = 20,
    String search = '',
    Set<ResourceLevel> levels = const {},
    bool favouritesOnly = false,
  }) async {
    final response = await http.get<Map<String, dynamic>>(
      '/resources',
      queryParameters: {
        'page': page,
        'size': size,
        if (search.isNotEmpty) 'search': search,
        if (levels.isNotEmpty)
          'levels': levels.map((level) => level.apiValue).join(','),
        if (favouritesOnly) 'favourites': true,
      },
    );
    return PaginatedData.fromJson(
      response.data!,
      (json) => ResourceData.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<ResourceDetailData> retrieveResource(String id) async {
    final response = await http.get<Map<String, dynamic>>(
      '/resources/${Uri.encodeComponent(id)}',
    );
    return ResourceDetailData.fromJson(response.data!);
  }

  Future<void> addFavourite(String id) async {
    await http.put<void>('/resources/${Uri.encodeComponent(id)}/favourite');
  }

  Future<void> removeFavourite(String id) async {
    await http.delete<void>('/resources/${Uri.encodeComponent(id)}/favourite');
  }
}
