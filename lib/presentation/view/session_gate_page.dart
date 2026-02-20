import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/session_state.dart';
import 'package:nook_lounge_app/presentation/view/create_island_page.dart';
import 'package:nook_lounge_app/presentation/view/error_retry_view.dart';
import 'package:nook_lounge_app/presentation/view/home_shell_page.dart';
import 'package:nook_lounge_app/presentation/view/sign_in_page.dart';

class SessionGatePage extends ConsumerWidget {
  const SessionGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionViewModelProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.errorMessage != null) {
      return ErrorRetryView(
        message: AppStrings.loadErrorMessage,
        onRetry: () => ref.read(sessionViewModelProvider.notifier).refresh(),
      );
    }

    final session = state.session;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return session.when(
      signedOut: SignInPage.new,
      needsIslandSetup: (uid) => CreateIslandPage(uid: uid),
      ready: (uid) => HomeShellPage(uid: uid),
    );
  }
}
