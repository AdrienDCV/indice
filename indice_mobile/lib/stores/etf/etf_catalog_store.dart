import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../repositories/etf_repository.dart';
import 'etf_catalog_state.dart';

class EtfCatalogStore extends Cubit<EtfCatalogState> {
  EtfCatalogStore(this._etfRepository) : super(const EtfCatalogState());

  final EtfRepository _etfRepository;

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, errorKey: null));
    try {
      final catalog = await _etfRepository.retrieveEtfs();
      emit(state.copyWith(catalog: catalog, isLoading: false));
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }
}
