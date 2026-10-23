import 'package:dio/dio.dart';
import 'package:indice_mobile/models/common/paginated_data.dart';
import 'package:indice_mobile/models/etf/etf_catalog_data.dart';
import 'package:indice_mobile/models/etf/etf_data.dart';
import 'package:indice_mobile/repositories/etf_repository.dart';

const spy = EtfData(
  ticker: 'SPY',
  exchange: 'NYSE ARCA',
  name: 'SPDR S&P 500 ETF Trust',
  currency: 'USD',
);

const qqq = EtfData(
  ticker: 'QQQ',
  exchange: 'NASDAQ',
  name: 'Invesco QQQ Trust',
  currency: 'USD',
);

EtfCatalogData buildCatalog({
  List<EtfData> etfs = const [spy, qqq],
  DateTime? fetchedAt,
  bool stale = false,
}) {
  return EtfCatalogData(
    etfs: PaginatedData(
      content: etfs,
      page: 0,
      size: 100,
      totalElements: etfs.length,
      totalPages: 1,
    ),
    fetchedAt: fetchedAt,
    stale: stale,
  );
}

DioException apiError(String errorKey) {
  final requestOptions = RequestOptions(path: '/etfs');
  return DioException.badResponse(
    statusCode: 500,
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: 500,
      data: [
        {'error': 'Internal Server Error', 'message': errorKey},
      ],
    ),
  );
}

class FakeEtfRepository implements EtfRepository {
  FakeEtfRepository(this.onRetrieveEtfs);

  Future<EtfCatalogData> Function() onRetrieveEtfs;
  int retrieveEtfsCalls = 0;

  @override
  Future<EtfCatalogData> retrieveEtfs() {
    retrieveEtfsCalls++;
    return onRetrieveEtfs();
  }
}
