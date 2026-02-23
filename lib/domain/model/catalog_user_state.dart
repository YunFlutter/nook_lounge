import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_user_state.freezed.dart';

@freezed
sealed class CatalogUserState with _$CatalogUserState {
  const factory CatalogUserState({
    required String itemId,
    required bool owned,
    required bool donated,
    required bool favorite,
    required String category,
    required String memo,
  }) = _CatalogUserState;

  factory CatalogUserState.fromMap({
    required String itemId,
    required Map<String, dynamic> data,
  }) {
    return CatalogUserState(
      itemId: itemId,
      owned: (data['owned'] as bool?) ?? false,
      donated: (data['donated'] as bool?) ?? false,
      favorite: (data['favorite'] as bool?) ?? false,
      category: (data['category'] as String?) ?? '',
      memo: (data['memo'] as String?) ?? '',
    );
  }
}
