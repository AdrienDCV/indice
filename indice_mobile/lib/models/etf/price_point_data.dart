import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_point_data.freezed.dart';
part 'price_point_data.g.dart';

@freezed
abstract class PricePointData with _$PricePointData {
  const factory PricePointData({
    required DateTime date,
    required double close,
    required double changeSinceStart,
  }) = _PricePointData;

  factory PricePointData.fromJson(Map<String, dynamic> json) =>
      _$PricePointDataFromJson(json);
}
