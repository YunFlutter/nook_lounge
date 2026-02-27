import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/settings_faq_item.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_dialogs.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_inquiry_form_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_inquiry_list_page.dart';

class SettingsSupportCenterPage extends ConsumerStatefulWidget {
  const SettingsSupportCenterPage({
    required this.uid,
    required this.displayName,
    super.key,
  });

  final String uid;
  final String displayName;

  @override
  ConsumerState<SettingsSupportCenterPage> createState() =>
      _SettingsSupportCenterPageState();
}

class _SettingsSupportCenterPageState
    extends ConsumerState<SettingsSupportCenterPage> {
  String _selectedCategory = SettingsSeedData.supportCategories.first;
  String? _expandedFaqId;

  @override
  Widget build(BuildContext context) {
    final inquiriesAsync = ref.watch(settingsInquiriesProvider(widget.uid));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('고객센터'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.horizontalPadding,
        ),
        children: <Widget>[
          _inquirySummaryCard(context, inquiriesAsync.valueOrNull?.length ?? 0),
          const SizedBox(height: 16),
          Text(
            '무엇을 도와드릴까요?',
            style: AppTextStyles.bodyWithSize(
              42,
              color: AppColors.textSecondary,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _categoryChips(),
          const SizedBox(height: 14),
          ..._faqList(),
        ],
      ),
    );
  }

  Widget _inquirySummaryCard(BuildContext context, int inquiryCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              button: true,
              label: '나의 문의 내역',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsInquiryListPage(uid: widget.uid),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '$inquiryCount',
                        style: AppTextStyles.bodyWithSize(
                          48,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '나의 문의 내역',
                        style: AppTextStyles.bodyWithSize(
                          18,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _openInquiryForm,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderDefault),
                backgroundColor: AppColors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('1:1 문의하기', style: AppTextStyles.bodyPrimaryStrong),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SettingsSeedData.supportCategories
          .map((category) {
            final selected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(
                category,
                style: AppTextStyles.captionWithColor(
                  selected ? AppColors.accentDeepOrange : AppColors.textMuted,
                  weight: FontWeight.w800,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                  _expandedFaqId = null;
                });
              },
              selectedColor: AppColors.accentOrange,
              backgroundColor: AppColors.bgSecondary,
              side: BorderSide(
                color: selected
                    ? AppColors.accentOrange
                    : AppColors.borderDefault,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  SettingsUiTokens.chipRadius,
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  List<Widget> _faqList() {
    final filteredItems = SettingsSeedData.faqItems
        .where((item) => item.category == _selectedCategory)
        .toList(growable: false);

    return filteredItems.map((item) => _faqTile(item)).toList(growable: false);
  }

  Widget _faqTile(SettingsFaqItem item) {
    final expanded = _expandedFaqId == item.id;

    return Column(
      children: <Widget>[
        InkWell(
          onTap: () {
            setState(() {
              _expandedFaqId = expanded ? null : item.id;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.bgSecondary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Q',
                    style: AppTextStyles.bodyWithSize(
                      22,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.question,
                    style: AppTextStyles.bodyWithSize(
                      18,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textPrimary,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.answer,
              style: AppTextStyles.bodyWithSize(
                15,
                color: AppColors.black,
                weight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _openInquiryForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SettingsInquiryFormPage(uid: widget.uid),
      ),
    );

    if (submitted != true || !mounted) {
      return;
    }

    await SettingsDialogs.showInquiryReceived(
      context: context,
      displayName: widget.displayName,
    );
  }
}
