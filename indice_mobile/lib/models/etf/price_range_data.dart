import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_range_data.freezed.dart';
part 'price_range_data.g.dart';

@freezed
abstract class PriceRangeData with _$PriceRangeData {
  const factory PriceRangeData({
    required double low,
    required double high,
    required double position,
  }) = _PriceRangeData;

  factory PriceRangeData.fromJson(Map<String, dynamic> json) =>
      _$PriceRangeDataFromJson(json);
}
