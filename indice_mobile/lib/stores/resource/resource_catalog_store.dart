import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../models/common/paginated_data.dart';
import '../../models/resource/resource_data.dart';
import '../../models/resource/resource_level.dart';
import '../../repositories/cached_result.dart';
import '../../repositories/resource_repository.dart';
import 'resource_catalog_state.dart';

class ResourceCatalogStore extends Cubit<ResourceCatalogState> {
  ResourceCatalogStore(
    this._resourceRepository, {
    this._reconnectDelay = const Duration(seconds: 15),
  }) : super(const ResourceCatalogState());

  static const pageSize = 20;
  static const searchDelay = Duration(milliseconds: 300);

  final ResourceRepository _resourceRepository;
  final Duration _reconnectDelay;
  Timer? _searchTimer;
  Timer? _reconnectTimer;
  int _request = 0;
  final Set<String> _pendingFavourites = {};

  Future<void> init() => _loadFirstPage();

  Future<void> refresh() => _loadFirstPage(showLoading: false);

  Future<void> syncFavouriteDownloads() =>
      _resourceRepository.syncFavouriteDownloads();

  void searchChanged(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      emit(state.copyWith(search: text.trim()));
      _loadFirstPage();
    });
  }

  Future<void> levelToggled(ResourceLevel level, bool isSelected) {
    final levels = {...state.levels};
    if (isSelected) {
      levels.add(level);
    } else {
      levels.remove(level);
    }
    emit(state.copyWith(levels: levels));
    return _loadFirstPage();
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
      final page = (await _retrievePage(state.nextPage)).data;
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          resources: [...state.resources, ...page.content],
          nextPage: state.nextPage + 1,
          hasMore: _hasMore(page),
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }

  Future<void> toggleFavourite(String id) async {
    final index = state.resources.indexWhere((resource) => resource.id == id);
    if (index == -1 || _pendingFavourites.contains(id)) return;
    _pendingFavourites.add(id);
    final favourite = !state.resources[index].favourite;
    emit(state.copyWith(favouriteErrorKey: null));
    try {
      if (favourite) {
        await _resourceRepository.addFavourite(id);
      } else {
        await _resourceRepository.removeFavourite(id);
      }
      if (isClosed) return;
      favouriteChanged(id, favourite);
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          favouriteErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    } finally {
      _pendingFavourites.remove(id);
    }
  }

  void favouriteChanged(String id, bool favourite) {
    final index = state.resources.indexWhere((resource) => resource.id == id);
    if (index == -1) return;
    emit(state.copyWith(resources: _withFavourite(index, favourite)));
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
      if (isClosed || request != _request) return;
      final page = result.data;
      emit(
        state.copyWith(
          resources: page.content,
          nextPage: 1,
          hasMore: _hasMore(page),
          offline: result.offline,
          favouritesOnly: result.offline || favourites,
          isLoading: false,
        ),
      );
      if (result.offline) {
        _reconnectTimer = Timer(
          _reconnectDelay,
          () => _loadFirstPage(showLoading: false, favouritesOnly: false),
        );
      }
    } catch (error) {
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          resources: const [],
          hasMore: false,
          isLoading: false,
          errorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }

  Future<CachedResult<PaginatedData<ResourceData>>> _retrievePage(
    int page, {
    bool? favouritesOnly,
  }) {
    return _resourceRepository.retrieveResources(
      page: page,
      size: pageSize,
      search: state.search,
      levels: state.levels,
      favouritesOnly: favouritesOnly ?? state.favouritesOnly,
    );
  }

  bool _hasMore(PaginatedData<ResourceData> page) =>
      page.page + 1 < page.totalPages;

  /// Met à jour l'état de favori de la ressource n°[index], ou la retire de la
  /// liste si seuls les favoris sont affichés et qu'elle n'en est plus un.
  List<ResourceData> _withFavourite(int index, bool favourite) {
    final resources = [...state.resources];
    if (state.favouritesOnly && !favourite) {
      return resources..removeAt(index);
    }
    resources[index] = resources[index].copyWith(favourite: favourite);
    return resources;
  }
}
