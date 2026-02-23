import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/domain/model/create_island_draft.dart';

class PassportIssuedPage extends StatefulWidget {
  const PassportIssuedPage({
    required this.draft,
    required this.onEnterIsland,
    super.key,
    this.imagePath,
  });

  final CreateIslandDraft draft;
  final String? imagePath;
  final Future<void> Function() onEnterIsland;

  @override
  State<PassportIssuedPage> createState() => _PassportIssuedPageState();
}

class _PassportIssuedPageState extends State<PassportIssuedPage>
    with TickerProviderStateMixin {
  late final AnimationController _spotlightController;
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();

    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(
      330.0,
      screenWidth - (AppSpacing.pageHorizontal * 2),
    );

    return Scaffold(
      backgroundColor: AppColors.passportPageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Column(
            children: <Widget>[
              Expanded(child: SizedBox()),
              Text(
                '여권 발급 완료!',
                style: AppTextStyles.bodyWithSize(
                  48,
                  color: AppColors.passportTitleBlue,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              Expanded(
                flex: 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CustomPaint(
                      size: const Size(380, 380),
                      painter: _SpotlightPainter(_spotlightController.value),
                    ),
                    AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, child) {
                        return IgnorePointer(
                          child: CustomPaint(
                            size: Size(screenWidth, 450),
                            painter: _ConfettiPainter(
                              _confettiController.value,
                            ),
                          ),
                        );
                      },
                    ),
                    _PassportCard(
                      width: cardWidth,
                      draft: widget.draft,
                      imagePath: widget.imagePath,
                    ),
                  ],
                ),
              ),
              Text(
                '환영합니다!',
                style: AppTextStyles.bodyWithSize(
                  32,
                  color: AppColors.passportWelcomePurple,
                  weight: FontWeight.w800,
                ),
              ),
              Expanded(child: SizedBox()),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowStrong,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () async {
                    await widget.onEnterIsland();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: AppColors.primaryDefault,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    '섬으로 입장하기',
                    style: AppTextStyles.buttonPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s10 * 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({
    required this.width,
    required this.draft,
    this.imagePath,
  });

  final double width;
  final CreateIslandDraft draft;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.passportCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.passportCardBorder, width: 5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              color: AppColors.passportCardHeaderBg,
            ),
            child: Row(
              children: <Widget>[
                SizedBox(width: 6),
                Expanded(
                  child: Divider(
                    color: AppColors.passportLine,
                    thickness: 1.6,
                    height: 1,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'PASSPORT',
                  style: AppTextStyles.bodyWithSize(
                    16,
                    color: AppColors.passportTextTitle,
                    weight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Divider(
                    color: AppColors.passportLine,
                    thickness: 1.6,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s10),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PassportPhoto(imagePath: imagePath),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '섬 이름:',
                          style: AppTextStyles.bodyWithSize(
                            12,
                            color: AppColors.passportTextSub,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          draft.islandName,
                          style: AppTextStyles.bodyWithSize(
                            16,
                            color: AppColors.passportTextMain,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '주민 이름:',
                          style: AppTextStyles.bodyWithSize(
                            12,
                            color: AppColors.passportTextSub,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          draft.representativeName,
                          style: AppTextStyles.bodyWithSize(
                            16,
                            color: AppColors.passportTextMain,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FruitBadge(fruitName: draft.nativeFruit),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportPhoto extends StatelessWidget {
  const _PassportPhoto({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        color: AppColors.passportPhotoBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.passportPhotoBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imagePath != null
            ? Image.file(File(imagePath!), fit: BoxFit.cover)
            : Image.asset('assets/images/login.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _FruitBadge extends StatelessWidget {
  const _FruitBadge({required this.fruitName});

  final String fruitName;

  @override
  Widget build(BuildContext context) {
    final icon = _fruitEmojiByName[fruitName] ?? '🍀';

    return Row(
      children: [
        Text(
          icon,
          style: AppTextStyles.bodyWithSize(
            30,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          children: [
            Text(
              '특산물:',
              style: AppTextStyles.bodyWithSize(
                12,
                color: AppColors.passportTextSub,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fruitName,
              style: AppTextStyles.bodyWithSize(
                14,
                color: AppColors.passportTextMain,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const Map<String, String> _fruitEmojiByName = <String, String>{
    '사과': '🍎',
    '체리': '🍒',
    '오렌지': '🍊',
    '복숭아': '🍑',
    '배': '🍐',
  };
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppColors.passportSpotGlow.withValues(alpha: 0.74),
          AppColors.passportSpotGlow.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * 0.92, glowPaint);

    final rayPaint = Paint()..style = PaintingStyle.fill;
    const rayCount = 20;
    final rotation = progress * math.pi * 2;

    for (var i = 0; i < rayCount; i++) {
      final startAngle = (i / rayCount) * math.pi * 2 + rotation;
      final sweep = (math.pi * 2 / rayCount) * 0.55;

      final alpha = i.isEven ? 0.14 : 0.07;
      rayPaint.color = AppColors.passportSpotRay.withValues(alpha: alpha);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    const colors = <Color>[
      AppColors.confettiPurple,
      AppColors.confettiMint,
      AppColors.confettiYellow,
      AppColors.confettiBlue,
      AppColors.confettiOrange,
    ];

    final burstOrigins = <Offset>[
      Offset(size.width * 0.22, size.height * 0.26),
      Offset(size.width * 0.5, size.height * 0.18),
      Offset(size.width * 0.78, size.height * 0.26),
    ];

    for (var burstIndex = 0; burstIndex < burstOrigins.length; burstIndex++) {
      final burstStart = burstIndex * 0.22;
      final local = _looped(progress - burstStart);
      if (local > 0.58) {
        continue;
      }

      final life = (local / 0.58).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(life);
      final alpha = (1 - life).clamp(0.0, 1.0);
      final origin = burstOrigins[burstIndex];

      if (local < 0.12) {
        final ringRadius = 8 + (local / 0.12) * 30;
        ringPaint.color = AppColors.passportBurstGlow.withValues(
          alpha: 1 - (local / 0.12),
        );
        canvas.drawCircle(origin, ringRadius, ringPaint);
      }

      const particleCount = 24;
      for (var i = 0; i < particleCount; i++) {
        final seed = (burstIndex * 97 + i * 13).toDouble();
        final angle =
            _fract(math.sin(seed * 12.9898) * 43758.5453) * math.pi * 2;
        final speed = 45 + _fract(math.sin(seed * 71.31) * 15731.743) * 210;
        final spin = (_fract(math.sin(seed * 29.53) * 951.135) - 0.5) * 3.4;

        final dx = math.cos(angle) * speed * eased;
        final dy =
            math.sin(angle) * speed * eased +
            (220 + (i % 5) * 18) * life * life * 0.36;

        final width = 6.0 + (i % 3) * 2.0;
        final height = 5.0 + (i % 2) * 2.0;

        particlePaint.color = colors[(i + burstIndex) % colors.length]
            .withValues(alpha: alpha * 0.96);

        canvas.save();
        canvas.translate(origin.dx + dx, origin.dy + dy);
        canvas.rotate(spin + life * 8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: width, height: height),
            const Radius.circular(2),
          ),
          particlePaint,
        );
        canvas.restore();
      }
    }
  }

  double _looped(double value) {
    final normalized = value % 1;
    return normalized < 0 ? normalized + 1 : normalized;
  }

  double _fract(double value) => value - value.floorToDouble();

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
