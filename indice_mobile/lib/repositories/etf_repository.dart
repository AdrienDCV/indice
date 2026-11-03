import 'package:dio/dio.dart';

import '../http.dart';
import '../models/common/paginated_data.dart';
import '../models/etf/etf_catalog_data.dart';
import '../models/etf/etf_comparison_data.dart';
import '../models/etf/etf_data.dart';
import '../models/etf/etf_detail_data.dart';
import '../storage/api_cache.dart';
import 'cached_result.dart';

const _downloadPrefix = 'etf_detail_';
const _favouritesPageSize = 100;

class EtfRepository {
  EtfRepository(this._apiCache);

  final ApiCache _apiCache;

  Future<CachedResult<EtfCatalogData>> retrieveEtfs({
    int page = 0,
    int size = 50,
    String search = '',
    bool favouritesOnly = false,
  }) async {
    try {
      final response = await http.get<Map<String, dynamic>>(
        '/etfs',
        queryParameters: {
          'page': page,
          'size': size,
          if (search.isNotEmpty) 'search': search,
          if (favouritesOnly) 'favourites': true,
        },
      );
      return CachedResult(EtfCatalogData.fromJson(response.data!));
    } on DioException catch (error) {
      if (page != 0 || search.isNotEmpty || !_isUnreachable(error)) rethrow;
      final downloads = await _downloadedFavourites();
      return CachedResult(
        _catalogOf(downloads.map((download) => download.data).toList()),
        offline: true,
      );
    }
  }

  Future<CachedResult<EtfDetailData>> retrieveEtf(String ticker) async {
    try {
      final response = await http.get<Map<String, dynamic>>(
        '/etfs/${Uri.encodeComponent(ticker)}',
      );
      final json = response.data!;
      final detail = EtfDetailData.fromJson(json);
      if (detail.favourite) {
        await _apiCache.write(_downloadKey(ticker), json);
      } else {
        await _apiCache.delete(_downloadKey(ticker));
      }
      return CachedResult(detail);
    } on DioException catch (error) {
      if (!_isUnreachable(error)) rethrow;
      final download = await _readDownload(ticker);
      if (download == null) rethrow;
      return download;
    }
  }

  Future<void> addFavourite(String ticker) async {
    final response = await http.put<Map<String, dynamic>>(
      '/etfs/${Uri.encodeComponent(ticker)}/favourite',
    );
    final json = response.data;
    if (json != null) await _apiCache.write(_downloadKey(ticker), json);
  }

  Future<void> removeFavourite(String ticker) async {
    await http.delete<void>('/etfs/${Uri.encodeComponent(ticker)}/favourite');
    await _apiCache.delete(_downloadKey(ticker));
  }

  Future<void> syncFavouriteDownloads() async {
    try {
      final favourites = await _favouriteTickers();
      final downloaded = {
        for (final download in await _downloadedFavourites())
          download.data.ticker,
      };
      for (final ticker in favourites.difference(downloaded)) {
        try {
          await retrieveEtf(ticker);
        } catch (_) {}
      }
      for (final ticker in downloaded.difference(favourites)) {
        await _apiCache.delete(_downloadKey(ticker));
      }
    } catch (_) {}
  }

  Future<EtfComparisonData> compare(String etfA, String etfB) async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs/compare',
      queryParameters: {'etfA': etfA, 'etfB': etfB},
    );
    return EtfComparisonData.fromJson(response.data!);
  }

  Future<Set<String>> _favouriteTickers() async {
    final tickers = <String>{};
    var page = 0;
    var totalPages = 1;
    while (page < totalPages) {
      final catalog = (await retrieveEtfs(
        page: page,
        size: _favouritesPageSize,
        favouritesOnly: true,
      )).data;
      tickers.addAll(catalog.etfs.content.map((etf) => etf.ticker));
      totalPages = catalog.etfs.totalPages;
      page++;
    }
    return tickers;
  }

  Future<List<CachedResult<EtfDetailData>>> _downloadedFavourites() async {
    final downloadedFiles = await _apiCache.readAll(_downloadPrefix);
    final downloads = <CachedResult<EtfDetailData>>[];
    for (final downloadedFile in downloadedFiles) {
      final download = _downloadOf(downloadedFile);
      if (download != null) downloads.add(download);
    }
    return downloads;
  }

  Future<CachedResult<EtfDetailData>?> _readDownload(String ticker) async {
    final cached = await _apiCache.read(_downloadKey(ticker));
    return cached == null ? null : _downloadOf(cached);
  }

  CachedResult<EtfDetailData>? _downloadOf(CachedResponse cached) {
    final detail = _detailOf(cached.response);
    if (detail == null) return null;
    return CachedResult(detail, offline: true, cachedAt: cached.cachedAt);
  }

  EtfDetailData? _detailOf(Map<String, dynamic> json) {
    try {
      return EtfDetailData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  EtfCatalogData _catalogOf(List<EtfDetailData> details) {
    final etfs = [
      for (final detail in details)
        EtfData(
          ticker: detail.ticker,
          exchange: detail.exchange,
          name: detail.name,
          currency: detail.currency,
          favourite: detail.favourite,
          leveragedOrInverse: detail.leveragedOrInverse,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return EtfCatalogData(
      etfs: PaginatedData(
        content: etfs,
        page: 0,
        size: etfs.length,
        totalElements: etfs.length,
        totalPages: 1,
      ),
      fetchedAt: null,
      stale: false,
    );
  }

  String _downloadKey(String ticker) => '$_downloadPrefix$ticker';

  bool _isUnreachable(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == null || statusCode >= 500;
  }
}
