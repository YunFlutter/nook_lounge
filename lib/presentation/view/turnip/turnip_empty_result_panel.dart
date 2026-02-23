import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';

class TurnipEmptyResultPanel extends StatelessWidget {
  const TurnipEmptyResultPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.edit_note_rounded,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            '먼저 데이터를 입력해주세요.',
            style: AppTextStyles.bodyWithSize(
              16,
              color: AppColors.textMuted,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '일요일 매수가와 월요일 오전/오후 가격 입력 후\n계산하기를 눌러주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyWithSize(
              13,
              color: AppColors.textHint,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
