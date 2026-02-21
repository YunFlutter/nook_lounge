import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/app.dart';
import 'package:nook_lounge_app/firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
        developer.log(
          '[Global FlutterError] ${details.exceptionAsString()}',
          stackTrace: details.stack,
          error: details.exception,
          name: 'global',
        );
      };

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stackTrace) {
            developer.log(
              '[Global PlatformDispatcher] $error',
              error: error,
              stackTrace: stackTrace,
              name: 'global',
            );
            return false;
          };

      runApp(const ProviderScope(child: NookLoungeApp()));
    },
    (error, stackTrace) {
      developer.log(
        '[Global runZonedGuarded] $error',
        error: error,
        stackTrace: stackTrace,
        name: 'global',
      );
    },
  );
}
