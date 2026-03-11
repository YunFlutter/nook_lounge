import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_provider.dart';
import 'package:nook_lounge_app/presentation/view/session_gate_page.dart';

final appNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: ref.watch(appNavigatorKeyProvider),
    observers: <NavigatorObserver>[ref.watch(appRouteObserverProvider)],
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const SessionGatePage()),
    ],
  );
});
