import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/resource/resource_detail_data.dart';

part 'resource_detail_state.freezed.dart';

@freezed
abstract class ResourceDetailState with _$ResourceDetailState {
  const factory ResourceDetailState({
    ResourceDetailData? resource,
    @Default(false) bool isLoading,
    String? errorKey,
    String? favouriteErrorKey,
  }) = _ResourceDetailState;
}
