import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_events.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_provider.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/session_state.dart';
import 'package:nook_lounge_app/presentation/state/session_view_state.dart';
import 'package:nook_lounge_app/presentation/viewmodel/session_view_model.dart';

class AppTelemetryScope extends ConsumerStatefulWidget {
  const AppTelemetryScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppTelemetryScope> createState() => _AppTelemetryScopeState();
}

class _AppTelemetryScopeState extends ConsumerState<AppTelemetryScope> {
  String? _lastSessionFingerprint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _syncSession(previous: null, next: ref.read(sessionViewModelProvider)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionViewState>(sessionViewModelProvider, (previous, next) {
      unawaited(_syncSession(previous: previous, next: next));
    });

    return widget.child;
  }

  Future<void> _syncSession({
    required SessionViewState? previous,
    required SessionViewState next,
  }) async {
    final current = _resolveSessionSnapshot(next.session);
    if (current == null) {
      return;
    }

    final fingerprint = '${current.sessionType}|${current.uid ?? ''}';
    if (_lastSessionFingerprint == fingerprint) {
      return;
    }
    _lastSessionFingerprint = fingerprint;

    final telemetry = ref.read(appTelemetryProvider);
    await telemetry.setUserContext(
      uid: current.uid,
      sessionType: current.sessionType,
    );

    final previousSnapshot = _resolveSessionSnapshot(previous?.session);
    if (previousSnapshot?.sessionType == current.sessionType) {
      return;
    }

    unawaited(
      telemetry.logEvent(
        AppTelemetryEvents.sessionStateChanged,
        parameters: <String, Object?>{
          'session_state': current.sessionType,
          'previous_state': previousSnapshot?.sessionType,
        },
      ),
    );
  }

  ({String sessionType, String? uid})? _resolveSessionSnapshot(
    SessionState? session,
  ) {
    if (session == null) {
      return null;
    }

    return session.when(
      signedOut: () => (sessionType: 'signed_out', uid: null),
      needsIslandSetup: (uid) =>
          (sessionType: 'needs_island_setup', uid: _normalizeUid(uid)),
      ready: (uid) {
        if (uid == SessionViewModel.guestUid) {
          return (sessionType: 'guest', uid: null);
        }

        final sessionType = ref.read(authRepositoryProvider).isAnonymous
            ? 'anonymous'
            : 'member';
        return (sessionType: sessionType, uid: _normalizeUid(uid));
      },
      blocked: (uid, block) =>
          (sessionType: 'blocked', uid: _normalizeUid(uid)),
    );
  }

  String? _normalizeUid(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return null;
    }
    return normalizedUid;
  }
}
