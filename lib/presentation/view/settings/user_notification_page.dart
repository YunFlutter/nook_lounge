import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_detail_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/user_notification_list_tile.dart';

class UserNotificationPage extends ConsumerStatefulWidget {
  const UserNotificationPage({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<UserNotificationPage> createState() =>
      _UserNotificationPageState();
}

class _UserNotificationPageState extends ConsumerState<UserNotificationPage> {
  bool _markingAllRead = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(
      marketUserNotificationsProvider(widget.uid),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('알림'),
        actions: <Widget>[
          notificationsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (notifications) {
              final unreadCount = notifications.where((e) => !e.isRead).length;
              return TextButton(
                onPressed: _markingAllRead || unreadCount == 0
                    ? null
                    : () => _markAllAsRead(notifications),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  textStyle: AppTextStyles.captionSecondary,
                ),
                child: Text(_markingAllRead ? '처리중...' : '모두 읽음'),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '알림을 불러오지 못했어요.\n$error',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Text('도착한 알림이 없어요.', style: AppTextStyles.bodyMutedStrong),
            );
          }

          final sortedNotifications = notifications.toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(marketUserNotificationsProvider(widget.uid));
              await ref.read(
                marketUserNotificationsProvider(widget.uid).future,
              );
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemBuilder: (context, index) {
                final notification = sortedNotifications[index];
                return UserNotificationListTile(
                  notification: notification,
                  onTap: () => _openNotification(context, notification),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: sortedNotifications.length,
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead(
    List<MarketUserNotification> notifications,
  ) async {
    final unread = notifications
        .where((e) => !e.isRead)
        .toList(growable: false);
    if (unread.isEmpty) {
      return;
    }

    setState(() {
      _markingAllRead = true;
    });

    try {
      await Future.wait<void>(
        unread.map(
          (notification) => ref
              .read(marketRepositoryProvider)
              .markUserNotificationRead(
                uid: widget.uid,
                notificationId: notification.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('모든 알림을 읽음 처리했어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('알림 읽음 처리에 실패했어요.\n$error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _markingAllRead = false;
        });
      }
    }
  }

  Future<void> _openNotification(
    BuildContext context,
    MarketUserNotification notification,
  ) async {
    try {
      if (!notification.isRead) {
        await ref
            .read(marketRepositoryProvider)
            .markUserNotificationRead(
              uid: widget.uid,
              notificationId: notification.id,
            );
      }

      final offerId = notification.offerId.trim();
      if (offerId.isEmpty || !context.mounted) {
        return;
      }

      final offer = await ref
          .read(marketRepositoryProvider)
          .fetchOfferById(offerId);
      if (!context.mounted) {
        return;
      }

      if (offer == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('연결된 거래글을 찾을 수 없어요.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MarketOfferDetailPage(offer: offer),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('알림을 여는 중 오류가 발생했어요.\n$error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
