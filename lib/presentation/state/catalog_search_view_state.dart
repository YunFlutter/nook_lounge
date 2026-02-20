import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';

part 'catalog_search_view_state.freezed.dart';

@freezed
sealed class CatalogSearchViewState with _$CatalogSearchViewState {
  const CatalogSearchViewState._();

  const factory CatalogSearchViewState({
    @Default(false) bool isLoading,
    @Default('') String keyword,
    String? selectedCategory,
    @Default(<CatalogItem>[]) List<CatalogItem> items,
    String? errorMessage,
  }) = _CatalogSearchViewState;
}
