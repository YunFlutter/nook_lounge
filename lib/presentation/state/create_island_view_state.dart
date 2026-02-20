import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_island_view_state.freezed.dart';

@freezed
sealed class CreateIslandViewState with _$CreateIslandViewState {
  const CreateIslandViewState._();

  const factory CreateIslandViewState({
    @Default(false) bool isSubmitting,
    @Default(false) bool submitSuccess,
    String? selectedImagePath,
    String? errorMessage,
  }) = _CreateIslandViewState;
}
