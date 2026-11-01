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

  Future<void> init() => _load(showLoading: true);

  Future<void> refresh() => _load(showLoading: false);

  Future<void> _load({required bool showLoading}) async {
    emit(state.copyWith(isLoading: showLoading, errorKey: null));
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

  Future<bool?> toggleFavourite() async {
    final etf = state.etf;
    if (etf == null) return null;
    final favourite = !etf.favourite;
    emit(
      state.copyWith(
        etf: etf.copyWith(favourite: favourite),
        favouriteErrorKey: null,
      ),
    );
    try {
      if (favourite) {
        await _etfRepository.addFavourite(etf.ticker);
      } else {
        await _etfRepository.removeFavourite(etf.ticker);
      }
      return favourite;
    } catch (error) {
      emit(
        state.copyWith(
          etf: state.etf?.copyWith(favourite: !favourite),
          favouriteErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
      return null;
    }
  }
}
