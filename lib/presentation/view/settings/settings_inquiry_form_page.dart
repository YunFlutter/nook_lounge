import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

class SettingsInquiryFormPage extends ConsumerStatefulWidget {
  const SettingsInquiryFormPage({
    required this.uid,
    this.initialCategory,
    this.initialTitle,
    this.pageTitle = '1:1 문의하기',
    this.submitButtonLabel = '문의 접수',
    this.titleHintText = '문의 제목을 입력해주세요.',
    this.bodyHintText = '문의하실 내용을 입력해주세요.',
    this.lockCategory = false,
    this.inquiryType = SupportInquiryType.general,
    super.key,
  });

  final String uid;
  final String? initialCategory;
  final String? initialTitle;
  final String pageTitle;
  final String submitButtonLabel;
  final String titleHintText;
  final String bodyHintText;
  final bool lockCategory;
  final SupportInquiryType inquiryType;

  @override
  ConsumerState<SettingsInquiryFormPage> createState() =>
      _SettingsInquiryFormPageState();
}

class _SettingsInquiryFormPageState
    extends ConsumerState<SettingsInquiryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late String _selectedCategory;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    final initialCategory = widget.initialCategory?.trim() ?? '';
    _selectedCategory =
        SettingsSeedData.supportCategories.contains(initialCategory)
        ? initialCategory
        : SettingsSeedData.supportCategories.first;

    final initialTitle = widget.initialTitle?.trim() ?? '';
    if (initialTitle.isNotEmpty) {
      _titleController.text = initialTitle;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: Text(widget.pageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.horizontalPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('문의 분류', style: AppTextStyles.bodyPrimaryStrong),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: SettingsSeedData.supportCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: AppTextStyles.bodyPrimaryStrong,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _submitting || widget.lockCategory
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
              ),
              const SizedBox(height: 14),
              Text('제목', style: AppTextStyles.bodyPrimaryStrong),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                enabled: !_submitting,
                decoration: InputDecoration(hintText: widget.titleHintText),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text('문의 내용', style: AppTextStyles.bodyPrimaryStrong),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                enabled: !_submitting,
                minLines: 7,
                maxLines: 12,
                decoration: InputDecoration(
                  hintText: widget.bodyHintText,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '문의 내용을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.settingsPrimaryButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    _submitting ? '접수 중...' : widget.submitButtonLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .createInquiry(
            uid: widget.uid,
            category: _selectedCategory,
            title: _titleController.text,
            body: _bodyController.text,
            type: widget.inquiryType,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('문의 접수에 실패했어요.\n$error')));
      setState(() {
        _submitting = false;
      });
    }
  }
}
