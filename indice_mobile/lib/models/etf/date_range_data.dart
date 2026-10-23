import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_range_data.freezed.dart';
part 'date_range_data.g.dart';

@freezed
abstract class DateRangeData with _$DateRangeData {
  const factory DateRangeData({
    required DateTime startDate,
    required DateTime endDate,
  }) = _DateRangeData;

  factory DateRangeData.fromJson(Map<String, dynamic> json) =>
      _$DateRangeDataFromJson(json);
}
