import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class IslandRulesEditSheet extends StatefulWidget {
  const IslandRulesEditSheet({
    required this.initialRules,
    required this.title,
    required this.subtitle,
    required this.hintText,
    required this.emptyRulesMessage,
    this.primaryButtonLabel = '규칙 저장하기',
    super.key,
  });

  final String initialRules;
  final String title;
  final String subtitle;
  final String hintText;
  final String emptyRulesMessage;
  final String primaryButtonLabel;

  static Future<String?> show({
    required BuildContext context,
    required String initialRules,
    required String title,
    required String subtitle,
    required String hintText,
    required String emptyRulesMessage,
    String primaryButtonLabel = '규칙 저장하기',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: IslandRulesEditSheet(
              initialRules: initialRules,
              title: title,
              subtitle: subtitle,
              hintText: hintText,
              emptyRulesMessage: emptyRulesMessage,
              primaryButtonLabel: primaryButtonLabel,
            ),
          ),
        );
      },
    );
  }

  @override
  State<IslandRulesEditSheet> createState() => _IslandRulesEditSheetState();
}

class _IslandRulesEditSheetState extends State<IslandRulesEditSheet> {
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
          SnackBar(
            content: Text(widget.emptyRulesMessage),
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
            Text(widget.title, style: AppTextStyles.headingH1),
            const SizedBox(height: AppSpacing.s12),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondaryStrong,
            ),
            const SizedBox(height: AppSpacing.s18),
            // 유지보수 포인트:
            // 공항/마켓이 같은 규칙 편집 시트를 재사용하므로
            // 입력창 토큰은 여기서만 조정하면 두 화면이 함께 맞춰집니다.
            TextField(
              controller: _controller,
              minLines: 8,
              maxLines: 12,
              textInputAction: TextInputAction.newline,
              cursorColor: AppColors.accentDeepOrange,
              style: AppTextStyles.bodySecondaryStrong.copyWith(height: 1.5),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.bodyHintStrong.copyWith(height: 1.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
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
              child: Text(
                widget.primaryButtonLabel,
                style: AppTextStyles.buttonPrimary,
              ),
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
