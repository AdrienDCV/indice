import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../models/etf/etf_catalog_data.dart';
import '../../models/etf/etf_data.dart';
import '../../repositories/etf_repository.dart';
import 'etf_catalog_state.dart';

class EtfCatalogStore extends Cubit<EtfCatalogState> {
  EtfCatalogStore(this._etfRepository) : super(const EtfCatalogState());

  static const pageSize = 50;
  static const searchDelay = Duration(milliseconds: 300);

  final EtfRepository _etfRepository;
  Timer? _searchTimer;
  int _request = 0;

  Future<void> init() => _loadFirstPage();

  Future<void> refresh() => _loadFirstPage(showLoading: false);

  void searchChanged(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      emit(state.copyWith(search: text.trim()));
      _loadFirstPage();
    });
  }

  Future<void> favouritesOnlyChanged(bool favouritesOnly) {
    emit(state.copyWith(favouritesOnly: favouritesOnly));
    return _loadFirstPage();
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    final request = _request;
    emit(state.copyWith(isLoadingMore: true, loadMoreErrorKey: null));
    try {
      final catalog = await _retrievePage(state.nextPage);
      if (request != _request) return;
      emit(
        state.copyWith(
          etfs: [...state.etfs, ...catalog.etfs.content],
          nextPage: state.nextPage + 1,
          hasMore: _hasMore(catalog),
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (request != _request) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }

  Future<void> toggleFavourite(String ticker) async {
    final index = state.etfs.indexWhere((etf) => etf.ticker == ticker);
    if (index == -1) return;
    final etf = state.etfs[index];
    final favourite = !etf.favourite;
    emit(
      state.copyWith(
        etfs: _withFavourite(state.etfs, etf, favourite, index),
        favouriteErrorKey: null,
      ),
    );
    try {
      if (favourite) {
        await _etfRepository.addFavourite(ticker);
      } else {
        await _etfRepository.removeFavourite(ticker);
      }
    } catch (error) {
      emit(
        state.copyWith(
          etfs: _withFavourite(state.etfs, etf, !favourite, index),
          favouriteErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }

  void favouriteChanged(String ticker, bool favourite) {
    final index = state.etfs.indexWhere((etf) => etf.ticker == ticker);
    if (index == -1) return;
    emit(
      state.copyWith(
        etfs: _withFavourite(state.etfs, state.etfs[index], favourite, index),
      ),
    );
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _loadFirstPage({bool showLoading = true}) async {
    final request = ++_request;
    emit(
      state.copyWith(
        isLoading: showLoading,
        errorKey: null,
        isLoadingMore: false,
        loadMoreErrorKey: null,
      ),
    );
    try {
      final catalog = await _retrievePage(0);
      if (request != _request) return;
      emit(
        state.copyWith(
          etfs: catalog.etfs.content,
          nextPage: 1,
          hasMore: _hasMore(catalog),
          fetchedAt: catalog.fetchedAt,
          stale: catalog.stale,
          isLoading: false,
        ),
      );
    } catch (error) {
      if (request != _request) return;
      emit(
        state.copyWith(
          etfs: const [],
          hasMore: false,
          isLoading: false,
          errorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }

  Future<EtfCatalogData> _retrievePage(int page) {
    return _etfRepository.retrieveEtfs(
      page: page,
      size: pageSize,
      search: state.search,
      favouritesOnly: state.favouritesOnly,
    );
  }

  bool _hasMore(EtfCatalogData catalog) =>
      catalog.etfs.page + 1 < catalog.etfs.totalPages;

  List<EtfData> _withFavourite(
    List<EtfData> etfs,
    EtfData etf,
    bool favourite,
    int index,
  ) {
    final others = [
      for (final other in etfs)
        if (other.ticker != etf.ticker) other,
    ];
    if (state.favouritesOnly && !favourite) return others;
    final position = etfs.any((other) => other.ticker == etf.ticker)
        ? etfs.indexWhere((other) => other.ticker == etf.ticker)
        : index.clamp(0, others.length);
    return [...others]..insert(position, etf.copyWith(favourite: favourite));
  }
}
