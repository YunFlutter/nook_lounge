import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';

class SettingsDocumentPage extends ConsumerWidget {
  const SettingsDocumentPage({required this.type, super.key});

  final SettingsDocumentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(settingsDocumentProvider(type));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: Text(type.defaultTitle),
      ),
      body: documentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '${type.defaultTitle} 문서를 불러오지 못했어요.\n$error',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ),
        data: (document) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.verticalGap,
              SettingsUiTokens.horizontalPadding,
              SettingsUiTokens.verticalGap * 2,
            ),
            children: <Widget>[
              Text(
                document.body,
                style: AppTextStyles.bodyWithSize(
                  16,
                  color: AppColors.black,
                  weight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
