import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_view_state.freezed.dart';

@freezed
sealed class SignInViewState with _$SignInViewState {
  const SignInViewState._();

  const factory SignInViewState({
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SignInViewState;
}
