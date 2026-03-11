import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

enum MarketTradeRulesSheetAction { agree, cancelTrade }

class MarketTradeRulesViewSheet extends StatelessWidget {
  const MarketTradeRulesViewSheet({
    required this.rules,
    this.showAgreementActions = false,
    super.key,
  });

  final String rules;
  final bool showAgreementActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.s10,
        AppSpacing.pageHorizontal,
        AppSpacing.s20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.s22),
            Text('섬 방문 규칙', style: AppTextStyles.headingH1),
            const SizedBox(height: AppSpacing.s12),
            Text(
              '상대가 등록한 방문 규칙을 확인해 주세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondaryStrong,
            ),
            const SizedBox(height: AppSpacing.s20),
            SizedBox(
              width: double.infinity,
              child: Text(
                rules,
                style: AppTextStyles.bodySecondaryStrong.copyWith(height: 1.5),
                textAlign: TextAlign.left,
              ),
            ),
            if (showAgreementActions) ...<Widget>[
              const SizedBox(height: AppSpacing.s24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(MarketTradeRulesSheetAction.agree);
                },
                style: FilledButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  backgroundColor: AppColors.modalPrimaryAction,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text('동의하고 코드 확인', style: AppTextStyles.buttonPrimary),
              ),
              const SizedBox(height: AppSpacing.s10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(MarketTradeRulesSheetAction.cancelTrade);
                },
                style: OutlinedButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(
                    color: AppColors.badgeRedText,
                    width: 2,
                  ),
                  foregroundColor: AppColors.badgeRedText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  '동의하지 않고 거래 취소',
                  style: AppTextStyles.bodyWithSize(
                    16,
                    color: AppColors.badgeRedText,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
