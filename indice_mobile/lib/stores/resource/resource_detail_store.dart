import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../repositories/resource_repository.dart';
import 'resource_detail_state.dart';

class ResourceDetailStore extends Cubit<ResourceDetailState> {
  ResourceDetailStore(
    this._resourceRepository,
    this._id, {
    this._reconnectDelay = const Duration(seconds: 15),
  }) : super(const ResourceDetailState());

  final ResourceRepository _resourceRepository;
  final Duration _reconnectDelay;
  Timer? _reconnectTimer;
  bool _favouritePending = false;
  final String _id;

  Future<void> init() => _load(showLoading: true);

  Future<void> refresh() => _load(showLoading: false);

  @override
  Future<void> close() {
    _reconnectTimer?.cancel();
    return super.close();
  }

  Future<void> _load({required bool showLoading}) async {
    _reconnectTimer?.cancel();
    emit(state.copyWith(isLoading: showLoading, errorKey: null));
    try {
      final result = await _resourceRepository.retrieveResource(_id);
      emit(
        state.copyWith(
          resource: result.data,
          cachedAt: result.cachedAt,
          isLoading: false,
        ),
      );
      if (result.cachedAt != null && !isClosed) {
        _reconnectTimer = Timer(_reconnectDelay, refresh);
      }
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
    }
  }

  /// Renvoie le nouvel état de favori une fois confirmé par l'API, ou `null`.
  Future<bool?> toggleFavourite() async {
    final resource = state.resource;
    if (resource == null || _favouritePending) return null;
    _favouritePending = true;
    final favourite = !resource.favourite;
    emit(state.copyWith(favouriteErrorKey: null));
    try {
      if (favourite) {
        await _resourceRepository.addFavourite(resource.id);
      } else {
        await _resourceRepository.removeFavourite(resource.id);
      }
      emit(
        state.copyWith(
          resource: state.resource?.copyWith(favourite: favourite),
        ),
      );
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
