import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';

class AirportPurposeEditSheet extends StatefulWidget {
  const AirportPurposeEditSheet({
    required this.initialPurpose,
    required this.initialIntroMessage,
    super.key,
  });

  final AirportVisitPurpose initialPurpose;
  final String initialIntroMessage;

  @override
  State<AirportPurposeEditSheet> createState() =>
      _AirportPurposeEditSheetState();
}

class _AirportPurposeEditSheetState extends State<AirportPurposeEditSheet> {
  late AirportVisitPurpose _selectedPurpose;
  late final TextEditingController _introController;

  @override
  void initState() {
    super.initState();
    _selectedPurpose = widget.initialPurpose;
    _introController = TextEditingController(text: widget.initialIntroMessage);
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final intro = _introController.text.trim();
    if (intro.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('섬 소개를 입력해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    Navigator.of(context).pop((purpose: _selectedPurpose, introMessage: intro));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        18,
        AppSpacing.pageHorizontal,
        AppSpacing.s10 * 2,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '비행장을 여는 목적을 알려주세요!',
              style: AppTextStyles.headingH2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: AirportVisitPurpose.values
                  .map((purpose) {
                    final selected = purpose == _selectedPurpose;
                    return ChoiceChip(
                      label: Text(
                        purpose.label,
                        style: selected
                            ? AppTextStyles.captionInverseHeavy
                            : AppTextStyles.captionSecondary,
                      ),
                      selected: selected,
                      selectedColor: AppColors.primaryDefault,
                      backgroundColor: AppColors.catalogChipBg,
                      showCheckmark: false,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primaryDefault
                            : AppColors.borderDefault,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedPurpose = purpose;
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            Text('내 섬 소개', style: AppTextStyles.headingH3),
            const SizedBox(height: 10),
            TextField(
              controller: _introController,
              maxLines: 3,
              maxLength: 140,
              style: AppTextStyles.bodyPrimaryStrong,
              decoration: InputDecoration(
                hintText: '예) 너굴너굴섬에 놀러오세요!',
                hintStyle: AppTextStyles.bodyHintStrong,
                filled: true,
                fillColor: AppColors.badgeYellowBg,
                counterStyle: AppTextStyles.captionMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.badgeBlueText,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.badgeBlueText,
                foregroundColor: AppColors.textInverse,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
