import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/core/telemetry/app_page_route.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_names.dart';
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
  String _selectedCategory = '';
  String? _expandedFaqId;

  @override
  Widget build(BuildContext context) {
    final inquiriesAsync = ref.watch(settingsInquiriesProvider(widget.uid));
    final faqItemsAsync = ref.watch(settingsFaqItemsProvider);
    final faqItems = faqItemsAsync.valueOrNull ?? const <SettingsFaqItem>[];
    final categories = _resolveCategories(faqItems);
    final selectedCategory = _resolveSelectedCategory(categories);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text(
          '고객센터',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
          Text('무엇을 도와드릴까요?', style: AppTextStyles.headingH1),
          const SizedBox(height: 12),
          ..._faqSection(
            faqItemsAsync: faqItemsAsync,
            faqItems: faqItems,
            categories: categories,
            selectedCategory: selectedCategory,
          ),
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
              child: AppInkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  AppPageRoute<void>(
                    screenName: AppScreenNames.settingsInquiryList,
                    builder: (_) => SettingsInquiryListPage(uid: widget.uid),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: <Widget>[
                      Text('$inquiryCount', style: AppTextStyles.headingH1),
                      const SizedBox(height: 8),
                      Text('나의 문의 내역', style: AppTextStyles.headingH3),
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
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
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

  List<String> _resolveCategories(List<SettingsFaqItem> faqItems) {
    final categories = <String>[];
    for (final item in faqItems) {
      final category = item.category.trim();
      if (category.isEmpty || categories.contains(category)) {
        continue;
      }
      categories.add(category);
    }
    return categories;
  }

  String _resolveSelectedCategory(List<String> categories) {
    if (categories.isEmpty) {
      return '';
    }
    return categories.contains(_selectedCategory)
        ? _selectedCategory
        : categories.first;
  }

  List<Widget> _faqSection({
    required AsyncValue<List<SettingsFaqItem>> faqItemsAsync,
    required List<SettingsFaqItem> faqItems,
    required List<String> categories,
    required String selectedCategory,
  }) {
    if (faqItemsAsync.isLoading && faqItems.isEmpty) {
      return <Widget>[
        _faqStatusCard(
          title: 'FAQ를 불러오는 중입니다.',
          body: 'app_config/faqs 문서를 확인하고 있어요.',
          trailing: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    if (faqItemsAsync.hasError && faqItems.isEmpty) {
      return <Widget>[
        _faqStatusCard(title: 'FAQ를 불러오지 못했습니다.', body: '잠시 후 다시 확인해 주세요.'),
      ];
    }

    if (categories.isEmpty) {
      return <Widget>[
        _faqStatusCard(
          title: '등록된 FAQ가 없습니다.',
          body: 'app_config/faqs 의 active 항목을 표시합니다.',
        ),
      ];
    }

    return <Widget>[
      _categoryChips(categories, selectedCategory),
      const SizedBox(height: 14),
      ..._faqList(faqItems: faqItems, selectedCategory: selectedCategory),
    ];
  }

  Widget _faqStatusCard({
    required String title,
    required String body,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.headingH3),
                const SizedBox(height: 6),
                Text(body, style: AppTextStyles.bodySecondaryStrong),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _categoryChips(List<String> categories, String selectedCategory) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map((category) {
            final selected = selectedCategory == category;
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

  List<Widget> _faqList({
    required List<SettingsFaqItem> faqItems,
    required String selectedCategory,
  }) {
    final filteredItems = faqItems
        .where((item) => item.category == selectedCategory)
        .toList(growable: false);

    return filteredItems.map((item) => _faqTile(item)).toList(growable: false);
  }

  Widget _faqTile(SettingsFaqItem item) {
    final expanded = _expandedFaqId == item.id;

    return Column(
      children: <Widget>[
        AppInkWell(
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
                  child: Text('Q', style: AppTextStyles.headingH3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.question, style: AppTextStyles.headingH3),
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
            child: Text(item.answer, style: AppTextStyles.bodyPrimaryStrong),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _openInquiryForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      AppPageRoute<bool>(
        screenName: AppScreenNames.settingsInquiryForm,
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
