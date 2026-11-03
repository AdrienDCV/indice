import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/resource/resource_data.dart';
import '../../models/resource/resource_level.dart';

part 'resource_catalog_state.freezed.dart';

@freezed
abstract class ResourceCatalogState with _$ResourceCatalogState {
  const factory ResourceCatalogState({
    @Default([]) List<ResourceData> resources,
    @Default('') String search,
    @Default({}) Set<ResourceLevel> levels,
    @Default(false) bool favouritesOnly,
    @Default(0) int nextPage,
    @Default(false) bool hasMore,
    @Default(false) bool isLoading,
    String? errorKey,
    @Default(false) bool isLoadingMore,
    String? loadMoreErrorKey,
    String? favouriteErrorKey,
  }) = _ResourceCatalogState;
}
