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
  bool _favouritePending = false;

  Future<void> init() => _load(showLoading: true);

  Future<void> refresh() => _load(showLoading: false);

  Future<void> _load({required bool showLoading}) async {
    emit(state.copyWith(isLoading: showLoading, errorKey: null));
    try {
      final result = await _etfRepository.retrieveEtf(_ticker);
      emit(
        state.copyWith(
          etf: result.data,
          cachedAt: result.cachedAt,
          isLoading: false,
        ),
      );
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
    if (etf == null || _favouritePending) return null;
    _favouritePending = true;
    final favourite = !etf.favourite;
    emit(state.copyWith(favouriteErrorKey: null));
    try {
      if (favourite) {
        await _etfRepository.addFavourite(etf.ticker);
      } else {
        await _etfRepository.removeFavourite(etf.ticker);
      }
      emit(state.copyWith(etf: state.etf?.copyWith(favourite: favourite)));
      return favourite;
    } catch (error) {
      emit(
        state.copyWith(
          favouriteErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
      return null;
    } finally {
      _favouritePending = false;
    }
  }
}
