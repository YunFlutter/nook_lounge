import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/app/theme/passport_palette.dart';
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
  /// 유지보수 포인트:
  /// 과거 spotlight 애니메이션 제거 이후 hot-reload 상황에서 ticker 누수가 남을 수 있어
  /// 레거시 컨트롤러를 안전하게 정리하기 위해 nullable로 유지합니다.
  AnimationController? _spotlightController;
  late final AnimationController _confettiController;
  bool _isEnteringIsland = false;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void reassemble() {
    super.reassemble();
    // hot-reload 시 과거 상태의 ticker 누수가 있으면 즉시 정리합니다.
    _spotlightController?.dispose();
    _spotlightController = null;
  }

  @override
  void dispose() {
    _spotlightController?.dispose();
    _spotlightController = null;
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
      backgroundColor: PassportPalette.pageBackground,
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
                  56,
                  color: PassportPalette.titleAccent,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              Expanded(
                flex: 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
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
                  40,
                  color: PassportPalette.welcomeAccent,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.s10 * 5),
              // Expanded(child: SizedBox()),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: PassportPalette.shadowStrong,
                      blurRadius: 1,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: _isEnteringIsland
                      ? null
                      : () async {
                          setState(() {
                            _isEnteringIsland = true;
                          });

                          try {
                            await widget.onEnterIsland();
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop(true);
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text('입장에 실패했어요.\n$error')),
                              );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isEnteringIsland = false;
                              });
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    minimumSize: const Size.fromHeight(60),
                    backgroundColor: PassportPalette.actionGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _isEnteringIsland ? '입장 중...' : '섬으로 입장하기',
                    style: AppTextStyles.buttonPrimary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.s10 * 7),
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

  /// 유지보수 포인트:
  /// 여권 카드 입체감(그림자 깊이/퍼짐)을 조절할 때 아래 상수만 변경하면 됩니다.
  static const double _cardCornerRadius = 16;
  static const double _castShadowInset = 18;
  static const double _castShadowHeight = 34;
  static const double _castShadowOffset = 16;

  final double width;
  final CreateIslandDraft draft;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final cardBorderRadius = BorderRadius.circular(_cardCornerRadius);

    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: _castShadowInset,
            right: _castShadowInset,
            bottom: -_castShadowOffset,
            child: IgnorePointer(
              child: Container(
                height: _castShadowHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_cardCornerRadius + 8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      PassportPalette.shadowMedium.withValues(alpha: 0.16),
                      PassportPalette.shadowSoft.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color.lerp(
                    PassportPalette.cardDetailBackground,
                    Colors.white,
                    0.10,
                  )!,
                  PassportPalette.cardDetailBackground,
                ],
                stops: const <double>[0, 0.45],
              ),
              borderRadius: cardBorderRadius,
              border: Border.all(color: PassportPalette.cardBorder, width: 5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: PassportPalette.shadowMedium.withValues(alpha: 0.22),
                  blurRadius: 34,
                  spreadRadius: 0.4,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: PassportPalette.shadowSoft.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.36),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(0, -1),
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
                    color: PassportPalette.cardHeaderBackground,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        SizedBox(width: 6),
                        Expanded(
                          child: Divider(
                            color: PassportPalette.textPrimary,
                            thickness: 1.6,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PASSPORT',
                          style: AppTextStyles.bodyWithSize(
                            16,
                            color: PassportPalette.textPrimary,
                            weight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Divider(
                            color: PassportPalette.textPrimary,
                            thickness: 1.6,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
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
                                  14,
                                  color: PassportPalette.textSecondary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                draft.islandName,
                                style: AppTextStyles.bodyWithSize(
                                  18,
                                  color: PassportPalette.textPrimary,
                                  weight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '주민 이름:',
                                style: AppTextStyles.bodyWithSize(
                                  14,
                                  color: PassportPalette.textSecondary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                draft.representativeName,
                                style: AppTextStyles.bodyWithSize(
                                  18,
                                  color: PassportPalette.textPrimary,
                                  weight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _FruitBadge(fruitName: draft.nativeFruit),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
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
        color: PassportPalette.photoBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PassportPalette.photoBorder),
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
        const SizedBox(width: 10),
        Text(
          icon,
          style: AppTextStyles.bodyWithSize(
            30,
            color: PassportPalette.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          children: [
            Text(
              '특산물:',
              style: AppTextStyles.bodyWithSize(
                14,
                color: PassportPalette.textSecondary,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fruitName,
              style: AppTextStyles.bodyWithSize(
                18,
                color: PassportPalette.textPrimary,
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
      PassportPalette.confettiPurple,
      PassportPalette.confettiMint,
      PassportPalette.confettiYellow,
      PassportPalette.confettiBlue,
      PassportPalette.confettiOrange,
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
        ringPaint.color = PassportPalette.burstGlow.withValues(
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
