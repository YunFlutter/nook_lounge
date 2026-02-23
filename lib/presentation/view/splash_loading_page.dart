import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';

class SplashLoadingPage extends StatefulWidget {
  const SplashLoadingPage({
    super.key,
    this.waitingForSession = true,
    this.onCompleted,
  });

  final bool waitingForSession;
  final VoidCallback? onCompleted;

  @override
  State<SplashLoadingPage> createState() => _SplashLoadingPageState();
}

class _SplashLoadingPageState extends State<SplashLoadingPage>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _floatController;
  bool _notifiedCompleted = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _progressController,
              _floatController,
            ]),
            builder: (context, child) {
              final progress = _progressController.value;
              final percentText = '${(progress * 100).round()}%';
              final floatOffset = (_floatController.value - 0.5) * 8;

              if (progress >= 1 &&
                  !_notifiedCompleted &&
                  widget.onCompleted != null) {
                _notifiedCompleted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    widget.onCompleted!.call();
                  }
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Spacer(flex: 2),
                  Transform.translate(
                    offset: Offset(0, floatOffset),
                    child: Image.asset(
                      'assets/images/splash.png',
                      width: size.width * 0.56,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nook Lounge',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingH1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '섬과 섬을 잇는 라운지',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelWithColor(
                      AppColors.textSecondary,
                      weight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.waitingForSession
                              ? '섬 데이터를 불러오는 중...'
                              : '로그인 화면으로 이동할게요.',
                          style: AppTextStyles.bodyWithSize(
                            14,
                            color: AppColors.textMuted,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        percentText,
                        style: AppTextStyles.bodyWithSize(
                          14,
                          color: AppColors.textAccent,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.borderDefault,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.textAccent,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    '© 2026 Project NL',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyWithSize(
                      14,
                      color: AppColors.textMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '본 앱은 팬 제작 비공식 서비스이며 Nintendo와 공식적인 관련이 없습니다.\nAnimal Crossing™은 Nintendo의 상표입니다.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyWithSize(
                      12,
                      color: AppColors.textMuted,
                      weight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
