import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../models/etf/etf_catalog_data.dart';
import '../../models/etf/etf_data.dart';
import '../../repositories/cached_result.dart';
import '../../repositories/etf_repository.dart';
import 'etf_catalog_state.dart';

class EtfCatalogStore extends Cubit<EtfCatalogState> {
  EtfCatalogStore(
    this._etfRepository, {
    this._reconnectDelay = const Duration(seconds: 15),
  }) : super(const EtfCatalogState());

  static const pageSize = 50;
  static const searchDelay = Duration(milliseconds: 300);

  final EtfRepository _etfRepository;
  final Duration _reconnectDelay;
  Timer? _searchTimer;
  Timer? _reconnectTimer;
  int _request = 0;
  final Set<String> _pendingFavourites = {};
  bool _downloadsSynced = false;

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
    if (!state.hasMore ||
        state.isLoading ||
        state.isLoadingMore ||
        state.offline) {
      return;
    }
    final request = _request;
    emit(state.copyWith(isLoadingMore: true, loadMoreErrorKey: null));
    try {
      final catalog = (await _retrievePage(state.nextPage)).data;
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
    if (index == -1 || _pendingFavourites.contains(ticker)) return;
    _pendingFavourites.add(ticker);
    final favourite = !state.etfs[index].favourite;
    emit(state.copyWith(favouriteErrorKey: null));
    try {
      if (favourite) {
        await _etfRepository.addFavourite(ticker);
      } else {
        await _etfRepository.removeFavourite(ticker);
      }
      favouriteChanged(ticker, favourite);
    } catch (error) {
      emit(
        state.copyWith(
          favouriteErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    } finally {
      _pendingFavourites.remove(ticker);
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
    _reconnectTimer?.cancel();
    return super.close();
  }

  Future<void> _loadFirstPage({
    bool showLoading = true,
    bool? favouritesOnly,
  }) async {
    _reconnectTimer?.cancel();
    final request = ++_request;
    final favourites = favouritesOnly ?? state.favouritesOnly;
    emit(
      state.copyWith(
        isLoading: showLoading,
        errorKey: null,
        isLoadingMore: false,
        loadMoreErrorKey: null,
      ),
    );
    try {
      final result = await _retrievePage(0, favouritesOnly: favourites);
      if (request != _request) return;
      final catalog = result.data;
      emit(
        state.copyWith(
          etfs: catalog.etfs.content,
          nextPage: 1,
          hasMore: _hasMore(catalog),
          fetchedAt: catalog.fetchedAt,
          stale: catalog.stale,
          offline: result.offline,
          favouritesOnly: result.offline || favourites,
          isLoading: false,
        ),
      );
      if (result.offline && !isClosed) {
        _reconnectTimer = Timer(
          _reconnectDelay,
          () => _loadFirstPage(showLoading: false, favouritesOnly: false),
        );
      }
      if (!result.offline && !_downloadsSynced) {
        _downloadsSynced = true;
        unawaited(_etfRepository.syncFavouriteDownloads());
      }
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

  Future<CachedResult<EtfCatalogData>> _retrievePage(
    int page, {
    bool? favouritesOnly,
  }) {
    return _etfRepository.retrieveEtfs(
      page: page,
      size: pageSize,
      search: state.search,
      favouritesOnly: favouritesOnly ?? state.favouritesOnly,
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
