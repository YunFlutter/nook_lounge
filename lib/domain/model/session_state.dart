import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/user_service_block.dart';

part 'session_state.freezed.dart';

@freezed
sealed class SessionState with _$SessionState {
  const SessionState._();

  const factory SessionState.signedOut() = SessionSignedOut;

  const factory SessionState.needsIslandSetup({required String uid}) =
      SessionNeedsIslandSetup;

  const factory SessionState.ready({required String uid}) = SessionReady;

  const factory SessionState.blocked({
    required String uid,
    required UserServiceBlock block,
  }) = SessionBlocked;
}
