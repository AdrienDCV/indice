import '../http.dart';
import '../models/etf/etf_catalog_data.dart';

class EtfRepository {
  Future<EtfCatalogData> retrieveEtfs() async {
    final response = await http.get<Map<String, dynamic>>(
      '/etfs',
      queryParameters: {'size': 100},
    );
    return EtfCatalogData.fromJson(response.data!);
  }
}
