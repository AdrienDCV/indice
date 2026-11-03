import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_data.dart';
import 'resource_level.dart';
import 'resource_type.dart';

part 'resource_detail_data.freezed.dart';
part 'resource_detail_data.g.dart';

@freezed
abstract class ResourceDetailData with _$ResourceDetailData {
  const factory ResourceDetailData({
    required String id,
    required String title,
    required String description,
    required String content,
    required ResourceType type,
    required int durationMinutes,
    required ResourceLevel level,
    MediaData? media,
    required bool favourite,
  }) = _ResourceDetailData;

  factory ResourceDetailData.fromJson(Map<String, dynamic> json) =>
      _$ResourceDetailDataFromJson(json);
}
