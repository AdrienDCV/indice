import 'package:freezed_annotation/freezed_annotation.dart';

part 'returns_data.freezed.dart';
part 'returns_data.g.dart';

@freezed
abstract class ReturnsData with _$ReturnsData {
  const factory ReturnsData({
    double? oneYear,
    double? threeYears,
    double? fiveYears,
    double? fiveYearsAnnualized,
  }) = _ReturnsData;

  factory ReturnsData.fromJson(Map<String, dynamic> json) =>
      _$ReturnsDataFromJson(json);
}
