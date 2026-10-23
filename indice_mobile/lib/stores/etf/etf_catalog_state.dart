import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/etf/etf_catalog_data.dart';

part 'etf_catalog_state.freezed.dart';

@freezed
abstract class EtfCatalogState with _$EtfCatalogState {
  const factory EtfCatalogState({
    EtfCatalogData? catalog,
    @Default(false) bool isLoading,
    String? errorKey,
  }) = _EtfCatalogState;
}
