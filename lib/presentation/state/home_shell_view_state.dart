import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_shell_view_state.freezed.dart';

@freezed
sealed class HomeShellViewState with _$HomeShellViewState {
  const HomeShellViewState._();

  const factory HomeShellViewState({@Default(2) int selectedTabIndex}) =
      _HomeShellViewState;
}
