import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_type.dart';

part 'media_data.freezed.dart';
part 'media_data.g.dart';

@freezed
abstract class MediaData with _$MediaData {
  const factory MediaData({required String url, required MediaType type}) =
      _MediaData;

  factory MediaData.fromJson(Map<String, dynamic> json) =>
      _$MediaDataFromJson(json);
}
