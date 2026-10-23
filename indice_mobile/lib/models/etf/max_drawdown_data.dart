import 'package:freezed_annotation/freezed_annotation.dart';

part 'max_drawdown_data.freezed.dart';
part 'max_drawdown_data.g.dart';

@freezed
abstract class MaxDrawdownData with _$MaxDrawdownData {
  const factory MaxDrawdownData({
    required double value,
    required DateTime peakDate,
    required DateTime troughDate,
  }) = _MaxDrawdownData;

  factory MaxDrawdownData.fromJson(Map<String, dynamic> json) =>
      _$MaxDrawdownDataFromJson(json);
}
