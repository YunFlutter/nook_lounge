import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/model/create_island_draft.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';
import 'package:nook_lounge_app/presentation/state/create_island_view_state.dart';

class CreateIslandViewModel extends StateNotifier<CreateIslandViewState> {
  CreateIslandViewModel({required IslandRepository islandRepository})
    : _islandRepository = islandRepository,
      super(const CreateIslandViewState());

  final IslandRepository _islandRepository;

  void setSelectedImagePath(String? imagePath) {
    state = state.copyWith(selectedImagePath: imagePath);
  }

  Future<String?> createIsland({
    required String uid,
    required CreateIslandDraft draft,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      submitSuccess: false,
      errorMessage: null,
    );

    try {
      final islandId = await _islandRepository.createPrimaryIsland(
        uid: uid,
        draft: draft,
        passportImagePath: state.selectedImagePath,
      );
      state = state.copyWith(isSubmitting: false, submitSuccess: true);
      return islandId;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        submitSuccess: false,
        errorMessage: error.toString(),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void resetSubmitState() {
    state = state.copyWith(submitSuccess: false);
  }
}
