import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../http.dart';
import '../../repositories/resource_repository.dart';
import 'resource_detail_state.dart';

class ResourceDetailStore extends Cubit<ResourceDetailState> {
  ResourceDetailStore(this._resourceRepository, this._id)
    : super(const ResourceDetailState());

  final ResourceRepository _resourceRepository;
  final String _id;

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, errorKey: null));
    try {
      final resource = await _resourceRepository.retrieveResource(_id);
      emit(state.copyWith(resource: resource, isLoading: false));
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
    if (resource == null) return null;
    final favourite = !resource.favourite;
    emit(
      state.copyWith(
        resource: resource.copyWith(favourite: favourite),
        favouriteErrorKey: null,
      ),
    );
    try {
      if (favourite) {
        await _resourceRepository.addFavourite(resource.id);
      } else {
        await _resourceRepository.removeFavourite(resource.id);
      }
      return favourite;
    } catch (error) {
      emit(
        state.copyWith(
          resource: state.resource?.copyWith(favourite: !favourite),
          favouriteErrorKey: extractErrorMessage(error) ?? unexpectedErrorKey,
        ),
      );
      return null;
    }
  }
}
