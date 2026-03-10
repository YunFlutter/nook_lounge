import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_dialogs.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_inquiry_detail_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_inquiry_form_page.dart';

class SettingsInquiryListPage extends ConsumerWidget {
  const SettingsInquiryListPage({
    required this.uid,
    this.blockedAccessMode = false,
    this.allowAppealSubmission = false,
    super.key,
  });

  final String uid;
  final bool blockedAccessMode;
  final bool allowAppealSubmission;

  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(settingsInquiriesProvider(uid));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !blockedAccessMode,
        leading: blockedAccessMode
            ? null
            : IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: '뒤로가기',
              ),
        title: Text(blockedAccessMode ? '문의 내역 / 이의 신청' : '나의 문의 내역'),
        actions: blockedAccessMode
            ? <Widget>[
                TextButton(
                  onPressed: () => _signOut(context, ref),
                  child: Text('로그아웃', style: AppTextStyles.bodyPrimaryStrong),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: inquiriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '문의 내역을 불러오지 못했어요.\n$error',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ),
        data: (inquiries) {
          final visibleInquiries = blockedAccessMode
              ? inquiries.where(_isAppealInquiry).toList(growable: false)
              : inquiries;
          final receivedCount = visibleInquiries
              .where((e) => e.status == SupportInquiryStatus.received)
              .length;
          final processingCount = visibleInquiries
              .where((e) => e.status == SupportInquiryStatus.processing)
              .length;
          final completedCount = visibleInquiries
              .where((e) => e.status == SupportInquiryStatus.completed)
              .length;
          final primaryLabel = blockedAccessMode ? '이의접수' : '문의접수';

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.verticalGap,
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.horizontalPadding,
            ),
            children: <Widget>[
              if (blockedAccessMode) ...<Widget>[
                _blockedGuideCard(context),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    _summaryItem(primaryLabel, receivedCount),
                    _summaryItem('처리중', processingCount),
                    _summaryItem('처리완료', completedCount),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (blockedAccessMode) ...<Widget>[
                Text('이의 신청 내역', style: AppTextStyles.headingH3),
                const SizedBox(height: 10),
              ],
              if (visibleInquiries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    blockedAccessMode ? '이의 신청 내역이 없어요.' : '문의 내역이 없어요.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMutedStrong,
                  ),
                ),
              ...visibleInquiries.map(
                (inquiry) => _inquiryCard(context, inquiry),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryItem(String label, int count) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text('$count', style: AppTextStyles.headingH1),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.headingH3),
        ],
      ),
    );
  }

  Widget _inquiryCard(BuildContext context, SupportInquiry inquiry) {
    final statusBg = SettingsSeedData.inquiryStatusBackgroundColor(
      inquiry.status,
    );
    final statusTextColor = SettingsSeedData.inquiryStatusTextColor(
      inquiry.status,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: inquiry.title,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SettingsInquiryDetailPage(uid: uid, inquiry: inquiry),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(
                      SettingsUiTokens.chipRadius,
                    ),
                  ),
                  child: Text(
                    SettingsSeedData.inquiryStatusLabel(inquiry.status),
                    style: AppTextStyles.captionWithColor(
                      statusTextColor,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_isAppealInquiry(inquiry)) ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.badgeYellowBg,
                      borderRadius: BorderRadius.circular(
                        SettingsUiTokens.chipRadius,
                      ),
                    ),
                    child: Text(
                      '이의 신청',
                      style: AppTextStyles.captionWithColor(
                        AppColors.badgeYellowText,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        inquiry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingH3,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dateFormat.format(inquiry.createdAt),
                        style: AppTextStyles.captionMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blockedGuideCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('차단 상태 안내', style: AppTextStyles.headingH3),
          const SizedBox(height: 8),
          Text(
            '현재 차단 상태에서는 문의 내역 확인과 이의 신청만 가능합니다.',
            style: AppTextStyles.bodySecondaryStrong,
          ),
          if (allowAppealSubmission) ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _openAppealForm(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.settingsPrimaryButton,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('이의 신청하기'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isAppealInquiry(SupportInquiry inquiry) {
    if (inquiry.isAppeal) {
      return true;
    }

    final normalizedCategory = inquiry.category.trim();
    final normalizedTitle = inquiry.title.trim();

    // 유지보수 포인트:
    // appeal 타입 도입 전 저장된 기존 이의 신청은 정책 카테고리 + 제목 패턴으로만
    // 차단 전용 화면에 노출해 기존 사용자 기록이 사라지지 않게 합니다.
    return normalizedCategory == SettingsSeedData.supportCategoryPolicy &&
        normalizedTitle.contains('이의 신청');
  }

  Future<void> _openAppealForm(BuildContext context) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SettingsInquiryFormPage(
          uid: uid,
          initialCategory: SettingsSeedData.supportCategoryPolicy,
          initialTitle: '서비스 차단 이의 신청',
          pageTitle: '이의 신청하기',
          submitButtonLabel: '이의 신청 접수',
          titleHintText: '이의 신청 제목을 입력해주세요.',
          bodyHintText: '차단 사유에 대해 확인이 필요한 내용과 이의 신청 사유를 자세히 입력해주세요.',
          lockCategory: true,
          inquiryType: SupportInquiryType.appeal,
        ),
      ),
    );

    if (submitted != true || !context.mounted) {
      return;
    }

    await SettingsDialogs.showInquiryReceived(
      context: context,
      displayName: '고객',
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('로그아웃에 실패했어요.\n$error')));
    }
  }
}
