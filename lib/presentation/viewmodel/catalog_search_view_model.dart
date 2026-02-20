import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';
import 'package:nook_lounge_app/presentation/state/catalog_search_view_state.dart';

class CatalogSearchViewModel extends StateNotifier<CatalogSearchViewState> {
  CatalogSearchViewModel({required CatalogRepository catalogRepository})
    : _catalogRepository = catalogRepository,
      super(const CatalogSearchViewState()) {
    loadInitial();
  }

  final CatalogRepository _catalogRepository;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final items = await _catalogRepository.loadAll();

      state = state.copyWith(
        isLoading: false,
        items: items,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> search({required String keyword, String? category}) async {
    state = state.copyWith(
      isLoading: true,
      keyword: keyword,
      selectedCategory: category,
      errorMessage: null,
    );

    try {
      final items = await _catalogRepository.search(
        keyword: keyword,
        category: category,
      );

      state = state.copyWith(
        isLoading: false,
        items: items,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
