import 'package:dio/dio.dart';
import 'package:indice_mobile/models/common/paginated_data.dart';
import 'package:indice_mobile/models/etf/etf_catalog_data.dart';
import 'package:indice_mobile/models/etf/etf_data.dart';
import 'package:indice_mobile/models/etf/etf_detail_data.dart';
import 'package:indice_mobile/models/etf/market_data.dart';
import 'package:indice_mobile/models/etf/max_drawdown_data.dart';
import 'package:indice_mobile/models/etf/price_point_data.dart';
import 'package:indice_mobile/models/etf/price_range_data.dart';
import 'package:indice_mobile/models/etf/returns_data.dart';
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

final spyMarketData = MarketData(
  lastClose: 766.48,
  lastCloseDate: DateTime(2026, 10, 19),
  historyStartDate: DateTime(2021, 10, 12),
  returns: const ReturnsData(
    oneYear: 0.142,
    threeYears: 0.51,
    fiveYears: 0.88,
    fiveYearsAnnualized: 0.135,
  ),
  volatilityOneYear: 0.161,
  maxDrawdown: MaxDrawdownData(
    value: -0.245,
    peakDate: DateTime(2022, 1, 3),
    troughDate: DateTime(2022, 10, 12),
  ),
  fiftyTwoWeekRange: const PriceRangeData(
    low: 629.28,
    high: 781.62,
    position: 0.9,
  ),
  pricePoints: [
    PricePointData(
      date: DateTime(2021, 10, 12),
      close: 450,
      changeSinceStart: 0,
    ),
    PricePointData(
      date: DateTime(2024, 3, 12),
      close: 512.4,
      changeSinceStart: 0.1387,
    ),
    PricePointData(
      date: DateTime(2026, 10, 19),
      close: 766.48,
      changeSinceStart: 0.7033,
    ),
  ],
);

EtfDetailData buildEtfDetail({MarketData? marketData, bool stale = false}) {
  return EtfDetailData(
    ticker: spy.ticker,
    exchange: spy.exchange,
    name: spy.name,
    currency: spy.currency,
    marketData: marketData,
    fetchedAt: DateTime.utc(2026, 10, 20, 9),
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

Future<EtfDetailData> _unexpectedRetrieveEtf(String ticker) {
  throw UnimplementedError('retrieveEtf($ticker) was not expected');
}

class FakeEtfRepository implements EtfRepository {
  FakeEtfRepository(
    this.onRetrieveEtfs, {
    this.onRetrieveEtf = _unexpectedRetrieveEtf,
  });

  Future<EtfCatalogData> Function() onRetrieveEtfs;
  Future<EtfDetailData> Function(String ticker) onRetrieveEtf;
  int retrieveEtfsCalls = 0;
  final retrievedTickers = <String>[];

  @override
  Future<EtfCatalogData> retrieveEtfs() {
    retrieveEtfsCalls++;
    return onRetrieveEtfs();
  }

  @override
  Future<EtfDetailData> retrieveEtf(String ticker) {
    retrievedTickers.add(ticker);
    return onRetrieveEtf(ticker);
  }
}
