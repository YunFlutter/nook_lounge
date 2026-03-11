import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/telemetry/app_route_observer.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';

final appTelemetryProvider = Provider<AppTelemetry>((ref) {
  return AppTelemetry(
    analytics: FirebaseAnalytics.instance,
    crashlytics: FirebaseCrashlytics.instance,
  );
});

final appRouteObserverProvider = Provider<AppRouteObserver>((ref) {
  return AppRouteObserver(telemetry: ref.watch(appTelemetryProvider));
});
