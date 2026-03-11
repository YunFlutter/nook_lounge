import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/telemetry/app_page_route.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_names.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/presentation/view/common/home_style_app_bar_title.dart';
import 'package:nook_lounge_app/presentation/view/common/app_owl_empty_state.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_card.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_send_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_rules_view_sheet.dart';

class MarketTradeCodeViewPage extends ConsumerStatefulWidget {
  const MarketTradeCodeViewPage({
    required this.offer,
    this.targetReceiverUid = '',
    super.key,
  });

  final MarketOffer offer;
  final String targetReceiverUid;

  @override
  ConsumerState<MarketTradeCodeViewPage> createState() =>
      _MarketTradeCodeViewPageState();
}

class _MarketTradeCodeViewPageState
    extends ConsumerState<MarketTradeCodeViewPage> {
  static const String _maskedCode = '-----';

  bool _isAgreeingRules = false;
  bool _isConfirmingVisit = false;
  bool _isCancellingTrade = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        widget.offer.lifecycle == MarketLifecycleTab.completed ||
        widget.offer.status == MarketOfferStatus.closed;
    if (isCompleted) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: _buildAppBar(),
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
    final tradeVisitRequestsAsync = ref.watch(
      airportTradeVisitRequestsProvider((offerId: widget.offer.id, uid: '')),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildMessage(
          title: '코드 정보를 불러오지 못했어요.',
          subtitle: '잠시 후 다시 시도해 주세요.',
        ),
        data: (session) {
          if (session == null) {
            return _buildEmptyMessage(
              title: '아직 코드 세션이 없어요.',
              subtitle: '거래 승낙 후 코드가 생성됩니다.',
            );
          }
          final isSender = session.isCodeSender(currentUid);
          final supportsTouchingQueue = _supportsTouchingQueue(widget.offer);
          final proposalsAsync = isSender && supportsTouchingQueue
              ? ref.watch(marketTradeProposalsProvider(widget.offer.id))
              : const AsyncValue<List<MarketTradeProposal>>.data(
                  <MarketTradeProposal>[],
                );
          final tradeVisitRequests =
              tradeVisitRequestsAsync.valueOrNull ??
              const <AirportVisitRequest>[];
          final agreedReceiverUids = tradeVisitRequests
              .where((request) => request.hasValidRuleAgreement)
              .map((request) => request.requesterUid.trim())
              .where((uid) => uid.isNotEmpty)
              .toSet();
          final normalizedTargetReceiverUid = widget.targetReceiverUid.trim();
          final selectedReceiverUids = _splitUidCsv(session.codeReceiverUid);
          final acceptedReceiverUids =
              proposalsAsync.valueOrNull
                  ?.where((proposal) => proposal.isAccepted)
                  .map((proposal) => proposal.proposerUid.trim())
                  .where((uid) => uid.isNotEmpty)
                  .toSet() ??
              const <String>{};
          final targetTradeVisitRequest = normalizedTargetReceiverUid.isEmpty
              ? null
              : _findTradeVisitRequestForReceiver(
                  requests: tradeVisitRequests,
                  receiverUid: normalizedTargetReceiverUid,
                );
          final shouldResetQueuedTouchingCode =
              isSender &&
              supportsTouchingQueue &&
              (normalizedTargetReceiverUid.isNotEmpty
                  ? !selectedReceiverUids.contains(
                          normalizedTargetReceiverUid,
                        ) &&
                        !_hasActiveTradeInvite(targetTradeVisitRequest)
                  : (proposalsAsync.isLoading ||
                        (acceptedReceiverUids.isNotEmpty &&
                            !_hasSameUidSet(
                              acceptedReceiverUids,
                              selectedReceiverUids,
                            ))));
          final focusReceiverUids = normalizedTargetReceiverUid.isNotEmpty
              ? <String>{normalizedTargetReceiverUid}
              : shouldResetQueuedTouchingCode
              ? _resolveQueuedTouchingFocusReceiverUids(
                  acceptedReceiverUids: acceptedReceiverUids,
                  selectedReceiverUids: selectedReceiverUids,
                  proposerUid: session.proposerUid,
                )
              : selectedReceiverUids;
          final tradeVisitRequest = isSender && supportsTouchingQueue
              ? _resolveHostTradeVisitRequest(
                  requests: tradeVisitRequests,
                  selectedReceiverUids: focusReceiverUids,
                  agreedReceiverUids: agreedReceiverUids,
                )
              : _resolveTradeVisitRequestForViewer(
                  requests: tradeVisitRequests,
                  viewerUid: currentUid,
                  targetReceiverUid: isSender
                      ? normalizedTargetReceiverUid
                      : currentUid,
                  fallbackReceiverUid: isSender
                      ? session.proposerUid
                      : currentUid,
                );
          final isRulesAgreed = isSender && supportsTouchingQueue
              ? _isHostVisitRequestReadyForArrival(request: tradeVisitRequest)
              : (tradeVisitRequest?.hasValidRuleAgreement ?? false);
          return _buildBody(
            context: context,
            session: session,
            currentUid: currentUid,
            isRulesAgreed: isRulesAgreed,
            isRulesAgreementLoading:
                tradeVisitRequestsAsync.isLoading || proposalsAsync.isLoading,
            tradeVisitRequest: tradeVisitRequest,
            isTradeVisitRequestLoading: tradeVisitRequestsAsync.isLoading,
            shouldResetQueuedTouchingCode: shouldResetQueuedTouchingCode,
          );
        },
      ),
    );
  }

  bool _supportsTouchingQueue(MarketOffer offer) {
    return offer.tradeType == MarketTradeType.touching &&
        offer.moveType == MarketMoveType.host;
  }

  AirportVisitRequest? _resolveHostTradeVisitRequest({
    required List<AirportVisitRequest> requests,
    required Set<String> selectedReceiverUids,
    required Set<String> agreedReceiverUids,
  }) {
    final candidateRequests = selectedReceiverUids.isEmpty
        ? requests
        : requests
              .where(
                (request) =>
                    selectedReceiverUids.contains(request.requesterUid.trim()),
              )
              .toList(growable: false);
    for (final request in candidateRequests) {
      if (request.isInvited &&
          agreedReceiverUids.contains(request.requesterUid.trim())) {
        return request;
      }
    }
    for (final request in candidateRequests) {
      if (request.isInvited) {
        return request;
      }
    }
    for (final request in candidateRequests) {
      if (request.isArrived) {
        return request;
      }
    }
    for (final request in candidateRequests) {
      if (request.isPending) {
        return request;
      }
    }
    return null;
  }

  Set<String> _resolveQueuedTouchingFocusReceiverUids({
    required Set<String> acceptedReceiverUids,
    required Set<String> selectedReceiverUids,
    required String proposerUid,
  }) {
    final normalizedProposerUid = proposerUid.trim();
    if (normalizedProposerUid.isNotEmpty &&
        acceptedReceiverUids.contains(normalizedProposerUid) &&
        !selectedReceiverUids.contains(normalizedProposerUid)) {
      return <String>{normalizedProposerUid};
    }

    final unsentReceiverUids = acceptedReceiverUids.difference(
      selectedReceiverUids,
    );
    if (unsentReceiverUids.isNotEmpty) {
      return unsentReceiverUids;
    }
    return acceptedReceiverUids;
  }

  bool _hasSameUidSet(Set<String> left, Set<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final uid in left) {
      if (!right.contains(uid)) {
        return false;
      }
    }
    return true;
  }

  AirportVisitRequest? _findTradeVisitRequestForReceiver({
    required List<AirportVisitRequest> requests,
    required String receiverUid,
  }) {
    final normalizedReceiverUid = receiverUid.trim();
    if (normalizedReceiverUid.isEmpty) {
      return null;
    }
    for (final request in requests) {
      if (request.requesterUid.trim() == normalizedReceiverUid) {
        return request;
      }
    }
    return null;
  }

  AirportVisitRequest? _resolveTradeVisitRequestForViewer({
    required List<AirportVisitRequest> requests,
    required String viewerUid,
    required String targetReceiverUid,
    required String fallbackReceiverUid,
  }) {
    final normalizedTargetReceiverUid = targetReceiverUid.trim();
    if (normalizedTargetReceiverUid.isNotEmpty) {
      return _findTradeVisitRequestForReceiver(
        requests: requests,
        receiverUid: normalizedTargetReceiverUid,
      );
    }

    final normalizedViewerUid = viewerUid.trim();
    final viewerRequest = _findTradeVisitRequestForReceiver(
      requests: requests,
      receiverUid: normalizedViewerUid,
    );
    if (viewerRequest != null) {
      return viewerRequest;
    }

    final normalizedFallbackReceiverUid = fallbackReceiverUid.trim();
    if (normalizedFallbackReceiverUid.isNotEmpty) {
      return _findTradeVisitRequestForReceiver(
        requests: requests,
        receiverUid: normalizedFallbackReceiverUid,
      );
    }

    if (requests.isEmpty) {
      return null;
    }
    return requests.first;
  }

  bool _hasActiveTradeInvite(AirportVisitRequest? request) {
    if (request == null) {
      return false;
    }
    final hasInviteCode = request.inviteCode?.trim().isNotEmpty ?? false;
    return hasInviteCode || request.isInvited || request.isArrived;
  }

  String _resolveTradeCodeSendTargetReceiverUid({
    required MarketTradeCodeSession session,
    required AirportVisitRequest? tradeVisitRequest,
  }) {
    final requestReceiverUid = tradeVisitRequest?.requesterUid.trim() ?? '';
    if (requestReceiverUid.isNotEmpty) {
      return requestReceiverUid;
    }

    final sessionProposerUid = session.proposerUid.trim();
    if (sessionProposerUid.isNotEmpty) {
      return sessionProposerUid;
    }

    final receiverUids = _splitUidCsv(session.codeReceiverUid);
    if (receiverUids.length == 1) {
      return receiverUids.first;
    }
    return '';
  }

  bool _isHostVisitRequestReadyForArrival({
    required AirportVisitRequest? request,
  }) {
    if (request == null) {
      return false;
    }
    if (request.isArrived) {
      return true;
    }
    return request.isInvited && request.hasValidRuleAgreement;
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: const HomeStyleAppBarTitle('거래 코드 확인'),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required MarketTradeCodeSession session,
    required String currentUid,
    required bool isRulesAgreed,
    required bool isRulesAgreementLoading,
    required AirportVisitRequest? tradeVisitRequest,
    required bool isTradeVisitRequestLoading,
    required bool shouldResetQueuedTouchingCode,
  }) {
    final isSender = session.isCodeSender(currentUid);
    final requestCode =
        tradeVisitRequest?.inviteCode?.trim().toUpperCase() ?? '';
    final sessionCode = session.code.trim().toUpperCase();
    final displayedActiveCode = requestCode.isNotEmpty
        ? requestCode
        : (isSender ? sessionCode : '');
    final hasCode =
        displayedActiveCode.isNotEmpty && !shouldResetQueuedTouchingCode;
    final rules =
        (tradeVisitRequest?.senderIslandRules?.trim().isNotEmpty ?? false)
        ? tradeVisitRequest!.senderIslandRules!.trim()
        : session.normalizedSenderIslandRules;
    final canShowSenderRules = !isSender && hasCode;
    final isCodeLockedByRuleAgreement = canShowSenderRules && !isRulesAgreed;
    final canRevealCode = hasCode && (isSender || !isCodeLockedByRuleAgreement);
    final isVisitConfirmed =
        isSender && (tradeVisitRequest?.isArrived ?? false);
    final canConfirmVisit =
        canRevealCode &&
        isSender &&
        isRulesAgreed &&
        tradeVisitRequest != null &&
        !tradeVisitRequest.isArrived &&
        _hasActiveTradeInvite(tradeVisitRequest);
    final codeGuideMessage = _resolveCodeGuideMessage(
      hasCode: hasCode,
      isSender: isSender,
      isCodeLockedByRuleAgreement: isCodeLockedByRuleAgreement,
      canConfirmVisit: canConfirmVisit,
      isVisitConfirmed: isVisitConfirmed,
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s12,
          AppSpacing.pageHorizontal,
          AppSpacing.s24,
        ),
        children: <Widget>[
          Center(
            child: _buildStatusPill(
              label: _statusLabel(
                hasCode: hasCode,
                isSender: isSender,
                canRevealCode: canRevealCode,
                isCodeLockedByRuleAgreement: isCodeLockedByRuleAgreement,
                isRulesAgreementLoading: isRulesAgreementLoading,
                canConfirmVisit: canConfirmVisit,
                isVisitConfirmed: isVisitConfirmed,
              ),
              dotColor: _statusDotColor(
                hasCode: hasCode,
                canRevealCode: canRevealCode,
                isCodeLockedByRuleAgreement: isCodeLockedByRuleAgreement,
                isRulesAgreementLoading: isRulesAgreementLoading,
                canConfirmVisit: canConfirmVisit,
                isVisitConfirmed: isVisitConfirmed,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s22),
          Text(
            _headlineText(
              hasCode: hasCode,
              isSender: isSender,
              canRevealCode: canRevealCode,
              isCodeLockedByRuleAgreement: isCodeLockedByRuleAgreement,
              canConfirmVisit: canConfirmVisit,
              isVisitConfirmed: isVisitConfirmed,
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.dialogTitleWithSize(24),
          ),
          const SizedBox(height: AppSpacing.s20),
          Text(
            _headlineCaption(
              hasCode: hasCode,
              isSender: isSender,
              canRevealCode: canRevealCode,
              isCodeLockedByRuleAgreement: isCodeLockedByRuleAgreement,
              canConfirmVisit: canConfirmVisit,
              isVisitConfirmed: isVisitConfirmed,
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondaryStrong.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.s20),
          Center(
            child: Image.asset(
              'assets/images/code_airplane.png',
              width: min(MediaQuery.sizeOf(context).width * 0.52, 220),
              fit: BoxFit.contain,
              semanticLabel: '거래 코드 확인 비행기 일러스트',
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          _buildTradeSummary(),
          const SizedBox(height: AppSpacing.s24),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildSectionTitle('도도 코드'),
          ),
          const SizedBox(height: AppSpacing.s10),
          _buildCodeCard(
            displayedCode: hasCode && canRevealCode
                ? displayedActiveCode
                : _maskedCode,
            guideMessage: codeGuideMessage,
            visibleAt: hasCode && canRevealCode
                ? (tradeVisitRequest?.invitedAt ?? session.codeSentAt)
                : null,
          ),
          if (canShowSenderRules) ...<Widget>[
            const SizedBox(height: AppSpacing.s24),
            if (isCodeLockedByRuleAgreement) ...<Widget>[
              DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: rules.isEmpty
                      ? null
                      : () => _openRulesSheet(
                          context,
                          inviteCode: displayedActiveCode,
                          rules: rules,
                          requiresAgreement: true,
                        ),
                  style: FilledButton.styleFrom(
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: AppColors.modalPrimaryAction,
                    disabledBackgroundColor: AppColors.catalogChipBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text('방문 규칙 확인', style: AppTextStyles.buttonPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed:
                      _isCancellingTrade ||
                          _isAgreeingRules ||
                          isRulesAgreementLoading
                      ? null
                      : _rejectRulesAndCancelTrade,
                  style: OutlinedButton.styleFrom(
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.white,
                    side: const BorderSide(
                      color: AppColors.badgeRedText,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isCancellingTrade
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.badgeRedText,
                          ),
                        )
                      : Text(
                          '방문 취소',
                          style: AppTextStyles.bodyWithSize(
                            16,
                            color: AppColors.badgeRedText,
                            weight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ] else ...<Widget>[
              DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed:
                      _isCancellingTrade ||
                          _isAgreeingRules ||
                          isRulesAgreementLoading
                      ? null
                      : _rejectRulesAndCancelTrade,
                  style: OutlinedButton.styleFrom(
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.white,
                    side: const BorderSide(
                      color: AppColors.badgeRedText,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isCancellingTrade
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.badgeRedText,
                          ),
                        )
                      : Text(
                          '방문 취소',
                          style: AppTextStyles.bodyWithSize(
                            16,
                            color: AppColors.badgeRedText,
                            weight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ],
          if (isSender && hasCode) ...<Widget>[
            const SizedBox(height: AppSpacing.s24),
            DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed:
                    canConfirmVisit &&
                        !_isConfirmingVisit &&
                        !_isCancellingTrade &&
                        !isTradeVisitRequestLoading
                    ? () => _confirmVisit(request: tradeVisitRequest)
                    : null,
                style: FilledButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: AppColors.modalPrimaryAction,
                  disabledBackgroundColor: AppColors.catalogChipBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isConfirmingVisit
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        isVisitConfirmed ? '방문 확인 완료' : '방문 확인',
                        style: AppTextStyles.buttonPrimary,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed:
                    _isCancellingTrade ||
                        _isConfirmingVisit ||
                        isTradeVisitRequestLoading
                    ? null
                    : _rejectRulesAndCancelTrade,
                style: OutlinedButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(
                    color: AppColors.badgeRedText,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isCancellingTrade
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.badgeRedText,
                        ),
                      )
                    : Text(
                        '방문 취소',
                        style: AppTextStyles.bodyWithSize(
                          16,
                          color: AppColors.badgeRedText,
                          weight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
          if (isSender && !hasCode) ...<Widget>[
            const SizedBox(height: AppSpacing.s24),
            DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: () {
                  final targetReceiverUid =
                      _resolveTradeCodeSendTargetReceiverUid(
                        session: session,
                        tradeVisitRequest: tradeVisitRequest,
                      );
                  Navigator.of(context).push(
                    AppPageRoute<void>(
                      screenName: AppScreenNames.marketTradeCodeSend,
                      builder: (_) => MarketTradeCodeSendPage(
                        offer: widget.offer,
                        session: session,
                        targetReceiverUid: targetReceiverUid,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: AppColors.modalPrimaryAction,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text('코드 보내기', style: AppTextStyles.buttonPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill({required String label, required Color dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(label, style: AppTextStyles.captionSecondary),
        ],
      ),
    );
  }

  Widget _buildTradeSummary() {
    return IgnorePointer(
      child: MarketOfferCard(
        offer: widget.offer,
        showActionArea: false,
        onTap: () {},
        onActionTap: () {},
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.headingH3);
  }

  Widget _buildCodeCard({
    required String displayedCode,
    required String guideMessage,
    required DateTime? visibleAt,
  }) {
    final isMasked = displayedCode == _maskedCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s18,
        AppSpacing.s22,
        AppSpacing.s18,
        AppSpacing.s18,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            displayedCode,
            style: isMasked
                ? AppTextStyles.bodyWithSize(
                    32,
                    color: AppColors.textMuted,
                    weight: FontWeight.w800,
                    letterSpacing: 6,
                  )
                : AppTextStyles.marketCodeDisplay,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            guideMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionSecondary,
          ),
          if (visibleAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s8),
            Text(_formatDateTime(visibleAt), style: AppTextStyles.captionMuted),
          ],
        ],
      ),
    );
  }

  Future<void> _openRulesSheet(
    BuildContext context, {
    required String inviteCode,
    required String rules,
    required bool requiresAgreement,
  }) async {
    final result = await showModalBottomSheet<MarketTradeRulesSheetAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: MarketTradeRulesViewSheet(
              rules: rules,
              showAgreementActions: requiresAgreement,
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    if (result == MarketTradeRulesSheetAction.agree) {
      await _agreeRulesAndRevealCode(inviteCode);
      return;
    }
    if (result == MarketTradeRulesSheetAction.cancelTrade) {
      await _rejectRulesAndCancelTrade();
    }
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
          content: Text('거래를 취소했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    Navigator.of(context).pop();
  }

  Future<void> _agreeRulesAndRevealCode(String inviteCode) async {
    if (_isAgreeingRules || _isCancellingTrade) {
      return;
    }

    setState(() => _isAgreeingRules = true);
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .agreeTradeRules(offer: widget.offer, inviteCode: inviteCode);
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

  Future<void> _confirmVisit({required AirportVisitRequest? request}) async {
    if (request == null || _isConfirmingVisit || _isCancellingTrade) {
      return;
    }

    setState(() => _isConfirmingVisit = true);
    try {
      await ref
          .read(airportRepositoryProvider)
          .markArrived(islandId: request.islandId, requestId: request.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isConfirmingVisit = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_resolveVisitConfirmErrorMessage(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _isConfirmingVisit = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('비행장 방문 상태를 섬에 있음으로 변경했어요.'),
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
                  '이 거래를 취소할까요?\n취소하면 진행 중인 방문 일정도 함께 정리돼요.',
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

  String _statusLabel({
    required bool hasCode,
    required bool isSender,
    required bool canRevealCode,
    required bool isCodeLockedByRuleAgreement,
    required bool isRulesAgreementLoading,
    required bool canConfirmVisit,
    required bool isVisitConfirmed,
  }) {
    if (_isCancellingTrade) {
      return '거래 취소 중';
    }
    if (_isConfirmingVisit) {
      return '방문 확인 중';
    }
    if (_isAgreeingRules || isRulesAgreementLoading) {
      return '규칙 동의 저장 중';
    }
    if (isCodeLockedByRuleAgreement) {
      return '규칙 확인 필요';
    }
    if (isVisitConfirmed) {
      return '섬 도착 확인됨';
    }
    if (canConfirmVisit) {
      return '방문 확인 가능';
    }
    if (hasCode && canRevealCode) {
      return '코드 확인 가능';
    }
    return isSender ? '코드 발송 대기' : '코드 도착 대기';
  }

  Color _statusDotColor({
    required bool hasCode,
    required bool canRevealCode,
    required bool isCodeLockedByRuleAgreement,
    required bool isRulesAgreementLoading,
    required bool canConfirmVisit,
    required bool isVisitConfirmed,
  }) {
    if (_isCancellingTrade) {
      return AppColors.badgeRedText;
    }
    if (_isConfirmingVisit) {
      return AppColors.accentDeepOrange;
    }
    if (_isAgreeingRules || isRulesAgreementLoading) {
      return AppColors.accentDeepOrange;
    }
    if (isCodeLockedByRuleAgreement) {
      return AppColors.badgeRedText;
    }
    if (isVisitConfirmed) {
      return AppColors.accentDeepOrange;
    }
    if (canConfirmVisit) {
      return AppColors.modalPrimaryAction;
    }
    if (hasCode && canRevealCode) {
      return AppColors.modalPrimaryAction;
    }
    return AppColors.textMuted;
  }

  String _headlineText({
    required bool hasCode,
    required bool isSender,
    required bool canRevealCode,
    required bool isCodeLockedByRuleAgreement,
    required bool canConfirmVisit,
    required bool isVisitConfirmed,
  }) {
    if (isCodeLockedByRuleAgreement) {
      return '방문 규칙을 먼저 확인해 주세요!';
    }
    if (isVisitConfirmed) {
      return '방문 상태를 전달했어요!';
    }
    if (canConfirmVisit) {
      return '도착했다면 방문 확인을 눌러주세요!';
    }
    if (hasCode && canRevealCode) {
      return isSender ? '코드가 전송되었어요!' : '입장 준비를 해주세요!';
    }
    return isSender ? '도도 코드를 보내주세요!' : '코드가 도착하길 기다려주세요!';
  }

  String _headlineCaption({
    required bool hasCode,
    required bool isSender,
    required bool canRevealCode,
    required bool isCodeLockedByRuleAgreement,
    required bool canConfirmVisit,
    required bool isVisitConfirmed,
  }) {
    if (isCodeLockedByRuleAgreement) {
      return '상대 섬 방문 규칙에 동의하면 코드가 바로 공개돼요.';
    }
    if (isVisitConfirmed) {
      return '비행장에 방문 상태가 반영되었어요. 즐거운 거래 되세요.';
    }
    if (canConfirmVisit) {
      return '섬에 도착하면 방문 확인을 눌러 비행장 상태를 업데이트해 주세요.';
    }
    if (hasCode && canRevealCode) {
      return isSender
          ? '상대가 바로 확인할 수 있게 도도 코드를 안내해 주세요.'
          : '도도 코드를 확인했어요. 준비가 되면 방문해 주세요.';
    }
    return isSender
        ? '거래가 진행되려면 먼저 도도 코드를 보내야 해요.'
        : '상대가 도도 코드를 보내면 이 화면에서 바로 확인할 수 있어요.';
  }

  String _resolveCodeGuideMessage({
    required bool hasCode,
    required bool isSender,
    required bool isCodeLockedByRuleAgreement,
    required bool canConfirmVisit,
    required bool isVisitConfirmed,
  }) {
    if (isCodeLockedByRuleAgreement) {
      return '상대 섬 방문 규칙을 확인하고 동의하면 코드가 공개돼요.';
    }
    if (isVisitConfirmed) {
      return '비행장에 섬 방문 상태가 반영되었어요.';
    }
    if (canConfirmVisit) {
      return '섬에 도착하면 방문 확인을 눌러 주세요.';
    }
    if (hasCode) {
      return '코드가 전송되었어요. 준비가 되면 방문해 주세요.';
    }
    return isSender ? '아직 코드를 보내지 않았어요.' : '상대가 코드를 보내는 중이에요.';
  }

  String _resolveVisitConfirmErrorMessage(Object error) {
    if (error is StateError) {
      switch (error.message) {
        case 'permission-denied':
          return '방문 상태를 변경할 권한이 없어요.';
        case 'touching_visit_already_in_progress':
          return '만지작 줄서기는 한 번에 한 명씩만 방문 확인할 수 있어요.';
      }
    }
    return '방문 확인 처리에 실패했어요. 잠시 후 다시 시도해 주세요.';
  }

  Set<String> _splitUidCsv(String raw) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
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

  Widget _buildEmptyMessage({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
        ),
        child: AppOwlEmptyState(title: title, subtitle: subtitle),
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
