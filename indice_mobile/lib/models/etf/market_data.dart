import 'package:freezed_annotation/freezed_annotation.dart';

import 'max_drawdown_data.dart';
import 'price_point_data.dart';
import 'price_range_data.dart';
import 'returns_data.dart';

part 'market_data.freezed.dart';
part 'market_data.g.dart';

@freezed
abstract class MarketData with _$MarketData {
  const factory MarketData({
    required double lastClose,
    required DateTime lastCloseDate,
    required DateTime historyStartDate,
    required ReturnsData returns,
    double? volatilityOneYear,
    MaxDrawdownData? maxDrawdown,
    PriceRangeData? fiftyTwoWeekRange,
    required List<PricePointData> pricePoints,
  }) = _MarketData;

  factory MarketData.fromJson(Map<String, dynamic> json) =>
      _$MarketDataFromJson(json);
}
