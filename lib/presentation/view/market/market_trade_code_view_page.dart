import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/telemetry/app_page_route.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_names.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/presentation/view/common/home_style_app_bar_title.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_send_page.dart';

class MarketTradeCodeViewPage extends ConsumerStatefulWidget {
  const MarketTradeCodeViewPage({required this.offer, super.key});

  final MarketOffer offer;

  @override
  ConsumerState<MarketTradeCodeViewPage> createState() =>
      _MarketTradeCodeViewPageState();
}

class _MarketTradeCodeViewPageState
    extends ConsumerState<MarketTradeCodeViewPage> {
  static const String _maskedCode = '-----';

  bool _isAgreeingRules = false;
  bool _isCancellingTrade = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        widget.offer.lifecycle == MarketLifecycleTab.completed ||
        widget.offer.status == MarketOfferStatus.closed;
    if (isCompleted) {
      return Scaffold(
        appBar: AppBar(title: const HomeStyleAppBarTitle('거래 코드 확인')),
        body: _buildMessage(
          title: '거래가 종료되어 코드를 확인할 수 없어요.',
          subtitle: '종료된 거래의 코드는 더 이상 표시되지 않습니다.',
        ),
      );
    }

    final sessionAsync = ref.watch(
      marketTradeCodeSessionProvider(widget.offer.id),
    );
    final currentUid = ref
        .read(marketViewModelProvider.notifier)
        .currentUserId
        .trim();
    final rulesAgreedAsync = ref.watch(
      marketTradeRuleAgreementProvider((
        offerId: widget.offer.id,
        receiverUid: currentUid,
      )),
    );

    return Scaffold(
      appBar: AppBar(title: const HomeStyleAppBarTitle('거래 코드 확인')),
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
            isRulesAgreed: rulesAgreedAsync.valueOrNull ?? false,
            isRulesAgreementLoading: rulesAgreedAsync.isLoading,
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required MarketTradeCodeSession session,
    required String currentUid,
    required bool isRulesAgreed,
    required bool isRulesAgreementLoading,
  }) {
    final bool isSender = session.isCodeSender(currentUid);
    final bool hasCode = session.hasCode;
    final rules = session.normalizedSenderIslandRules;
    final bool canShowSenderRules = !isSender && hasCode;
    // 유지보수 포인트:
    // 코드 수신자는 규칙 동의 전까지 코드를 잠금 처리합니다.
    // (요구사항: 규칙 확인/동의 후 코드 공개)
    final bool isCodeLockedByRuleAgreement =
        canShowSenderRules && !isRulesAgreed;
    final bool canRevealCode =
        hasCode && (isSender || !isCodeLockedByRuleAgreement);
    final String codeGuideMessage = _resolveCodeGuideMessage(
      hasCode: hasCode,
      isSender: isSender,
      isCodeLockedByRuleAgreement: isCodeLockedByRuleAgreement,
    );

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
        if (canShowSenderRules) ...<Widget>[
          _buildRulesCard(rules: rules, isSenderRulesMissing: rules.isEmpty),
          if (isCodeLockedByRuleAgreement) ...<Widget>[
            const SizedBox(height: 14),
            _buildRuleAgreementActions(
              context,
              session,
              isRulesAgreementLoading: isRulesAgreementLoading,
            ),
          ],
          const SizedBox(height: 14),
        ],
        _buildCodeCard(
          displayedCode: hasCode && canRevealCode ? session.code : _maskedCode,
          guideMessage: codeGuideMessage,
          visibleAt: hasCode && canRevealCode ? session.codeSentAt : null,
        ),
        if (isSender && !hasCode) ...<Widget>[
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                AppPageRoute<void>(
                  screenName: AppScreenNames.marketTradeCodeSend,
                  builder: (_) => MarketTradeCodeSendPage(
                    offer: widget.offer,
                    session: session,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              overlayColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              minimumSize: const Size.fromHeight(56),
              backgroundColor: AppColors.accentDeepOrange,
            ),
            child: Text('코드 보내기', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ],
    );
  }

  Widget _buildCodeCard({
    required String displayedCode,
    required String guideMessage,
    required DateTime? visibleAt,
  }) {
    return Container(
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
          Text(displayedCode, style: AppTextStyles.marketCodeDisplay),
          const SizedBox(height: 8),
          Text(
            guideMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionSecondary,
          ),
          if (visibleAt != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(_formatDateTime(visibleAt), style: AppTextStyles.captionMuted),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleAgreementActions(
    BuildContext context,
    MarketTradeCodeSession session, {
    required bool isRulesAgreementLoading,
  }) {
    final isBusy =
        _isCancellingTrade || _isAgreeingRules || isRulesAgreementLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('규칙에 동의하면 코드가 공개돼요.', style: AppTextStyles.captionSecondary),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: isBusy ? null : () => _agreeRulesAndRevealCode(session),
          style: FilledButton.styleFrom(
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppColors.accentDeepOrange,
          ),
          child: _isAgreeingRules
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('동의하고 코드 확인', style: AppTextStyles.buttonPrimary),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: isBusy ? null : _rejectRulesAndCancelTrade,
          style: OutlinedButton.styleFrom(
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.badgeRedText),
            foregroundColor: AppColors.badgeRedText,
          ),
          child: _isCancellingTrade
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  '동의하지 않고 거래 취소',
                  style: AppTextStyles.bodyWithSize(
                    16,
                    color: AppColors.badgeRedText,
                    weight: FontWeight.w800,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _rejectRulesAndCancelTrade() async {
    if (_isAgreeingRules || _isCancellingTrade) {
      return;
    }
    final shouldCancel = await _showRejectTradeConfirmDialog(context);
    if (shouldCancel != true || !mounted) {
      return;
    }

    setState(() => _isCancellingTrade = true);
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .cancelTrade(offer: widget.offer);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCancellingTrade = false);
      final message = _resolveCancelTradeErrorMessage(error);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
          content: Text('섬 방문 규칙에 동의하지 않아 거래를 취소했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    Navigator.of(context).pop();
  }

  Future<void> _agreeRulesAndRevealCode(MarketTradeCodeSession session) async {
    if (_isAgreeingRules || _isCancellingTrade) {
      return;
    }

    setState(() => _isAgreeingRules = true);
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .agreeTradeRules(offer: widget.offer, session: session);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isAgreeingRules = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_resolveAgreeRulesErrorMessage(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _isAgreeingRules = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('규칙 동의를 저장했어요. 코드를 확인해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool?> _showRejectTradeConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('거래 취소', style: AppTextStyles.headingH2),
                const SizedBox(height: 10),
                Text(
                  '규칙에 동의하지 않으면 거래가 즉시 취소돼요.\n정말 거래를 취소할까요?',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(
                            color: AppColors.borderDefault,
                          ),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text(
                          '돌아가기',
                          style: AppTextStyles.bodySecondaryStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppColors.modalPrimaryAction,
                        ),
                        child: Text(
                          '거래 취소',
                          style: AppTextStyles.buttonPrimary,
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

  String _resolveCodeGuideMessage({
    required bool hasCode,
    required bool isSender,
    required bool isCodeLockedByRuleAgreement,
  }) {
    if (isCodeLockedByRuleAgreement) {
      return '상대 섬 방문 규칙을 확인하고 동의하면 코드가 공개돼요.';
    }
    if (hasCode) {
      return '코드가 전송되었어요. 10분 내 입장해 주세요.';
    }
    return isSender ? '아직 코드를 보내지 않았어요.' : '상대가 코드를 보내는 중이에요.';
  }

  String _resolveCancelTradeErrorMessage(Object error) {
    if (error is StateError) {
      switch (error.message) {
        case 'unauthenticated':
          return '로그인 상태를 확인한 뒤 다시 시도해 주세요.';
        case 'trade_cancel_permission_denied':
          return '거래 취소 권한이 없어요.';
        case 'trade_proposal_not_found':
          return '취소할 거래 제안을 찾지 못했어요.';
        case 'invalid_offer_owner':
        case 'invalid_trade_cancel_payload':
          return '거래 정보가 올바르지 않아 취소할 수 없어요.';
      }
    }
    return '거래 취소에 실패했어요. 잠시 후 다시 시도해 주세요.';
  }

  String _resolveAgreeRulesErrorMessage(Object error) {
    if (error is StateError) {
      switch (error.message) {
        case 'unauthenticated':
          return '로그인 상태를 확인한 뒤 다시 시도해 주세요.';
        case 'trade_rule_agreement_permission_denied':
          return '코드 수신자만 규칙에 동의할 수 있어요.';
        case 'trade_code_not_ready':
          return '아직 확인할 코드가 준비되지 않았어요.';
        case 'trade_rule_missing':
          return '상대 섬 방문 규칙이 아직 등록되지 않았어요.';
        case 'trade_rule_code_mismatch':
          return '코드가 갱신되었어요. 화면을 새로고침한 뒤 다시 동의해 주세요.';
        case 'trade_code_session_not_found':
          return '코드 세션을 찾지 못했어요. 다시 시도해 주세요.';
      }
    }
    return '규칙 동의 저장에 실패했어요. 잠시 후 다시 시도해 주세요.';
  }

  Widget _buildInfoCard(MarketTradeCodeSession session) {
    final senderRole = session.codeSenderUid == widget.offer.ownerUid
        ? '판매자'
        : '구매자';
    final receiverRole = session.codeReceiverUid == widget.offer.ownerUid
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
          Text(widget.offer.title, style: AppTextStyles.bodyPrimaryHeavy),
          const SizedBox(height: 10),
          Text('코드 발송자: $senderRole', style: AppTextStyles.captionSecondary),
          const SizedBox(height: 4),
          Text('코드 수신자: $receiverRole', style: AppTextStyles.captionSecondary),
        ],
      ),
    );
  }

  Widget _buildRulesCard({
    required String rules,
    required bool isSenderRulesMissing,
  }) {
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
          Text('상대 섬 방문 규칙', style: AppTextStyles.captionMuted),
          const SizedBox(height: 6),
          Text(
            isSenderRulesMissing ? '상대가 아직 규칙을 입력하지 않았어요.' : rules,
            style: AppTextStyles.bodySecondaryStrong,
          ),
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
