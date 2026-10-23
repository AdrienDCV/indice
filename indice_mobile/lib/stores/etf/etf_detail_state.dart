import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/etf/etf_detail_data.dart';

part 'etf_detail_state.freezed.dart';

@freezed
abstract class EtfDetailState with _$EtfDetailState {
  const factory EtfDetailState({
    EtfDetailData? etf,
    @Default(false) bool isLoading,
    String? errorKey,
  }) = _EtfDetailState;
}
