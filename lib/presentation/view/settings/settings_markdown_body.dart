import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/presentation/view/common/app_owl_empty_state.dart';

class SettingsMarkdownBody extends StatelessWidget {
  const SettingsMarkdownBody({required this.data, super.key});

  final String data;

  static const double _bodyFontSize = 16;
  static const double _heading1FontSize = 24;
  static const double _heading2FontSize = 20;
  static const double _heading3FontSize = 18;
  static const double _codeFontSize = 15;

  @override
  Widget build(BuildContext context) {
    final trimmedData = data.trim();
    if (trimmedData.isEmpty) {
      return const AppOwlEmptyState(
        imageSize: 72,
        title: '등록된 내용이 없어요.',
        subtitle: '관리자 등록 후 여기에 표시돼요.',
      );
    }

    final styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      // 유지보수 포인트:
      // 설정 문서/공지 공통 본문 톤을 여기서 맞추면
      // 약관, 개인정보처리방침, 공지사항 마크다운 스타일이 함께 정리됩니다.
      p: AppTextStyles.bodyWithSize(
        _bodyFontSize,
        color: AppColors.black,
        weight: FontWeight.w700,
        height: 1.5,
      ),
      h1: AppTextStyles.bodyWithSize(
        _heading1FontSize,
        color: AppColors.textPrimary,
        weight: FontWeight.w800,
        height: 1.3,
      ),
      h2: AppTextStyles.bodyWithSize(
        _heading2FontSize,
        color: AppColors.textPrimary,
        weight: FontWeight.w800,
        height: 1.35,
      ),
      h3: AppTextStyles.bodyWithSize(
        _heading3FontSize,
        color: AppColors.textPrimary,
        weight: FontWeight.w800,
        height: 1.4,
      ),
      a: AppTextStyles.bodyWithSize(
        _bodyFontSize,
        color: AppColors.primaryHover,
        weight: FontWeight.w800,
        height: 1.5,
      ).copyWith(decoration: TextDecoration.underline),
      listBullet: AppTextStyles.bodyWithSize(
        _bodyFontSize,
        color: AppColors.textPrimary,
        weight: FontWeight.w800,
        height: 1.5,
      ),
      blockquote: AppTextStyles.bodyWithSize(
        _bodyFontSize,
        color: AppColors.textSecondary,
        weight: FontWeight.w700,
        height: 1.5,
      ),
      code: AppTextStyles.bodyWithSize(
        _codeFontSize,
        color: AppColors.textPrimary,
        weight: FontWeight.w700,
        height: 1.4,
      ).copyWith(backgroundColor: AppColors.bgSecondary),
    );

    return MarkdownBody(
      data: trimmedData,
      selectable: true,
      softLineBreak: true,
      styleSheet: styleSheet,
    );
  }
}
