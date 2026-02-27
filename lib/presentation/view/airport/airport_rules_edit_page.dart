import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class AirportRulesEditPage extends StatefulWidget {
  const AirportRulesEditPage({required this.initialRules, super.key});

  final String initialRules;

  @override
  State<AirportRulesEditPage> createState() => _AirportRulesEditPageState();
}

class _AirportRulesEditPageState extends State<AirportRulesEditPage> {
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

  void _onSave() {
    final nextRules = _controller.text.trim();
    if (nextRules.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('규칙을 한 줄 이상 입력해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    Navigator.of(context).pop(nextRules);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('섬 방문 규칙 작성하기'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.s10,
            AppSpacing.pageHorizontal,
            AppSpacing.s10 * 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 10),
              Text(
                '섬 방문 시 지켜야 할 규칙을 작성해 주세요.',
                style: AppTextStyles.captionMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderDefault),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: AppTextStyles.bodyPrimaryStrong,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: '예시)\n1. 꽃 밟지 않기\n2. 열매 따먹지 않기',
                      hintStyle: AppTextStyles.bodyHintStrong,
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.badgeBlueText,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('규칙 저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
