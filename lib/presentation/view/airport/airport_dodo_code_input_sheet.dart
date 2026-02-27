import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class AirportDodoCodeInputSheet extends StatefulWidget {
  const AirportDodoCodeInputSheet({required this.initialCode, super.key});

  final String initialCode;

  @override
  State<AirportDodoCodeInputSheet> createState() =>
      _AirportDodoCodeInputSheetState();
}

class _AirportDodoCodeInputSheetState extends State<AirportDodoCodeInputSheet> {
  static final RegExp _codePattern = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{5}$');

  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final code = _controller.text.trim().toUpperCase();
    if (!_codePattern.hasMatch(code)) {
      setState(() {
        _errorText = '영문 대문자+숫자 5자리로 입력해 주세요.';
      });
      return;
    }

    Navigator.of(context).pop(code);
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
        10,
        AppSpacing.pageHorizontal,
        AppSpacing.s10 * 2,
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
            const SizedBox(height: 22),
            Text('도도 코드 입력', style: AppTextStyles.headingH1),
            const SizedBox(height: 14),
            Text(
              '비행장에서 발급받은 5자리 코드를 입력해주세요.',
              style: AppTextStyles.bodySecondaryStrong,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderDefault),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.characters,
                maxLength: 5,
                textAlign: TextAlign.center,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(5),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final upper = newValue.text.toUpperCase();
                    return newValue.copyWith(
                      text: upper,
                      selection: TextSelection.collapsed(offset: upper.length),
                      composing: TextRange.empty,
                    );
                  }),
                ],
                style: AppTextStyles.bodyWithSize(
                  34,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: '- - - - -',
                  hintStyle: AppTextStyles.bodyWithSize(
                    34,
                    color: AppColors.textMuted,
                    weight: FontWeight.w800,
                  ),
                ),
                onChanged: (value) {
                  if (_errorText == null) {
                    return;
                  }
                  setState(() {
                    _errorText = null;
                  });
                },
              ),
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: AppTextStyles.captionWithColor(
                  AppColors.badgeRedText,
                  weight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 20),
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
              child: const Text('도도코드 등록하기'),
            ),
          ],
        ),
      ),
    );
  }
}
