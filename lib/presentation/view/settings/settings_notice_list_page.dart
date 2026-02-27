import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_notice_detail_page.dart';

class SettingsNoticeListPage extends ConsumerWidget {
  const SettingsNoticeListPage({super.key});

  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(settingsNoticesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('공지사항'),
      ),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '공지사항을 불러오지 못했어요.\n$error',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ),
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Text(
                '등록된 공지사항이 없어요.',
                style: AppTextStyles.bodyMutedStrong,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.verticalGap,
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.verticalGap,
            ),
            itemBuilder: (context, index) {
              final notice = notices[index];
              return _noticeTile(context, notice);
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: notices.length,
          );
        },
      ),
    );
  }

  Widget _noticeTile(BuildContext context, SettingsNotice notice) {
    return Semantics(
      button: true,
      label: notice.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(SettingsUiTokens.tileRadius),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SettingsNoticeDetailPage(notice: notice),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                notice.title,
                style: AppTextStyles.bodyWithSize(
                  22,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _dateFormat.format(notice.publishedAt),
                style: AppTextStyles.bodyWithSize(
                  14,
                  color: AppColors.textMuted,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
