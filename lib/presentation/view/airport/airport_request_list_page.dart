import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/presentation/view/common/app_owl_empty_state.dart';
import 'package:nook_lounge_app/presentation/view/common/home_style_app_bar_title.dart';

class AirportRequestListPage extends StatefulWidget {
  const AirportRequestListPage({
    required this.pendingRequests,
    required this.initialSelectedRequestIds,
    required this.initialDodoCode,
    required this.approvedRequestCount,
    required this.capacity,
    super.key,
  });

  final List<AirportVisitRequest> pendingRequests;
  final Set<String> initialSelectedRequestIds;
  final String initialDodoCode;
  final int approvedRequestCount;
  final int capacity;

  @override
  State<AirportRequestListPage> createState() => _AirportRequestListPageState();
}

class _AirportRequestListPageState extends State<AirportRequestListPage> {
  static final RegExp _codePattern = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{5}$');

  late final Set<String> _selectedIds;

  int get _normalizedCapacity =>
      (widget.capacity <= 0 ? 8 : widget.capacity).clamp(1, 8);

  int get _remainingInviteSlots =>
      (_normalizedCapacity - widget.approvedRequestCount).clamp(
        0,
        _normalizedCapacity,
      );

  @override
  void initState() {
    super.initState();
    _selectedIds = _buildInitialSelection();
  }

  Set<String> _buildInitialSelection() {
    if (_remainingInviteSlots <= 0) {
      return <String>{};
    }

    final seeded = <String>{};
    for (final request in widget.pendingRequests) {
      if (!_canSelectRequest(request)) {
        continue;
      }
      if (!widget.initialSelectedRequestIds.contains(request.id)) {
        continue;
      }
      seeded.add(request.id);
      if (seeded.length >= _remainingInviteSlots) {
        break;
      }
    }
    return seeded;
  }

  bool _canSelectRequest(AirportVisitRequest request) {
    return request.status == AirportVisitRequestStatus.pending;
  }

  void _showSnackBarMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleSelection(AirportVisitRequest request) {
    if (!_canSelectRequest(request)) {
      _showSnackBarMessage('이미 승낙된 손님은 현재 상태만 확인할 수 있어요.');
      return;
    }

    final requestId = request.id;
    final isSelecting = !_selectedIds.contains(requestId);
    if (isSelecting && _remainingInviteSlots <= 0) {
      _showSnackBarMessage('지금은 추가로 승낙할 수 있는 자리가 없어요.');
      return;
    }
    if (isSelecting && _selectedIds.length >= _remainingInviteSlots) {
      _showSnackBarMessage('현재는 최대 $_remainingInviteSlots명까지만 추가로 승낙할 수 있어요.');
      return;
    }

    setState(() {
      if (!isSelecting) {
        _selectedIds.remove(requestId);
      } else {
        _selectedIds.add(requestId);
      }
    });
  }

  void _selectAll() {
    if (_remainingInviteSlots <= 0) {
      _showSnackBarMessage('지금은 추가로 승낙할 수 있는 자리가 없어요.');
      return;
    }

    final selectableIds = widget.pendingRequests
        .where(_canSelectRequest)
        .take(_remainingInviteSlots)
        .map((request) => request.id)
        .toSet();
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(selectableIds);
    });
  }

  void _onInvite() {
    final normalizedCode = widget.initialDodoCode.trim().toUpperCase();
    if (_remainingInviteSlots <= 0) {
      _showSnackBarMessage('지금은 추가로 승낙할 수 있는 자리가 없어요.');
      return;
    }
    if (_selectedIds.isEmpty) {
      _showSnackBarMessage('초대할 손님을 선택해 주세요.');
      return;
    }
    if (_selectedIds.length > _remainingInviteSlots) {
      _showSnackBarMessage('현재는 최대 $_remainingInviteSlots명까지만 추가로 승낙할 수 있어요.');
      return;
    }
    if (!_codePattern.hasMatch(normalizedCode)) {
      _showSnackBarMessage('비행장 탭에서 도도코드를 먼저 등록해 주세요.');
      return;
    }

    Navigator.of(context).pop((
      selectedRequestIds: _selectedIds.toList(growable: false),
      dodoCode: normalizedCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final remainSeats = _remainingInviteSlots;
    final hasRequests = widget.pendingRequests.isNotEmpty;
    final selectableCount = widget.pendingRequests
        .where(_canSelectRequest)
        .length;
    final canSelectAny = selectableCount > 0 && remainSeats > 0;

    return Scaffold(
      appBar: AppBar(
        title: const HomeStyleAppBarTitle('방문 신청 목록'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.s10,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '대기 중인 유저 ${widget.pendingRequests.length}명',
                    style: AppTextStyles.headingH1,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffbbeaff).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$remainSeats자리 남음',
                      style: AppTextStyles.captionWithColor(
                        AppColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: canSelectAny ? _selectAll : null,
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      foregroundColor: AppColors.textSecondary,
                      textStyle: AppTextStyles.captionSecondary,
                    ),
                    child: const Text('전체 선택'),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.s2,
                  AppSpacing.pageHorizontal,
                  0,
                ),
                child: Text(
                  '동시에 최대 $_normalizedCapacity명까지 승낙할 수 있어요.\n이미 승낙된 손님은 상태만 확인할 수 있어요.',
                  style: AppTextStyles.captionMuted.copyWith(
                    height: 1.5
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.s2,
                  AppSpacing.pageHorizontal,
                  0,
                ),
                child: Text(
                  '현재 승낙 중 ${widget.approvedRequestCount}/$_normalizedCapacity명',
                  style: AppTextStyles.captionMuted,
                ),
              ),
            ),
            Expanded(
              child: hasRequests
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        4,
                        AppSpacing.pageHorizontal,
                        20,
                      ),
                      itemCount: widget.pendingRequests.length,
                      separatorBuilder: (_, unused) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final request = widget.pendingRequests[index];
                        final canSelect = _canSelectRequest(request);
                        final selected = _selectedIds.contains(request.id);
                        final statusLabel =
                            request.status == AirportVisitRequestStatus.arrived
                            ? '방문 중'
                            : request.status ==
                                  AirportVisitRequestStatus.invited
                            ? '도착 대기'
                            : '승낙 대기';
                        final statusBg =
                            request.status == AirportVisitRequestStatus.arrived
                            ? AppColors.catalogSuccessBg
                            : request.status ==
                                  AirportVisitRequestStatus.invited
                            ? Color(0xffbbeaff).withOpacity(0.3)
                            : AppColors.badgeYellowBg;
                        final statusTextColor =
                            request.status == AirportVisitRequestStatus.arrived
                            ? AppColors.catalogSuccessText
                            : request.status ==
                                  AirportVisitRequestStatus.invited
                            ? AppColors.badgeBlueText
                            : AppColors.badgeYellowText;
                        return AppInkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _toggleSelection(request),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: canSelect && selected
                                    ? AppColors.accentOrange
                                    : AppColors.borderDefault,
                                width: canSelect && selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  '${index + 1}',
                                  style: AppTextStyles.bodyPrimaryStrong,
                                ),
                                const SizedBox(width: 12),
                                ClipOval(
                                  child: SizedBox(
                                    width: 42,
                                    height: 42,
                                    child:
                                        request.requesterAvatarUrl
                                            .trim()
                                            .isEmpty
                                        ? Image.asset(
                                            'assets/images/icon_raccoon_character.png',
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            request.requesterAvatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/icon_raccoon_character.png',
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        request.requesterName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodyPrimaryStrong,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        request.requesterIslandName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.captionMuted,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: AppTextStyles.captionWithColor(
                                          statusTextColor,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      formatRelativeTime(
                                        canSelect
                                            ? request.requestedAt
                                            : request.updatedAt,
                                      ),
                                      style: AppTextStyles.captionMuted,
                                    ),
                                  ],
                                ),
                                if (canSelect) ...<Widget>[
                                  const SizedBox(width: 8),
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: selected
                                        ? AppColors.badgeBlueText
                                        : AppColors.borderDefault,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: AppOwlEmptyState(
                        useCard: false,
                        imageSize: 160,
                        title: '대기 중인 손님이 없어요.',
                        subtitle: '새 신청이 들어오면 여기에서 한 번에 초대할 수 있어요.',
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          8,
          AppSpacing.pageHorizontal,
          12,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(
                    color: AppColors.borderDefault,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  foregroundColor: AppColors.textMuted,
                  textStyle: AppTextStyles.buttonSecondary,
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: canSelectAny ? _onInvite : null,
                style: FilledButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  backgroundColor: Color(0xff85c8e5),
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text('선택한 손님 승낙하기(${_selectedIds.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
