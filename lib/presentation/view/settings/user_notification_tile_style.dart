import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';

class UserNotificationTileStyle {
  const UserNotificationTileStyle({
    required this.icon,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final IconData icon;
  final Color badgeBackground;
  final Color badgeForeground;

  factory UserNotificationTileStyle.from(MarketUserNotification notification) {
    if (notification.isTradeProposal) {
      return const UserNotificationTileStyle(
        icon: Icons.mail_outline_rounded,
        badgeBackground: AppColors.badgeMintBg,
        badgeForeground: AppColors.badgeMintText,
      );
    }

    if (notification.isTradeAccept) {
      return const UserNotificationTileStyle(
        icon: Icons.handshake_outlined,
        badgeBackground: AppColors.badgeBlueBg,
        badgeForeground: AppColors.badgeBlueText,
      );
    }

    if (notification.isTradeCode) {
      return const UserNotificationTileStyle(
        icon: Icons.pin_outlined,
        badgeBackground: AppColors.badgeYellowBg,
        badgeForeground: AppColors.badgeYellowText,
      );
    }

    if (notification.isTradeCancel) {
      return const UserNotificationTileStyle(
        icon: Icons.cancel_outlined,
        badgeBackground: AppColors.badgeRedBg,
        badgeForeground: AppColors.badgeRedText,
      );
    }

    return const UserNotificationTileStyle(
      icon: Icons.notifications_none_rounded,
      badgeBackground: AppColors.bgSecondary,
      badgeForeground: AppColors.textMuted,
    );
  }
}
