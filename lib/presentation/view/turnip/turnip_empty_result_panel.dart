import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class TurnipEmptyResultPanel extends StatelessWidget {
  const TurnipEmptyResultPanel({super.key});

  // 유지보수 포인트:
  // 빈 상태 이미지 에셋이 변경되면 경로와 크기를 여기서 함께 관리합니다.
  static const String _noDataImageAssetPath = 'assets/images/no_data_image.png';
  static const double _noDataImageSize = 88;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Semantics(
            label: '무주식 데이터 없음 이미지',
            image: true,
            child: Image.asset(
              _noDataImageAssetPath,
              width: _noDataImageSize,
              height: _noDataImageSize,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            '데이터가 없어요.',
            style: AppTextStyles.bodyWithSize(
              16,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '일요일 매수가와 월~토 가격을 입력하고\n계산하기를 눌러주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyWithSize(
              13,
              color: AppColors.textHint,
              weight: FontWeight.w700,
              height: 1.5
            ),
          ),
        ],
      ),
    );
  }
}
