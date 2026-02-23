import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
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

class _SignInPageState extends ConsumerState<SignInPage>
    with SingleTickerProviderStateMixin {
  ProviderSubscription<SignInViewState>? _signInSubscription;
  late final AnimationController _heroAnimationController;

  @override
  void initState() {
    super.initState();

    _heroAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

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
    _heroAnimationController.dispose();
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
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _heroAnimationController,
                builder: (context, child) {
                  final value = _heroAnimationController.value;
                  final floatOffset = (value - 0.5) * 10;
                  final scale = 0.98 + (value * 0.04);

                  return Transform.translate(
                    offset: Offset(0, floatOffset),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: Image.asset(
                  'assets/images/login.png',
                  width: 136,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 22),
              AnimatedFadeSlide(
                delay: Duration(milliseconds: 40),
                child: Text(
                  '즐거운 섬 생활의 시작',
                  style: AppTextStyles.headingH2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedFadeSlide(
                delay: Duration(milliseconds: 80),
                child: Text(
                  '나의 섬 주민들, 도감을 관리하고,\n무 주식을 체크하며 나만의 드림 아일랜드를\n만들어보세요.',
                  style: AppTextStyles.labelWithColor(
                    AppColors.textSecondary,
                    weight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 3),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 120),
                child: AnimatedScaleButton(
                  onTap: loading ? () {} : viewModel.signInWithApple,
                  child: FilledButton(
                    onPressed: loading ? null : viewModel.signInWithApple,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Image(
                          image: AssetImage('assets/images/apple.png'),
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 10),
                        Text(
                          AppStrings.appleLogin,
                          style: AppTextStyles.labelWithColor(
                            AppColors.textInverse,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 160),
                child: AnimatedScaleButton(
                  onTap: loading ? () {} : viewModel.signInWithGoogle,
                  child: OutlinedButton(
                    onPressed: loading ? null : viewModel.signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      side: const BorderSide(color: AppColors.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Image(
                          image: AssetImage('assets/images/google.png'),
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 10),
                        Text(
                          AppStrings.googleLogin,
                          style: AppTextStyles.labelWithColor(
                            AppColors.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () => ref
                            .read(sessionViewModelProvider.notifier)
                            .enterGuestBrowseMode(),
                  child: Text(
                    AppStrings.guestLogin,
                    style: AppTextStyles.bodyWithSize(
                      14,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedFadeSlide(
                delay: Duration(milliseconds: 240),
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: AppTextStyles.captionMuted,
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Terms of Service',
                        style: AppTextStyles.captionWithColor(
                          AppColors.textAccent,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.captionWithColor(
                          AppColors.textAccent,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
