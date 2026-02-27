import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

class SettingsInquiryDetailPage extends ConsumerStatefulWidget {
  const SettingsInquiryDetailPage({
    required this.uid,
    required this.inquiry,
    super.key,
  });

  final String uid;
  final SupportInquiry inquiry;

  @override
  ConsumerState<SettingsInquiryDetailPage> createState() =>
      _SettingsInquiryDetailPageState();
}

class _SettingsInquiryDetailPageState
    extends ConsumerState<SettingsInquiryDetailPage> {
  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final inquiry = widget.inquiry;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: Text(
          inquiry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _deleting ? null : _deleteInquiry,
            icon: const Icon(Icons.delete_rounded),
            tooltip: '문의 삭제',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.horizontalPadding,
        ),
        children: <Widget>[
          Text(
            inquiry.title,
            style: AppTextStyles.bodyWithSize(
              38,
              color: AppColors.textSecondary,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _dateFormat.format(inquiry.createdAt),
            style: AppTextStyles.bodyWithSize(
              14,
              color: AppColors.textMuted,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Text(
            inquiry.body,
            style: AppTextStyles.bodyWithSize(
              16,
              color: AppColors.black,
              weight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text('운영자 답변', style: AppTextStyles.headingH3),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _adminReplyOrFallback(inquiry),
              style: AppTextStyles.bodyWithSize(
                15,
                color: AppColors.black,
                weight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _adminReplyOrFallback(SupportInquiry inquiry) {
    final reply = inquiry.adminReply?.trim() ?? '';
    if (reply.isEmpty) {
      return '문의가 접수되어 확인 중입니다.\n빠르게 답변드릴게요.';
    }
    return reply;
  }

  Future<void> _deleteInquiry() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('문의를 삭제할까요?'),
          content: const Text('삭제된 문의는 복구할 수 없어요.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .deleteInquiry(uid: widget.uid, inquiryId: widget.inquiry.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('문의를 삭제했어요.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('문의 삭제에 실패했어요.\n$error')));
      setState(() {
        _deleting = false;
      });
    }
  }
}
