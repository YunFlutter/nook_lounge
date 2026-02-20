import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_state.freezed.dart';

@freezed
sealed class SessionState with _$SessionState {
  const SessionState._();

  const factory SessionState.signedOut() = SessionSignedOut;

  const factory SessionState.needsIslandSetup({required String uid}) =
      SessionNeedsIslandSetup;

  const factory SessionState.ready({required String uid}) = SessionReady;
}
