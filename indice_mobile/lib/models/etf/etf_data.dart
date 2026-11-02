import 'package:freezed_annotation/freezed_annotation.dart';

part 'etf_data.freezed.dart';
part 'etf_data.g.dart';

@freezed
abstract class EtfData with _$EtfData {
  const factory EtfData({
    required String ticker,
    required String exchange,
    required String name,
    required String currency,
    required bool favourite,
    required bool leveragedOrInverse,
  }) = _EtfData;

  factory EtfData.fromJson(Map<String, dynamic> json) =>
      _$EtfDataFromJson(json);
}
