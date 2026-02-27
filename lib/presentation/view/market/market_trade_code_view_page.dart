import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_send_page.dart';

class MarketTradeCodeViewPage extends ConsumerWidget {
  const MarketTradeCodeViewPage({required this.offer, super.key});

  final MarketOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted =
        offer.lifecycle == MarketLifecycleTab.completed ||
        offer.status == MarketOfferStatus.closed;
    if (isCompleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('거래 코드 확인')),
        body: _buildMessage(
          title: '거래가 종료되어 코드를 확인할 수 없어요.',
          subtitle: '종료된 거래의 코드는 더 이상 표시되지 않습니다.',
        ),
      );
    }

    final sessionAsync = ref.watch(marketTradeCodeSessionProvider(offer.id));
    final currentUid = ref.read(marketViewModelProvider.notifier).currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('거래 코드 확인')),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildMessage(
          title: '코드 정보를 불러오지 못했어요.',
          subtitle: '잠시 후 다시 시도해 주세요.',
        ),
        data: (session) {
          if (session == null) {
            return _buildMessage(
              title: '아직 코드 세션이 없어요.',
              subtitle: '거래 승낙 후 코드가 생성됩니다.',
            );
          }
          return _buildBody(
            context: context,
            session: session,
            currentUid: currentUid,
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required MarketTradeCodeSession session,
    required String currentUid,
  }) {
    final bool isSender = session.isCodeSender(currentUid);
    final bool hasCode = session.hasCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.s10,
        AppSpacing.pageHorizontal,
        110,
      ),
      children: <Widget>[
        _buildInfoCard(session),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: <Widget>[
              Text('도도 코드', style: AppTextStyles.captionMuted),
              const SizedBox(height: 8),
              Text(
                hasCode ? session.code : '-----',
                style: AppTextStyles.bodyWithSize(
                  34,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasCode
                    ? '코드가 전송되었어요. 10분 내 입장해 주세요.'
                    : (isSender ? '아직 코드를 보내지 않았어요.' : '상대가 코드를 보내는 중이에요.'),
                textAlign: TextAlign.center,
                style: AppTextStyles.captionSecondary,
              ),
              if (session.codeSentAt != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(session.codeSentAt!),
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ],
          ),
        ),
        if (isSender && !hasCode) ...<Widget>[
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      MarketTradeCodeSendPage(offer: offer, session: session),
                ),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: AppColors.accentDeepOrange,
            ),
            child: Text('코드 보내기', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(MarketTradeCodeSession session) {
    final senderRole = session.codeSenderUid == offer.ownerUid ? '판매자' : '구매자';
    final receiverRole = session.codeReceiverUid == offer.ownerUid
        ? '판매자'
        : '구매자';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('거래 제목', style: AppTextStyles.captionMuted),
          const SizedBox(height: 4),
          Text(offer.title, style: AppTextStyles.bodyPrimaryHeavy),
          const SizedBox(height: 10),
          Text('코드 발송자: $senderRole', style: AppTextStyles.captionSecondary),
          const SizedBox(height: 4),
          Text('코드 수신자: $receiverRole', style: AppTextStyles.captionSecondary),
        ],
      ),
    );
  }

  Widget _buildMessage({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.mark_chat_unread_rounded,
                color: AppColors.textHint,
                size: 44,
              ),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.bodySecondaryStrong),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.captionHint),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('yyyy.MM.dd HH:mm').format(value);
  }
}
