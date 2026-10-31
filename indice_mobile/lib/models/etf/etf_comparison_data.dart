import 'package:freezed_annotation/freezed_annotation.dart';

import 'compared_etf_data.dart';
import 'date_range_data.dart';

part 'etf_comparison_data.freezed.dart';
part 'etf_comparison_data.g.dart';

@freezed
abstract class EtfComparisonData with _$EtfComparisonData {
  const factory EtfComparisonData({
    required DateRangeData commonPeriod,
    double? correlation,
    required ComparedEtfData etfA,
    required ComparedEtfData etfB,
  }) = _EtfComparisonData;

  factory EtfComparisonData.fromJson(Map<String, dynamic> json) =>
      _$EtfComparisonDataFromJson(json);
}
