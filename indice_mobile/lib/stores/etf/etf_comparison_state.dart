import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/etf/etf_comparison_data.dart';

part 'etf_comparison_state.freezed.dart';

@freezed
abstract class EtfComparisonState with _$EtfComparisonState {
  const factory EtfComparisonState({
    String? etfA,
    String? etfB,
    EtfComparisonData? comparison,
    @Default(false) bool isLoading,
    String? errorKey,
  }) = _EtfComparisonState;
}
