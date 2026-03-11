import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';

class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver({required AppTelemetry telemetry}) : _telemetry = telemetry;

  final AppTelemetry _telemetry;
  String? _lastTrackedRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _trackRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _trackRoute(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _trackRoute(previousRoute);
  }

  void _trackRoute(Route<dynamic>? route) {
    final routeName = route?.settings.name?.trim();
    if (routeName == null || routeName.isEmpty || routeName.startsWith('/')) {
      return;
    }
    if (_lastTrackedRouteName == routeName) {
      return;
    }

    _lastTrackedRouteName = routeName;
    unawaited(
      _telemetry.logScreenView(
        screenName: routeName,
        parameters: const <String, Object>{'screen_origin': 'route'},
      ),
    );
  }
}
