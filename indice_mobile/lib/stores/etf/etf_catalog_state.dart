import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/etf/etf_data.dart';

part 'etf_catalog_state.freezed.dart';

@freezed
abstract class EtfCatalogState with _$EtfCatalogState {
  const factory EtfCatalogState({
    @Default([]) List<EtfData> etfs,
    @Default('') String search,
    @Default(false) bool favouritesOnly,
    @Default(0) int nextPage,
    @Default(false) bool hasMore,
    DateTime? fetchedAt,
    @Default(false) bool stale,
    @Default(false) bool isLoading,
    String? errorKey,
    @Default(false) bool isLoadingMore,
    String? loadMoreErrorKey,
    String? favouriteErrorKey,
  }) = _EtfCatalogState;
}
