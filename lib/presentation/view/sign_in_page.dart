import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/presentation/state/sign_in_view_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/animated_scale_button.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  ProviderSubscription<SignInViewState>? _signInSubscription;

  @override
  void initState() {
    super.initState();

    _signInSubscription = ref.listenManual<SignInViewState>(
      signInViewModelProvider,
      (previous, next) {
        if (next.errorMessage == null ||
            next.errorMessage == previous?.errorMessage) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));

        ref.read(signInViewModelProvider.notifier).clearError();
      },
    );
  }

  @override
  void dispose() {
    _signInSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(signInViewModelProvider);
    final viewModel = ref.read(signInViewModelProvider.notifier);
    final loading = signInState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: <Widget>[
              const Spacer(),
              const AnimatedFadeSlide(
                child: Icon(Icons.travel_explore, size: 88),
              ),
              const SizedBox(height: 20),
              const AnimatedFadeSlide(
                delay: Duration(milliseconds: 40),
                child: Text(
                  '즐거운 섬 생활의 시작',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              const AnimatedFadeSlide(
                delay: Duration(milliseconds: 80),
                child: Text(
                  '로그인 후 섬 정보를 관리하고\n비행장/마켓/도감을 이용할 수 있어요.',
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 120),
                child: AnimatedScaleButton(
                  onTap: loading ? () {} : viewModel.signInWithApple,
                  child: Semantics(
                    button: true,
                    label: AppStrings.appleLogin,
                    child: FilledButton(
                      onPressed: loading ? null : viewModel.signInWithApple,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text(AppStrings.appleLogin),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 160),
                child: AnimatedScaleButton(
                  onTap: loading ? () {} : viewModel.signInWithGoogle,
                  child: Semantics(
                    button: true,
                    label: AppStrings.googleLogin,
                    child: OutlinedButton(
                      onPressed: loading ? null : viewModel.signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Text(AppStrings.googleLogin),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: loading ? null : viewModel.signInAsGuest,
                  child: const Text(AppStrings.guestLogin),
                ),
              ),
              const SizedBox(height: 12),
              const AnimatedFadeSlide(
                delay: Duration(milliseconds: 240),
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
