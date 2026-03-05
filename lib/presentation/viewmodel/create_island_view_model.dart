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
    // 유지보수 포인트:
    // 빠른 연타/중복 탭으로 동일 요청이 여러 번 들어오지 않도록
    // ViewModel 레벨에서 1차 방어합니다.
    if (state.isSubmitting) {
      return null;
    }

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
