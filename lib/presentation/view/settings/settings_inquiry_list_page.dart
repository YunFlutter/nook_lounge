import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_inquiry_detail_page.dart';

class SettingsInquiryListPage extends ConsumerWidget {
  const SettingsInquiryListPage({required this.uid, super.key});

  final String uid;

  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(settingsInquiriesProvider(uid));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('나의 문의 내역'),
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
          final receivedCount = inquiries
              .where((e) => e.status == SupportInquiryStatus.received)
              .length;
          final processingCount = inquiries
              .where((e) => e.status == SupportInquiryStatus.processing)
              .length;
          final completedCount = inquiries
              .where((e) => e.status == SupportInquiryStatus.completed)
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.verticalGap,
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.horizontalPadding,
            ),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    _summaryItem('문의접수', receivedCount),
                    _summaryItem('처리중', processingCount),
                    _summaryItem('처리완료', completedCount),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (inquiries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '문의 내역이 없어요.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMutedStrong,
                  ),
                ),
              ...inquiries.map((inquiry) => _inquiryCard(context, inquiry)),
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
          Text(
            '$count',
            style: AppTextStyles.bodyWithSize(
              40,
              color: AppColors.textSecondary,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodyWithSize(
              18,
              color: AppColors.textSecondary,
              weight: FontWeight.w700,
            ),
          ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        inquiry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyWithSize(
                          18,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dateFormat.format(inquiry.createdAt),
                        style: AppTextStyles.bodyWithSize(
                          14,
                          color: AppColors.textMuted,
                          weight: FontWeight.w700,
                        ),
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
}
