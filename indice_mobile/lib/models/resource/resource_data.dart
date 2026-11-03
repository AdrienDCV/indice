import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_data.dart';
import 'resource_level.dart';
import 'resource_type.dart';

part 'resource_data.freezed.dart';
part 'resource_data.g.dart';

@freezed
abstract class ResourceData with _$ResourceData {
  const factory ResourceData({
    required String id,
    required String title,
    required String description,
    required ResourceType type,
    required int durationMinutes,
    required ResourceLevel level,
    MediaData? media,
    required bool favourite,
  }) = _ResourceData;

  factory ResourceData.fromJson(Map<String, dynamic> json) =>
      _$ResourceDataFromJson(json);
}
