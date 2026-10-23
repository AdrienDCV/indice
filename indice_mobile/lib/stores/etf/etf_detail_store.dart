import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../repositories/etf_repository.dart';
import 'etf_detail_state.dart';

class EtfDetailStore extends Cubit<EtfDetailState> {
  EtfDetailStore(this._etfRepository, this._ticker)
    : super(const EtfDetailState());

  final EtfRepository _etfRepository;
  final String _ticker;

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, errorKey: null));
    try {
      final etf = await _etfRepository.retrieveEtf(_ticker);
      emit(state.copyWith(etf: etf, isLoading: false));
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
