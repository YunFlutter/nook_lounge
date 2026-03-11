import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';

const String _nookipediaUrl = 'https://nookipedia.com/';
const String _turnipProphetUrl = 'https://turnipprophet.io/';
const double _cardGap = 14;
const double _cardInnerGap = 10;
const double _footerGap = 16;

class SettingsAttributionPage extends StatelessWidget {
  const SettingsAttributionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('저작권 및 출처'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SettingsUiTokens.horizontalPadding,
            SettingsUiTokens.verticalGap,
            SettingsUiTokens.horizontalPadding,
            SettingsUiTokens.verticalGap * 2,
          ),
          children: <Widget>[
            Text(
              '앱에서 사용하는 외부 데이터와 참고 서비스를 안내합니다.',
              style: AppTextStyles.headingH3,
            ),
            const SizedBox(height: SettingsUiTokens.sectionGap),
            _sourceCard(
              title: 'Nookipedia API',
              body:
                  'Nook Lounge는 Nookipedia API를 사용하고 있으며, 앱 내 일부 사진과 정보는 Nookipedia에서 가져왔습니다.',
              sourceLabel: '출처',
              sourceValue: _nookipediaUrl,
            ),
            const SizedBox(height: _cardGap),
            _sourceCard(
              title: '무주식 계산기',
              body:
                  '무주식 계산기는 Turnip Prophet을 바탕으로 제작했으며, 계산 흐름과 참고 기준을 해당 서비스에 기반해 구성했습니다.',
              sourceLabel: '기반 서비스',
              sourceValue: _turnipProphetUrl,
            ),
            const SizedBox(height: SettingsUiTokens.sectionGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SettingsUiTokens.horizontalPadding),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(
                  SettingsUiTokens.cardRadius,
                ),
              ),
              child: Text(
                '관련 사진, 정보, 상표 및 저작물의 권리는 각 권리자에게 있습니다.',
                style: AppTextStyles.bodySecondaryStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceCard({
    required String title,
    required String body,
    required String sourceLabel,
    required String sourceValue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SettingsUiTokens.horizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(SettingsUiTokens.cardRadius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTextStyles.headingH3),
          const SizedBox(height: _cardInnerGap),
          Text(
            body,
            style: AppTextStyles.bodyWithSize(
              16,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: _footerGap),
          Text(sourceLabel, style: AppTextStyles.captionMuted),
          const SizedBox(height: 4),
          Semantics(
            label: '$title 출처 주소 $sourceValue',
            child: Text(
              sourceValue,
              style: AppTextStyles.bodyWithSize(
                15,
                color: AppColors.primaryHover,
                weight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
