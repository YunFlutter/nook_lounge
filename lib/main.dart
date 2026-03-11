import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/app.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_provider.dart';
import 'package:nook_lounge_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final appTelemetry = AppTelemetry(
    analytics: FirebaseAnalytics.instance,
    crashlytics: FirebaseCrashlytics.instance,
  );
  await appTelemetry.initialize();
  appTelemetry.installErrorHandlers();

  final app = ProviderScope(
    overrides: <Override>[appTelemetryProvider.overrideWithValue(appTelemetry)],
    child: const NookLoungeApp(),
  );

  if (!appTelemetry.shouldCaptureUncaughtErrors) {
    runApp(app);
    return;
  }

  runZonedGuarded(() => runApp(app), (error, stackTrace) {
    unawaited(
      appTelemetry.recordError(
        error,
        stackTrace,
        reason: 'run_zoned_guarded',
        fatal: true,
      ),
    );
  });
}
