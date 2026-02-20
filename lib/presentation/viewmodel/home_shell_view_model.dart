import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/presentation/state/home_shell_view_state.dart';

class HomeShellViewModel extends StateNotifier<HomeShellViewState> {
  HomeShellViewModel() : super(const HomeShellViewState());

  void changeTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}
