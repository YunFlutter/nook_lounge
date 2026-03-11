import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_markdown_body.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_notice_pinned_badge.dart';

class SettingsNoticeDetailPage extends StatelessWidget {
  const SettingsNoticeDetailPage({required this.notice, super.key});

  final SettingsNotice notice;

  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text(
          '공지사항',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap * 2,
        ),
        children: <Widget>[
          if (notice.pinned) ...<Widget>[
            const SettingsNoticePinnedBadge(),
            const SizedBox(height: 12),
          ],
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
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 16),
          SettingsMarkdownBody(data: notice.body),
        ],
      ),
    );
  }
}
