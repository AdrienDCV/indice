import '../http.dart';
import '../models/etf/etf_catalog_data.dart';
import '../models/etf/etf_comparison_data.dart';
import '../models/etf/etf_detail_data.dart';

class EtfRepository {
  Future<EtfCatalogData> retrieveEtfs() async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs',
      queryParameters: {'size': 100},
    );
    return EtfCatalogData.fromJson(response.data!);
  }

  Future<EtfDetailData> retrieveEtf(String ticker) async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs/${Uri.encodeComponent(ticker)}',
    );
    return EtfDetailData.fromJson(response.data!);
  }

  Future<EtfComparisonData> compare(String etfA, String etfB) async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs/compare',
      queryParameters: {'etfA': etfA, 'etfB': etfB},
    );
    return EtfComparisonData.fromJson(response.data!);
  }
}
