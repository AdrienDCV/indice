import '../http.dart';
import '../models/etf/etf_catalog_data.dart';
import '../models/etf/etf_comparison_data.dart';
import '../models/etf/etf_detail_data.dart';

class EtfRepository {
  Future<EtfCatalogData> retrieveEtfs({
    int page = 0,
    int size = 50,
    String search = '',
    bool favouritesOnly = false,
  }) async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs',
      queryParameters: {
        'page': page,
        'size': size,
        if (search.isNotEmpty) 'search': search,
        if (favouritesOnly) 'favourites': true,
      },
    );
    return EtfCatalogData.fromJson(response.data!);
  }

  Future<EtfDetailData> retrieveEtf(String ticker) async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs/${Uri.encodeComponent(ticker)}',
    );
    return EtfDetailData.fromJson(response.data!);
  }

  Future<void> addFavourite(String ticker) async {
    await http.put<void>('/etfs/${Uri.encodeComponent(ticker)}/favourite');
  }

  Future<void> removeFavourite(String ticker) async {
    await http.delete<void>('/etfs/${Uri.encodeComponent(ticker)}/favourite');
  }

  Future<EtfComparisonData> compare(String etfA, String etfB) async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs/compare',
      queryParameters: {'etfA': etfA, 'etfB': etfB},
    );
    return EtfComparisonData.fromJson(response.data!);
  }
}
