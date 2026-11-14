import 'package:dio/dio.dart';

import '../http.dart';
import '../models/common/paginated_data.dart';
import '../models/resource/resource_data.dart';
import '../models/resource/resource_detail_data.dart';
import '../models/resource/resource_level.dart';
import '../storage/api_cache.dart';
import 'cached_result.dart';

const _downloadPrefix = 'resource_detail_';
const _favouritesPageSize = 100;

class ResourceRepository {
  ResourceRepository(this._apiCache);

  final ApiCache _apiCache;

  Future<CachedResult<PaginatedData<ResourceData>>> retrieveResources({
    int page = 0,
    int size = 20,
    String search = '',
    Set<ResourceLevel> levels = const {},
    bool favouritesOnly = false,
  }) async {
    try {
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
      return CachedResult(
        PaginatedData.fromJson(
          response.data!,
          (json) => ResourceData.fromJson(json! as Map<String, dynamic>),
        ),
      );
    } on DioException catch (error) {
      if (page != 0 ||
          search.isNotEmpty ||
          levels.isNotEmpty ||
          !_isUnreachable(error)) {
        rethrow;
      }
      final downloads = await _downloadedFavourites();
      return CachedResult(
        _pageOf(downloads.map((download) => download.data).toList()),
        offline: true,
      );
    }
  }

  Future<CachedResult<ResourceDetailData>> retrieveResource(String id) async {
    try {
      final response = await http.get<Map<String, dynamic>>(
        '/resources/${Uri.encodeComponent(id)}',
      );
      final json = response.data!;
      final detail = ResourceDetailData.fromJson(json);
      if (detail.favourite) {
        await _apiCache.write(_downloadKey(id), json);
      } else {
        await _apiCache.delete(_downloadKey(id));
      }
      return CachedResult(detail);
    } on DioException catch (error) {
      if (!_isUnreachable(error)) rethrow;
      final download = await _readDownload(id);
      if (download == null) rethrow;
      return download;
    }
  }

  Future<void> addFavourite(String id) async {
    await http.put<void>('/resources/${Uri.encodeComponent(id)}/favourite');
    try {
      await retrieveResource(id);
    } catch (_) {}
  }

  Future<void> removeFavourite(String id) async {
    await http.delete<void>('/resources/${Uri.encodeComponent(id)}/favourite');
    await _apiCache.delete(_downloadKey(id));
  }

  Future<void> syncFavouriteDownloads() async {
    try {
      final favourites = await _favouriteIds();
      final downloaded = {
        for (final download in await _downloadedFavourites()) download.data.id,
      };
      for (final id in favourites.difference(downloaded)) {
        try {
          await retrieveResource(id);
        } catch (_) {}
      }
      for (final id in downloaded.difference(favourites)) {
        await _apiCache.delete(_downloadKey(id));
      }
    } catch (_) {}
  }

  Future<Set<String>> _favouriteIds() async {
    final ids = <String>{};
    var page = 0;
    var totalPages = 1;
    while (page < totalPages) {
      final resources = (await retrieveResources(
        page: page,
        size: _favouritesPageSize,
        favouritesOnly: true,
      )).data;
      ids.addAll(resources.content.map((resource) => resource.id));
      totalPages = resources.totalPages;
      page++;
    }
    return ids;
  }

  Future<List<CachedResult<ResourceDetailData>>> _downloadedFavourites() async {
    final downloadedFiles = await _apiCache.readAll(_downloadPrefix);
    final downloads = <CachedResult<ResourceDetailData>>[];
    for (final downloadedFile in downloadedFiles) {
      final download = _downloadOf(downloadedFile);
      if (download != null) downloads.add(download);
    }
    return downloads;
  }

  Future<CachedResult<ResourceDetailData>?> _readDownload(String id) async {
    final cached = await _apiCache.read(_downloadKey(id));
    return cached == null ? null : _downloadOf(cached);
  }

  CachedResult<ResourceDetailData>? _downloadOf(CachedResponse cached) {
    final detail = _detailOf(cached.response);
    if (detail == null) return null;
    return CachedResult(detail, offline: true, cachedAt: cached.cachedAt);
  }

  ResourceDetailData? _detailOf(Map<String, dynamic> json) {
    try {
      return ResourceDetailData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  PaginatedData<ResourceData> _pageOf(List<ResourceDetailData> details) {
    final resources = [
      for (final detail in details)
        ResourceData(
          id: detail.id,
          title: detail.title,
          description: detail.description,
          type: detail.type,
          durationMinutes: detail.durationMinutes,
          level: detail.level,
          media: detail.media,
          favourite: detail.favourite,
        ),
    ]..sort((a, b) => a.title.compareTo(b.title));
    return PaginatedData(
      content: resources,
      page: 0,
      size: resources.length,
      totalElements: resources.length,
      totalPages: 1,
    );
  }

  String _downloadKey(String id) => '$_downloadPrefix$id';

  bool _isUnreachable(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == null || statusCode >= 500;
  }
}
