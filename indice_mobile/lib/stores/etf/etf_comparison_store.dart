import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../models/etf/etf_data.dart';
import '../../repositories/etf_repository.dart';
import 'etf_comparison_state.dart';

class EtfComparisonStore extends Cubit<EtfComparisonState> {
  EtfComparisonStore(this._etfRepository, {String? etfA})
    : super(EtfComparisonState(etfA: etfA));

  static const suggestionCount = 10;

  final EtfRepository _etfRepository;

  Future<void> selectEtfA(String ticker) async {
    emit(
      state.copyWith(
        etfA: ticker,
        comparison: null,
        isLoading: false,
        errorKey: null,
      ),
    );
    await _compare();
  }

  Future<void> selectEtfB(String ticker) async {
    emit(
      state.copyWith(
        etfB: ticker,
        comparison: null,
        isLoading: false,
        errorKey: null,
      ),
    );
    await _compare();
  }

  Future<void> retry() => _compare();

  Future<List<EtfData>> suggestEtfs(String search) async {
    try {
      final catalog = await _etfRepository.retrieveEtfs(
        search: search,
        size: suggestionCount,
      );
      return catalog.etfs.content;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _compare() async {
    final etfA = state.etfA;
    final etfB = state.etfB;
    if (etfA == null || etfB == null) return;

    bool isCurrentPair() => state.etfA == etfA && state.etfB == etfB;

    emit(state.copyWith(isLoading: true, errorKey: null));
    try {
      final comparison = await _etfRepository.compare(etfA, etfB);
      if (!isCurrentPair()) return;
      emit(state.copyWith(comparison: comparison, isLoading: false));
    } catch (error) {
      if (!isCurrentPair()) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }
}
