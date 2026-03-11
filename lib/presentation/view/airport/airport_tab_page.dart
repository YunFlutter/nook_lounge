import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/telemetry/app_page_route.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_names.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_view.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/domain/model/settings_notification_preferences.dart';
import 'package:nook_lounge_app/presentation/view/airport/airport_dodo_code_input_sheet.dart';
import 'package:nook_lounge_app/presentation/view/airport/airport_request_list_page.dart';
import 'package:nook_lounge_app/presentation/view/airport/airport_visitor_manifest_page.dart';
import 'package:nook_lounge_app/presentation/view/airport/widgets/airport_gate_pill_toggle.dart';
import 'package:nook_lounge_app/presentation/view/home/home_dashboard_tab.dart';
import 'package:nook_lounge_app/presentation/viewmodel/airport_view_model.dart';

class AirportTabPage extends ConsumerStatefulWidget {
  const AirportTabPage({required this.uid, required this.islandId, super.key});

  final String uid;
  final String islandId;

  @override
  ConsumerState<AirportTabPage> createState() => _AirportTabPageState();
}

class _AirportTabPageState extends ConsumerState<AirportTabPage> {
  static const double _visitorSlotWidth = 72;
  static const double _visitorAvatarSize = 58;
  Timer? _relativeTimeTicker;
  String _ensuredIslandId = '';

  @override
  void initState() {
    super.initState();
    _relativeTimeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _relativeTimeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = (uid: widget.uid, islandId: widget.islandId);
    final state = ref.watch(airportViewModelProvider(args));
    final viewModel = ref.read(airportViewModelProvider(args).notifier);

    ref.listen(airportViewModelProvider(args), (previous, next) {
      if (!mounted) {
        return;
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        viewModel.consumeMessages();
      } else if (next.infoMessage != null &&
          next.infoMessage != previous?.infoMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.infoMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        viewModel.consumeMessages();
      }
    });

    ref.listen<int>(
      airportViewModelProvider(
        args,
      ).select((state) => state.pendingRequests.length),
      (previous, next) {
        if (!mounted) {
          return;
        }
        if (previous == null || next <= previous) {
          return;
        }

        final notificationPrefs =
            ref
                .read(settingsNotificationPreferencesProvider(widget.uid))
                .valueOrNull ??
            SettingsNotificationPreferences.defaults;
        if (!notificationPrefs.airportQueueStandbyEnabled) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('내 방문 모집글에 새 대기열이 추가됐어요.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
    );

    final islands =
        ref.watch(homeDashboardIslandsProvider(widget.uid)).valueOrNull ??
        const <IslandProfile>[];
    IslandProfile? selectedIsland;
    for (final island in islands) {
      if (island.id == widget.islandId) {
        selectedIsland = island;
        break;
      }
    }

    if (selectedIsland != null && _ensuredIslandId != selectedIsland.id) {
      _ensuredIslandId = selectedIsland.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        viewModel.ensureSession(
          islandName: selectedIsland!.islandName,
          hostName: selectedIsland.representativeName,
          hostAvatarUrl: selectedIsland.imageUrl ?? '',
          islandImageUrl: selectedIsland.imageUrl ?? '',
        );
      });
    }

    if (widget.islandId.trim().isEmpty) {
      return AppScreenView(
        screenName: AppScreenNames.airportTab,
        child: Center(
          child: Text(
            '섬이 선택되지 않았어요.\n먼저 섬을 등록해 주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ),
      );
    }

    final session =
        state.session ??
        _buildFallbackSession(island: selectedIsland, uid: widget.uid);

    if (session == null && state.isInitializing) {
      return const AppScreenView(
        screenName: AppScreenNames.airportTab,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (session == null) {
      return AppScreenView(
        screenName: AppScreenNames.airportTab,
        child: Center(
          child: Text(
            '비행장 정보를 불러오지 못했어요.',
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ),
      );
    }

    final activeCode = session.activeDodoCode();
    final pendingRequests = state.pendingRequests;
    final waitingGuests = state.waitingGuests;
    final currentVisitors = state.activeVisitors;
    final requestListRequests = _buildRequestListRequests(
      pendingRequests: pendingRequests,
      waitingGuests: waitingGuests,
    );
    final myRequestSource = state.myRequests;
    final myActiveRequests =
        myRequestSource
            .where((request) => request.isActive)
            .where((request) => request.islandId != widget.islandId)
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final isMyRequestsRealtimeLoading =
        state.isInitializing && myRequestSource.isEmpty;

    final myWaitingSection = _buildMyWaitingSection(
      myActiveRequests,
      loading: isMyRequestsRealtimeLoading,
    );

    return AppScreenView(
      screenName: AppScreenNames.airportTab,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(airportViewModelProvider(args));
          await Future<void>.delayed(const Duration(milliseconds: 260));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.s10,
            AppSpacing.pageHorizontal,
            AppSpacing.s10,
          ),
          children: <Widget>[
            _buildGateSection(
              session: session,
              onToggle: (value) => viewModel.toggleGateOpen(value),
            ),
            const SizedBox(height: 16),
            _buildDodoCodeSection(
              code: activeCode,
              onInputCode: () => _openDodoCodeSheet(
                context: context,
                currentCode: activeCode,
                onSaved: viewModel.updateDodoCode,
              ),
              onResetCode: viewModel.resetDodoCode,
              onCopyCode: () {
                if (activeCode.isEmpty) {
                  return;
                }
                Clipboard.setData(ClipboardData(text: activeCode));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('도도코드를 복사했어요.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              },
            ),
            const SizedBox(height: 32),
            myWaitingSection,
            const SizedBox(height: 32),
            _buildInvitedSection(
              requests: waitingGuests,
              onMarkArrived: (requestId) => viewModel.markArrived(requestId),
              onReportUser: (request) =>
                  viewModel.reportVisitRequester(request: request),
              onOpenAll: () => _openRequestList(
                context: context,
                viewModel: viewModel,
                session: session,
                requestListRequests: requestListRequests,
                initiallySelectedIds: state.selectedRequestIds,
              ),
            ),
            const SizedBox(height: 32),
            _buildCurrentVisitorsSection(
              visitors: currentVisitors,
              waitingGuests: waitingGuests,
              capacity: session.capacity,
              onMarkArrived: (requestId) => viewModel.markArrived(requestId),
              onOpenManifest: () => _openVisitorManifest(
                context: context,
                uid: widget.uid,
                islandId: widget.islandId,
                session: session,
                onInviteTap: () => _openRequestList(
                  context: context,
                  viewModel: viewModel,
                  session: session,
                  requestListRequests: requestListRequests,
                  initiallySelectedIds: state.selectedRequestIds,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AirportSession? _buildFallbackSession({
    required IslandProfile? island,
    required String uid,
  }) {
    if (island == null) {
      return null;
    }
    return AirportSession(
      islandId: island.id,
      ownerUid: uid,
      islandName: island.islandName,
      hostName: island.representativeName,
      hostAvatarUrl: island.imageUrl ?? '',
      islandImageUrl: island.imageUrl ?? '',
      introMessage: AirportSession.defaultIntroMessage,
      rules: AirportSession.defaultRules,
      purpose: AirportVisitPurpose.touching,
      gateOpen: false,
      dodoCode: '',
      updatedAt: DateTime.now(),
      capacity: 8,
    );
  }

  Widget _buildGateSection({
    required AirportSession session,
    required ValueChanged<bool> onToggle,
  }) {
    final introSummary = _resolveGateIntroSummary(session);
    final hasIntroSummary = introSummary.isNotEmpty;
    final gateBorderColor = session.gateOpen
        ? AppColors.badgeBlueBg
        : AppColors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gateBorderColor, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('게이트 상태', style: AppTextStyles.headingH2)),
                AirportGatePillToggle(
                  gateOpen: session.gateOpen,
                  semanticLabel: '게이트 열기',
                  onTap: () {
                    onToggle(!session.gateOpen);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: session.gateOpen
                        ? AppColors.badgeRedText
                        : AppColors.textHint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  session.gateOpen ? '방문객에게 열림' : '방문객에게 닫힘',
                  style: AppTextStyles.bodySecondaryStrong,
                ),
              ],
            ),
            if (hasIntroSummary) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                introSummary,
                style: AppTextStyles.captionMuted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDodoCodeSection({
    required String code,
    required VoidCallback onInputCode,
    required VoidCallback onResetCode,
    required VoidCallback onCopyCode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.key_rounded, color: AppColors.accentOrange),
            const SizedBox(width: 6),
            Expanded(child: Text('도도코드', style: AppTextStyles.headingH3)),
            TextButton(
              onPressed: onResetCode,
              style: TextButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                foregroundColor: AppColors.textHint,
                textStyle: AppTextStyles.captionSecondary,
              ),
              child: const Text('코드 초기화'),
            ),
          ],
        ),
        // const SizedBox(height: 8),
        AppInkWell(
          onTap: onInputCode,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    code.isEmpty ? '도도코드를 등록해주세요.' : code,
                    textAlign: TextAlign.center,
                    style: code.isEmpty
                        ? AppTextStyles.bodyHintStrong
                        : AppTextStyles.bodyWithSize(
                            32,
                            letterSpacing: 1.5,
                            color: AppColors.navInactive,
                            weight: FontWeight.w800,
                          ),
                  ),
                ),
                IconButton(
                  onPressed: code.isEmpty ? null : onCopyCode,
                  icon: const Icon(
                    Icons.content_copy_rounded,
                    color: AppColors.textHint,
                  ),
                  tooltip: '코드 복사',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '방문객과 이 5자리 코드를 공유하세요.',
            style: AppTextStyles.captionMuted,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _resolveGateIntroSummary(AirportSession session) {
    // 유지보수 포인트: 비행장 메인 카드에서는 기본 소개문(고정 문구)을
    // 노출하지 않고, 사용자가 직접 입력한 소개 문구만 보여줍니다.
    final intro = session.introMessage.trim();
    if (intro.isEmpty || intro == AirportSession.defaultIntroMessage) {
      return '';
    }
    return intro;
  }

  Widget _buildMyWaitingSection(
    List<AirportVisitRequest> requests, {
    bool loading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text('내가 대기 중인 섬 현황', style: AppTextStyles.headingH3),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (requests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              '아직 대기 중인 섬이 없어요.',
              style: AppTextStyles.bodySecondaryStrong,
              textAlign: TextAlign.center,
            ),
          )
        else
          ...requests.take(2).map((request) {
            final isTradeLinked = request.sourceType == 'market_trade';
            final hasInviteCode =
                request.inviteCode?.trim().isNotEmpty ?? false;
            final statusColor =
                request.status == AirportVisitRequestStatus.arrived
                ? AppColors.catalogSuccessBg
                : request.status == AirportVisitRequestStatus.invited ||
                      hasInviteCode
                ? AppColors.badgeBlueBg
                : AppColors.badgeRedBg;
            final textColor =
                request.status == AirportVisitRequestStatus.arrived
                ? AppColors.catalogSuccessText
                : request.status == AirportVisitRequestStatus.invited ||
                      hasInviteCode
                ? AppColors.badgeBlueText
                : AppColors.badgeRedText;
            final statusLabel =
                request.status == AirportVisitRequestStatus.arrived
                ? '방문중'
                : request.status == AirportVisitRequestStatus.invited ||
                      hasInviteCode
                ? '초대됨'
                : '대기중';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  children: <Widget>[
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: request.hostIslandImageUrl.trim().isEmpty
                            ? Image.asset(
                                'assets/images/icon_raccoon_character.png',
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                request.hostIslandImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/icon_raccoon_character.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            request.hostName,
                            style: AppTextStyles.bodyPrimaryStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${request.hostIslandName} · ${request.purpose.label}',
                            style: AppTextStyles.captionMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isTradeLinked) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.badgeYellowBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '거래',
                          style: AppTextStyles.captionWithColor(
                            AppColors.badgeYellowText,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.captionWithColor(
                          textColor,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildInvitedSection({
    required List<AirportVisitRequest> requests,
    required Future<void> Function(String requestId) onMarkArrived,
    required Future<void> Function(AirportVisitRequest request) onReportUser,
    required VoidCallback onOpenAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text('내 섬에 방문 대기 중인 손님', style: AppTextStyles.headingH3),
            ),
            TextButton(
              onPressed: onOpenAll,
              style: TextButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTextStyles.captionSecondary,
              ),
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (requests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              '대기 중인 손님이 없어요.',
              style: AppTextStyles.bodySecondaryStrong,
              textAlign: TextAlign.center,
            ),
          )
        else
          ...requests.take(3).map((request) {
            final isTradeLinked = request.sourceType == 'market_trade';
            final hasInviteCode =
                request.inviteCode?.trim().isNotEmpty ?? false;
            final isInvited =
                request.status == AirportVisitRequestStatus.invited;
            final isArrived =
                request.status == AirportVisitRequestStatus.arrived;
            final canMarkArrived = !isArrived && (isInvited || hasInviteCode);
            final waitingLabel = isArrived
                ? '방문 중'
                : (isInvited || hasInviteCode ? '도착 대기' : '코드 대기');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipOval(
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: request.requesterAvatarUrl.trim().isEmpty
                                ? Image.asset(
                                    'assets/images/icon_raccoon_character.png',
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    request.requesterAvatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/icon_raccoon_character.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                request.requesterName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyPrimaryStrong,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '목적: ${request.purpose.label}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.captionMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            waitingLabel,
                            style: AppTextStyles.captionMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        // 유지보수 포인트:
                        // 액션 버튼을 별도 행으로 분리해 좁은 폭에서도
                        // 닉네임 영역이 과도하게 줄어들지 않도록 고정합니다.
                        if (isTradeLinked) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.badgeYellowBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '거래',
                              style: AppTextStyles.captionWithColor(
                                AppColors.badgeYellowText,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        const Spacer(),
                        TextButton(
                          onPressed: () => _onTapReportUser(
                            onReportUser: onReportUser,
                            request: request,
                          ),
                          style: TextButton.styleFrom(
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            foregroundColor: AppColors.badgeRedText,
                            textStyle: AppTextStyles.captionSecondary,
                          ),
                          child: const Text('신고'),
                        ),
                        const SizedBox(width: 4),
                        if (canMarkArrived)
                          OutlinedButton(
                            onPressed: () => onMarkArrived(request.id),
                            style: OutlinedButton.styleFrom(
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              side: const BorderSide(
                                color: AppColors.borderDefault,
                              ),
                              foregroundColor: AppColors.textSecondary,
                              textStyle: AppTextStyles.captionSecondary,
                            ),
                            child: const Text('도착 확인'),
                          )
                        else
                          Text(
                            formatRelativeTime(request.updatedAt),
                            style: AppTextStyles.captionMuted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCurrentVisitorsSection({
    required List<AirportVisitRequest> visitors,
    required List<AirportVisitRequest> waitingGuests,
    required int capacity,
    required Future<void> Function(String requestId) onMarkArrived,
    required VoidCallback onOpenManifest,
  }) {
    final canAddRequests = waitingGuests
        .where(_canAddFromWaitingGuest)
        .toList(growable: false);
    final slotCount = (capacity <= 0 ? 8 : capacity).clamp(1, 20);
    final renderedSlots = visitors.length > slotCount
        ? visitors.length
        : slotCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('현재 방문객 명단', style: AppTextStyles.headingH3)),
            TextButton(
              onPressed: onOpenManifest,
              style: TextButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTextStyles.captionSecondary,
              ),
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: renderedSlots,
            separatorBuilder: (_, unused) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < visitors.length) {
                return _buildVisitorFilledSlot(visitors[index]);
              }
              return _buildVisitorEmptySlot(
                canAdd: canAddRequests.isNotEmpty,
                onTap: canAddRequests.isEmpty
                    ? null
                    : () => _openWaitingGuestPicker(
                        waitingGuests: canAddRequests,
                        onMarkArrived: onMarkArrived,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorFilledSlot(AirportVisitRequest visitor) {
    return SizedBox(
      width: _visitorSlotWidth,
      child: Column(
        children: <Widget>[
          ClipOval(
            child: Container(
              width: _visitorAvatarSize,
              height: _visitorAvatarSize,
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: visitor.requesterAvatarUrl.trim().isEmpty
                  ? Image.asset(
                      'assets/images/icon_raccoon_character.png',
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      visitor.requesterAvatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/icon_raccoon_character.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            visitor.requesterName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorEmptySlot({
    required bool canAdd,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.transparent,
      child: AppInkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: _visitorSlotWidth,
          child: Column(
            children: <Widget>[
              Container(
                width: _visitorAvatarSize,
                height: _visitorAvatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgSecondary,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: canAdd
                      ? AppColors.primaryDefault
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                canAdd ? '추가' : '비어있음',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: canAdd
                    ? AppTextStyles.captionPrimaryHeavy
                    : AppTextStyles.captionMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canAddFromWaitingGuest(AirportVisitRequest request) {
    if (request.status == AirportVisitRequestStatus.arrived) {
      return false;
    }
    if (request.status == AirportVisitRequestStatus.invited) {
      return true;
    }
    return request.inviteCode?.trim().isNotEmpty ?? false;
  }

  Future<void> _openWaitingGuestPicker({
    required List<AirportVisitRequest> waitingGuests,
    required Future<void> Function(String requestId) onMarkArrived,
  }) async {
    final selected = await showModalBottomSheet<AirportVisitRequest>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        if (waitingGuests.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '대기 중인 손님이 없어요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondaryStrong,
              ),
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: waitingGuests.length,
            separatorBuilder: (_, unused) =>
                const Divider(height: 1, color: AppColors.borderDefault),
            itemBuilder: (context, index) {
              final request = waitingGuests[index];
              return ListTile(
                leading: ClipOval(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: request.requesterAvatarUrl.trim().isEmpty
                        ? Image.asset(
                            'assets/images/icon_raccoon_character.png',
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            request.requesterAvatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/icon_raccoon_character.png',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                ),
                title: Text(
                  request.requesterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyPrimaryStrong,
                ),
                subtitle: Text(
                  '${request.requesterIslandName} · ${request.purpose.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMuted,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                onTap: () => Navigator.of(context).pop(request),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }
    await onMarkArrived(selected.id);
  }

  Future<void> _onTapReportUser({
    required Future<void> Function(AirportVisitRequest request) onReportUser,
    required AirportVisitRequest request,
  }) async {
    final requesterUid = request.requesterUid.trim();
    if (requesterUid.isEmpty) {
      return;
    }

    final shouldReport = await _showReportUserConfirmDialog(
      targetUserName: request.requesterName,
    );
    if (shouldReport != true || !mounted) {
      return;
    }

    try {
      await onReportUser(request);
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('신고가 접수되었어요. 운영팀이 확인할게요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool?> _showReportUserConfirmDialog({required String targetUserName}) {
    // 유지보수 포인트:
    // 비행장/거래 다이얼로그 버튼 높이를 동일 토큰으로 맞춰 화면별 시각 일관성을 유지합니다.
    const dialogButtonHeight = 54.0;
    final targetName = targetUserName.trim().isEmpty
        ? '해당 유저'
        : targetUserName.trim();
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('손님 신고', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '$targetName 님을 신고할까요?\n신고 내용은 운영팀 검토 후 처리됩니다.',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size.fromHeight(
                            dialogButtonHeight,
                          ),
                          side: const BorderSide(color: AppColors.borderStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
                          minimumSize: const Size.fromHeight(
                            dialogButtonHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '신고',
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

  Future<void> _openDodoCodeSheet({
    required BuildContext context,
    required String currentCode,
    required Future<void> Function(String code) onSaved,
  }) async {
    final nextCode = await showModalBottomSheet<String>(
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
            child: AirportDodoCodeInputSheet(initialCode: currentCode),
          ),
        );
      },
    );

    if (!mounted || nextCode == null) {
      return;
    }
    await onSaved(nextCode);
  }

  Future<void> _openRequestList({
    required BuildContext context,
    required AirportViewModel viewModel,
    required AirportSession session,
    required List<AirportVisitRequest> requestListRequests,
    required Set<String> initiallySelectedIds,
  }) async {
    final result = await Navigator.of(context)
        .push<({List<String> selectedRequestIds, String dodoCode})>(
          AppPageRoute<({List<String> selectedRequestIds, String dodoCode})>(
            screenName: AppScreenNames.airportRequestList,
            builder: (_) => AirportRequestListPage(
              pendingRequests: requestListRequests,
              initialSelectedRequestIds: initiallySelectedIds,
              initialDodoCode: session.activeDodoCode(),
            ),
          ),
        );

    if (!mounted || result == null) {
      return;
    }

    viewModel.clearSelectedRequests();
    for (final requestId in result.selectedRequestIds) {
      viewModel.toggleRequestSelection(requestId);
    }

    final invited = await viewModel.inviteSelectedRequests(
      dodoCode: result.dodoCode,
    );

    if (!invited || !context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '손님들에게 초대장과\n도도코드를 보냈습니다!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingH2,
              ),
              const SizedBox(height: 10),
              Text('비행장에서 기다려 주세요.', style: AppTextStyles.bodySecondaryStrong),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                backgroundColor: AppColors.modalPrimaryAction,
                foregroundColor: AppColors.textInverse,
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  List<AirportVisitRequest> _buildRequestListRequests({
    required List<AirportVisitRequest> pendingRequests,
    required List<AirportVisitRequest> waitingGuests,
  }) {
    final mergedById = <String, AirportVisitRequest>{};
    for (final request in pendingRequests) {
      if (request.status == AirportVisitRequestStatus.arrived) {
        continue;
      }
      mergedById[request.id] = request;
    }
    for (final request in waitingGuests) {
      if (request.status == AirportVisitRequestStatus.arrived) {
        continue;
      }
      mergedById[request.id] = request;
    }

    final merged = mergedById.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }

  Future<void> _openVisitorManifest({
    required BuildContext context,
    required String uid,
    required String islandId,
    required AirportSession session,
    required VoidCallback onInviteTap,
  }) async {
    await Navigator.of(context).push(
      AppPageRoute<void>(
        screenName: AppScreenNames.airportVisitorManifest,
        builder: (_) => AirportVisitorManifestPage(
          uid: uid,
          islandId: islandId,
          session: session,
          onInviteTap: onInviteTap,
        ),
      ),
    );
  }
}
