import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_provider.dart';

class AppScreenView extends ConsumerStatefulWidget {
  const AppScreenView({
    required this.screenName,
    required this.child,
    super.key,
  });

  final String screenName;
  final Widget child;

  @override
  ConsumerState<AppScreenView> createState() => _AppScreenViewState();
}

class _AppScreenViewState extends ConsumerState<AppScreenView> {
  String? _lastLoggedScreenName;

  @override
  void initState() {
    super.initState();
    _scheduleTrack();
  }

  @override
  void didUpdateWidget(covariant AppScreenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName == widget.screenName) {
      return;
    }
    _scheduleTrack();
  }

  void _scheduleTrack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final normalizedScreenName = widget.screenName.trim();
      if (normalizedScreenName.isEmpty ||
          normalizedScreenName == _lastLoggedScreenName) {
        return;
      }

      _lastLoggedScreenName = normalizedScreenName;
      unawaited(
        ref
            .read(appTelemetryProvider)
            .logScreenView(
              screenName: normalizedScreenName,
              parameters: const <String, Object>{'screen_origin': 'widget'},
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
