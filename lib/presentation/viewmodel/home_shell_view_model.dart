import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_events.dart';
import 'package:nook_lounge_app/presentation/state/home_shell_view_state.dart';

class HomeShellViewModel extends StateNotifier<HomeShellViewState> {
  HomeShellViewModel({required AppTelemetry telemetry})
    : _telemetry = telemetry,
      super(const HomeShellViewState());

  final AppTelemetry _telemetry;

  void changeTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
    unawaited(
      _telemetry.logEvent(
        AppTelemetryEvents.homeTabSelected,
        parameters: <String, Object>{
          'tab_index': index,
          'tab_name': _resolveTabName(index),
        },
      ),
    );
  }

  String _resolveTabName(int index) {
    switch (index) {
      case 0:
        return 'airport';
      case 1:
        return 'market';
      case 2:
        return 'home';
      case 3:
        return 'catalog';
      case 4:
        return 'turnip';
      default:
        return 'unknown';
    }
  }
}
