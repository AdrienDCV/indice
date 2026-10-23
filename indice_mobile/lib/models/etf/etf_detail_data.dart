import 'package:freezed_annotation/freezed_annotation.dart';

import 'market_data.dart';

part 'etf_detail_data.freezed.dart';
part 'etf_detail_data.g.dart';

@freezed
abstract class EtfDetailData with _$EtfDetailData {
  const factory EtfDetailData({
    required String ticker,
    required String exchange,
    required String name,
    required String currency,
    MarketData? marketData,
    DateTime? fetchedAt,
    required bool stale,
  }) = _EtfDetailData;

  factory EtfDetailData.fromJson(Map<String, dynamic> json) =>
      _$EtfDetailDataFromJson(json);
}
