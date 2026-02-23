import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_detail_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_send_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_view_page.dart';

class MarketRealtimeListener extends ConsumerStatefulWidget {
  const MarketRealtimeListener({
    required this.uid,
    required this.child,
    super.key,
  });

  final String uid;
  final Widget child;

  @override
  ConsumerState<MarketRealtimeListener> createState() =>
      _MarketRealtimeListenerState();
}

class _MarketRealtimeListenerState
    extends ConsumerState<MarketRealtimeListener> {
  final Queue<MarketUserNotification> _pendingQueue =
      Queue<MarketUserNotification>();
  final Set<String> _handledNotificationIds = <String>{};
  bool _isHandlingNotification = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<MarketUserNotification>>>(
      marketUserNotificationsProvider(widget.uid),
      (previous, next) {
        next.whenData(_enqueueNotifications);
      },
    );
    return widget.child;
  }

  void _enqueueNotifications(List<MarketUserNotification> notifications) {
    if (!mounted) {
      return;
    }
    for (final notification in notifications) {
      if (notification.isRead) {
        continue;
      }
      if (!notification.isTradeAccept &&
          !notification.isTradeCode &&
          !notification.isTradeProposal &&
          !notification.isTradeCancel) {
        continue;
      }
      if (_handledNotificationIds.contains(notification.id)) {
        continue;
      }
      _handledNotificationIds.add(notification.id);
      _pendingQueue.add(notification);
    }
    _handleNextNotification();
  }

  Future<void> _handleNextNotification() async {
    if (!mounted || _isHandlingNotification || _pendingQueue.isEmpty) {
      return;
    }
    _isHandlingNotification = true;

    try {
      while (mounted && _pendingQueue.isNotEmpty) {
        final notification = _pendingQueue.removeFirst();
        await _showNotificationModal(notification);
        await _markAsRead(notification.id);
      }
    } finally {
      _isHandlingNotification = false;
    }
  }

  Future<void> _showNotificationModal(
    MarketUserNotification notification,
  ) async {
    if (!mounted) {
      return;
    }

    if (notification.isTradeProposal) {
      await _showProposalNotificationDialog(notification);
      return;
    }

    final offer = await ref
        .read(marketRepositoryProvider)
        .fetchOfferById(notification.offerId);
    final session = notification.offerId.trim().isEmpty
        ? null
        : await ref
              .read(marketRepositoryProvider)
              .fetchTradeCodeSession(notification.offerId);
    if (!mounted) {
      return;
    }

    if (notification.isTradeAccept) {
      await _showAcceptNotificationDialog(
        notification: notification,
        offer: offer,
        session: session,
      );
      return;
    }

    if (notification.isTradeCode) {
      await _showCodeNotificationDialog(
        notification: notification,
        offer: offer,
        session: session,
      );
      return;
    }

    if (notification.isTradeCancel) {
      await _showCancelNotificationDialog(
        notification: notification,
        offer: offer,
      );
    }
  }

  Future<void> _showProposalNotificationDialog(
    MarketUserNotification notification,
  ) async {
    final action = await _showRealtimeDialog(
      title: notification.title.isEmpty ? '새 거래 제안' : notification.title,
      message: notification.body.isEmpty
          ? '거래 제안이 도착했어요. 확인해 보세요.'
          : notification.body,
      confirmLabel: '바로 승낙',
      cancelLabel: '대기열 확인',
    );
    if (action == null || !mounted) {
      return;
    }

    // 유지보수 포인트:
    // 요청사항에 맞춰 실시간 모달에서 바로 승낙할 수 있게 분기합니다.
    // 취소(좌측 버튼)는 대기열 확인으로 연결해 기존 큐 선택 UX를 유지합니다.
    if (action == false) {
      await _openOfferDetail(notification.offerId);
      return;
    }

    await _acceptFromRealtimeProposal(notification);
  }

  Future<void> _acceptFromRealtimeProposal(
    MarketUserNotification notification,
  ) async {
    final proposerUid = notification.senderUid.trim();
    if (proposerUid.isEmpty) {
      await _openOfferDetail(notification.offerId);
      return;
    }

    final offer = await ref
        .read(marketRepositoryProvider)
        .fetchOfferById(notification.offerId);
    if (!mounted || offer == null) {
      return;
    }

    final currentUid = ref
        .read(marketViewModelProvider.notifier)
        .currentUserId
        .trim();
    if (currentUid.isEmpty || offer.ownerUid.trim() != currentUid) {
      // 작성자가 아니거나 세션이 바뀐 경우 안전하게 상세로만 이동
      await _openOfferDetail(notification.offerId);
      return;
    }

    late final MarketTradeCodeSession session;
    late final bool shouldSendCode;
    try {
      final result = await ref
          .read(marketViewModelProvider.notifier)
          .acceptTradeProposalAsOwner(offer: offer, proposerUid: proposerUid);
      session = result.session;
      shouldSendCode = result.shouldSendCode;
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('실시간 승낙 처리에 실패했어요. 대기열에서 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      await _openOfferDetail(notification.offerId);
      return;
    }

    if (!mounted) {
      return;
    }

    if (shouldSendCode) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              MarketTradeCodeSendPage(offer: offer, session: session),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketTradeCodeViewPage(offer: offer),
      ),
    );
  }

  Future<void> _showAcceptNotificationDialog({
    required MarketUserNotification notification,
    required MarketOffer? offer,
    required MarketTradeCodeSession? session,
  }) async {
    final currentUid = ref
        .read(marketViewModelProvider.notifier)
        .currentUserId
        .trim();
    final shouldInputCode = session?.isCodeSender(currentUid) ?? false;
    final confirmLabel = shouldInputCode ? '코드 입력하기' : '코드 확인하기';

    final shouldOpen = await _showRealtimeDialog(
      title: notification.title.isEmpty ? '거래가 승낙되었어요' : notification.title,
      message: notification.body.isEmpty
          ? '승낙이 도착했어요. 지금 거래를 진행해 주세요.'
          : notification.body,
      confirmLabel: confirmLabel,
      cancelLabel: '닫기',
    );
    if (shouldOpen != true || !mounted || offer == null) {
      return;
    }

    if (shouldInputCode && session != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              MarketTradeCodeSendPage(offer: offer, session: session),
        ),
      );
      return;
    }

    if (session != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MarketTradeCodeViewPage(offer: offer),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketOfferDetailPage(offer: offer),
      ),
    );
  }

  Future<void> _showCodeNotificationDialog({
    required MarketUserNotification notification,
    required MarketOffer? offer,
    required MarketTradeCodeSession? session,
  }) async {
    final tradeCode = notification.tradeCode.trim().isNotEmpty
        ? notification.tradeCode.trim()
        : (session?.code.trim() ?? '');
    final codeMessage = tradeCode.isEmpty ? '' : '\n도도 코드: $tradeCode';
    final shouldComplete = await _showRealtimeDialog(
      title: notification.title.isEmpty ? '도도 코드가 도착했어요' : notification.title,
      message:
          '${notification.body.isEmpty ? '상대가 도도 코드를 보냈어요.' : notification.body}$codeMessage',
      confirmLabel: '거래 완료하기',
      cancelLabel: '나중에',
      emphasizeCode: tradeCode,
    );
    if (shouldComplete != true || !mounted || offer == null) {
      return;
    }

    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .completeTrade(offer: offer);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('거래 완료 처리에 실패했어요. 상세에서 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('거래를 완료 처리했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showCancelNotificationDialog({
    required MarketUserNotification notification,
    required MarketOffer? offer,
  }) async {
    final shouldOpen = await _showRealtimeDialog(
      title: notification.title.isEmpty ? '거래가 취소되었어요' : notification.title,
      message: notification.body.isEmpty
          ? '상대가 거래를 취소했어요. 다른 제안을 확인해 보세요.'
          : notification.body,
      confirmLabel: '거래 보기',
      cancelLabel: '닫기',
    );
    if (shouldOpen != true || !mounted || offer == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketOfferDetailPage(offer: offer),
      ),
    );
  }

  Future<void> _openOfferDetail(String offerId) async {
    final normalized = offerId.trim();
    if (normalized.isEmpty) {
      return;
    }
    final offer = await ref
        .read(marketRepositoryProvider)
        .fetchOfferById(normalized);
    if (offer == null || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketOfferDetailPage(offer: offer),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await ref
          .read(marketRepositoryProvider)
          .markUserNotificationRead(
            uid: widget.uid,
            notificationId: notificationId,
          );
    } catch (_) {
      // 유지보수 포인트:
      // 읽음 처리 실패는 UX를 막지 않고 다음 알림 처리로 진행합니다.
    }
  }

  Future<bool?> _showRealtimeDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    String emphasizeCode = '',
  }) {
    const dialogButtonHeight = 52.0;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(message, style: AppTextStyles.dialogBodyCompact),
                if (emphasizeCode.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Text(
                      emphasizeCode,
                      style: AppTextStyles.bodyWithSize(
                        26,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            dialogButtonHeight,
                          ),
                          side: const BorderSide(color: AppColors.borderStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            dialogButtonHeight,
                          ),
                          backgroundColor: AppColors.accentDeepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
