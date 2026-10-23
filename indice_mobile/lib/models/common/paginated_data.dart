import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_data.freezed.dart';
part 'paginated_data.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class PaginatedData<T> with _$PaginatedData<T> {
  const factory PaginatedData({
    required List<T> content,
    required int page,
    required int size,
    required int totalElements,
    required int totalPages,
  }) = _PaginatedData<T>;

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedDataFromJson(json, fromJsonT);
}
