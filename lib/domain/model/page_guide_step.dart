import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';

class PageGuideStep {
  const PageGuideStep({
    required this.title,
    required this.description,
    this.icon = Icons.chevron_right_rounded,
    this.accentColor = AppColors.navActive,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
}
