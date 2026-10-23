import 'package:get_it/get_it.dart';

import 'repositories/etf_repository.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton(EtfRepository.new);
}
