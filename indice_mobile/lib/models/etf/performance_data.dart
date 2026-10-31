import 'package:freezed_annotation/freezed_annotation.dart';

import 'max_drawdown_data.dart';

part 'performance_data.freezed.dart';
part 'performance_data.g.dart';

@freezed
abstract class PerformanceData with _$PerformanceData {
  const factory PerformanceData({
    required double totalReturn,
    double? annualizedReturn,
    double? volatility,
    double? returnToRiskRatio,
    required MaxDrawdownData maxDrawdown,
  }) = _PerformanceData;

  factory PerformanceData.fromJson(Map<String, dynamic> json) =>
      _$PerformanceDataFromJson(json);
}
