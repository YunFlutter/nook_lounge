import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_loading_donut.dart';

class TurnipLoadingPanel extends StatelessWidget {
  const TurnipLoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TurnipLoadingDonut(),
          SizedBox(height: 16),
          Text(
            '계산 중입니다. 잠시만 기다려주세요.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
