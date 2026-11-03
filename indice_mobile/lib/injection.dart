import 'dart:io';

import 'package:get_it/get_it.dart';

import 'repositories/etf_repository.dart';
import 'repositories/resource_repository.dart';
import 'storage/api_cache.dart';

final getIt = GetIt.instance;

void configureDependencies(Directory apiCacheDirectory) {
  getIt.registerLazySingleton(() => ApiCache(apiCacheDirectory));
  getIt.registerLazySingleton(() => EtfRepository(getIt<ApiCache>()));
  getIt.registerLazySingleton(ResourceRepository.new);
}
