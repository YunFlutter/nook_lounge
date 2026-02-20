import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/session_state.dart';

part 'session_view_state.freezed.dart';

@freezed
sealed class SessionViewState with _$SessionViewState {
  const SessionViewState._();

  const factory SessionViewState({
    @Default(true) bool isLoading,
    SessionState? session,
    String? errorTitle,
    String? errorMessage,
  }) = _SessionViewState;
}
