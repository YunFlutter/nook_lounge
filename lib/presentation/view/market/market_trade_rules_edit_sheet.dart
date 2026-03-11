import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class MarketTradeRulesEditSheet extends StatefulWidget {
  const MarketTradeRulesEditSheet({required this.initialRules, super.key});

  final String initialRules;

  @override
  State<MarketTradeRulesEditSheet> createState() =>
      _MarketTradeRulesEditSheetState();
}

class _MarketTradeRulesEditSheetState extends State<MarketTradeRulesEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialRules);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final nextRules = _controller.text.trim();
    if (nextRules.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('섬 규칙을 한 줄 이상 입력해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    Navigator.of(context).pop(nextRules);
  }

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
              '상대가 동의한 뒤 코드를 확인할 수 있어요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondaryStrong,
            ),
            const SizedBox(height: AppSpacing.s18),
            Container(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: _controller,
                minLines: 8,
                maxLines: 12,
                textInputAction: TextInputAction.newline,
                cursorColor: AppColors.accentDeepOrange,
                style: AppTextStyles.bodySecondaryStrong.copyWith(height: 1.5),
                decoration: InputDecoration(
                  hintText: '예시)\n1. 꽃 밟지 않기\n2. 열매 따먹지 않기\n3. 게시판에 방문록 남기기',
                  hintStyle: AppTextStyles.bodyHintStrong.copyWith(height: 1.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.borderDefault,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.borderDefault,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.accentDeepOrange,
                      width: 2,
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            FilledButton(
              onPressed: _onSubmit,
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
              child: Text('규칙 저장하기', style: AppTextStyles.buttonPrimary),
            ),
            const SizedBox(height: AppSpacing.s10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size.fromHeight(56),
                side: const BorderSide(
                  color: AppColors.borderDefault,
                  width: 2,
                ),
                foregroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('취소', style: AppTextStyles.buttonSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
