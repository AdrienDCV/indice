import 'package:freezed_annotation/freezed_annotation.dart';

import 'performance_data.dart';
import 'price_point_data.dart';

part 'compared_etf_data.freezed.dart';
part 'compared_etf_data.g.dart';

@freezed
abstract class ComparedEtfData with _$ComparedEtfData {
  const factory ComparedEtfData({
    required String ticker,
    required String exchange,
    required String name,
    required String currency,
    DateTime? fetchedAt,
    required bool stale,
    required PerformanceData performance,
    required List<PricePointData> pricePoints,
  }) = _ComparedEtfData;

  factory ComparedEtfData.fromJson(Map<String, dynamic> json) =>
      _$ComparedEtfDataFromJson(json);
}
