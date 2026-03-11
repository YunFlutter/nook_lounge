import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class AppOwlEmptyState extends StatelessWidget {
  const AppOwlEmptyState({
    required this.title,
    this.subtitle,
    this.action,
    this.imageSemanticLabel = '데이터 없음 이미지',
    this.imageSize = 88,
    this.useCard = true,
    this.expand = true,
    this.minHeight,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s20,
      vertical: AppSpacing.s28,
    ),
    super.key,
  });

  // 유지보수 포인트:
  // "데이터 없음" 연출은 이 위젯으로 통일합니다.
  // 에셋이나 기본 간격이 바뀌면 여기만 수정하면 됩니다.
  static const String _owlAssetPath = 'assets/images/no_data_image.png';

  final String title;
  final String? subtitle;
  final Widget? action;
  final String imageSemanticLabel;
  final double imageSize;
  final bool useCard;
  final bool expand;
  final double? minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget child = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                label: imageSemanticLabel,
                image: true,
                child: Image.asset(
                  _owlAssetPath,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyWithSize(
                  18,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyWithSize(
                    14,
                    color: AppColors.textMuted,
                    weight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: AppSpacing.s20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );

    if (useCard) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: child,
      );
    }

    if (expand) {
      child = SizedBox(width: double.infinity, child: child);
    }

    return child;
  }
}
