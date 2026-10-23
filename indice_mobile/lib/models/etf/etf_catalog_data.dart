import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/paginated_data.dart';
import 'etf_data.dart';

part 'etf_catalog_data.freezed.dart';
part 'etf_catalog_data.g.dart';

@freezed
abstract class EtfCatalogData with _$EtfCatalogData {
  const factory EtfCatalogData({
    required PaginatedData<EtfData> etfs,
    DateTime? fetchedAt,
    required bool stale,
  }) = _EtfCatalogData;

  factory EtfCatalogData.fromJson(Map<String, dynamic> json) =>
      _$EtfCatalogDataFromJson(json);
}
