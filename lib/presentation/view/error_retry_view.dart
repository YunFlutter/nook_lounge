import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.s10 * 2,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.modalInner),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    'assets/images/error_image.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppSpacing.s10 + 2),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingH2,
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyWithSize(
                      14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s10 * 2),
                  FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
