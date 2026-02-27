import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';

class AirportLiveRecruitPage extends StatefulWidget {
  const AirportLiveRecruitPage({
    required this.myUid,
    required this.openSessions,
    required this.myActiveRequests,
    required this.onRequestVisit,
    required this.onCancelRequest,
    super.key,
  });

  final String myUid;
  final List<AirportSession> openSessions;
  final List<AirportVisitRequest> myActiveRequests;
  final Future<void> Function({
    required AirportSession targetSession,
    required AirportVisitPurpose purpose,
    required String message,
  })
  onRequestVisit;
  final Future<void> Function(AirportVisitRequest request) onCancelRequest;

  @override
  State<AirportLiveRecruitPage> createState() => _AirportLiveRecruitPageState();
}

class _AirportLiveRecruitPageState extends State<AirportLiveRecruitPage> {
  final TextEditingController _searchController = TextEditingController();
  AirportVisitPurpose? _filterPurpose;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onTapRequest(AirportSession session) async {
    final selection = await _openRequestPurposeDialog(context, session.purpose);
    if (selection == null) {
      return;
    }
    await widget.onRequestVisit(
      targetSession: session,
      purpose: selection.purpose,
      message: selection.message,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('방문 신청을 보냈어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _onTapCancelRequest(AirportVisitRequest request) async {
    await widget.onCancelRequest(request);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('대기 요청을 취소했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final requestByIslandId = <String, AirportVisitRequest>{
      for (final request in widget.myActiveRequests)
        if (request.islandId.trim().isNotEmpty)
          request.islandId.trim(): request,
    };

    final filteredSessions = widget.openSessions
        .where((session) => session.ownerUid != widget.myUid)
        .where((session) {
          if (_filterPurpose != null && session.purpose != _filterPurpose) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return session.islandName.toLowerCase().contains(query) ||
              session.hostName.toLowerCase().contains(query) ||
              session.introMessage.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('실시간 방문 모집'), centerTitle: true),
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
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.bodyPrimaryStrong,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.borderStrong,
                  ),
                  hintText: '가구, 레시피, 주민 검색...',
                  hintStyle: AppTextStyles.bodyHintStrong,
                  filled: true,
                  fillColor: AppColors.bgCard,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AirportVisitPurpose.values.length + 1,
                  separatorBuilder: (_, unused) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final selected = _filterPurpose == null;
                      return ChoiceChip(
                        label: Text(
                          '전체',
                          style: selected
                              ? AppTextStyles.captionInverseHeavy
                              : AppTextStyles.captionSecondary,
                        ),
                        selected: selected,
                        selectedColor: AppColors.accentOrange,
                        backgroundColor: AppColors.catalogChipBg,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() {
                            _filterPurpose = null;
                          });
                        },
                      );
                    }

                    final purpose = AirportVisitPurpose.values[index - 1];
                    final selected = _filterPurpose == purpose;
                    return ChoiceChip(
                      label: Text(
                        purpose.label,
                        style: selected
                            ? AppTextStyles.captionInverseHeavy
                            : AppTextStyles.captionSecondary,
                      ),
                      selected: selected,
                      selectedColor: AppColors.badgeBlueText,
                      backgroundColor: AppColors.catalogChipBg,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _filterPurpose = purpose;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredSessions.isEmpty
                  ? Center(
                      child: Text(
                        '지금은 열려있는 비행장이 없어요.',
                        style: AppTextStyles.bodySecondaryStrong,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        0,
                        AppSpacing.pageHorizontal,
                        AppSpacing.s10 * 2,
                      ),
                      itemCount: filteredSessions.length,
                      separatorBuilder: (_, unused) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final myRequest = requestByIslandId[session.islandId];
                        final waiting = myRequest != null;
                        final statusText = waiting
                            ? myRequest.status ==
                                      AirportVisitRequestStatus.invited
                                  ? '초대됨'
                                  : '대기중'
                            : '열림';
                        final statusBg = waiting
                            ? AppColors.badgeRedBg
                            : AppColors.catalogSuccessBg;
                        final statusTextColor = waiting
                            ? AppColors.badgeRedText
                            : AppColors.catalogSuccessText;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  ClipOval(
                                    child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child:
                                          session.islandImageUrl.trim().isEmpty
                                          ? Image.asset(
                                              'assets/images/icon_raccoon_character.png',
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              session.islandImageUrl,
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          session.hostName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.bodyPrimaryStrong,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          session.islandName,
                                          style: AppTextStyles.captionMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: AppTextStyles.captionWithColor(
                                        statusTextColor,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                session.introMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySecondaryStrong,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.badgeBlueBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      session.purpose.label,
                                      style: AppTextStyles.captionWithColor(
                                        AppColors.badgeBlueText,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatRelativeTime(session.updatedAt),
                                    style: AppTextStyles.captionMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  const Spacer(),
                                  SizedBox(
                                    height: 38,
                                    child: waiting
                                        ? OutlinedButton(
                                            onPressed: () =>
                                                _onTapCancelRequest(myRequest),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: AppColors.borderDefault,
                                              ),
                                              foregroundColor:
                                                  AppColors.textSecondary,
                                              textStyle: AppTextStyles
                                                  .bodySecondaryStrong,
                                            ),
                                            child: const Text('대기 취소'),
                                          )
                                        : FilledButton(
                                            onPressed: () =>
                                                _onTapRequest(session),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.badgeBlueText,
                                              foregroundColor:
                                                  AppColors.textInverse,
                                              textStyle: AppTextStyles
                                                  .bodyPrimaryHeavy,
                                            ),
                                            child: const Text('줄 서기'),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<({AirportVisitPurpose purpose, String message})?>
  _openRequestPurposeDialog(
    BuildContext context,
    AirportVisitPurpose initialPurpose,
  ) async {
    AirportVisitPurpose selectedPurpose = initialPurpose;
    final messageController = TextEditingController(
      text: AirportSession.defaultIntroMessage,
    );

    final result =
        await showDialog<({AirportVisitPurpose purpose, String message})>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  title: Text('방문 목적 선택', style: AppTextStyles.headingH2),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AirportVisitPurpose.values
                            .map((purpose) {
                              final selected = selectedPurpose == purpose;
                              return ChoiceChip(
                                label: Text(
                                  purpose.label,
                                  style: selected
                                      ? AppTextStyles.captionInverseHeavy
                                      : AppTextStyles.captionSecondary,
                                ),
                                selected: selected,
                                selectedColor: AppColors.primaryDefault,
                                backgroundColor: AppColors.catalogChipBg,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setState(() {
                                    selectedPurpose = purpose;
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        maxLength: 80,
                        maxLines: 2,
                        style: AppTextStyles.bodyPrimaryStrong,
                        decoration: InputDecoration(
                          labelText: '한 줄 메시지',
                          hintText: '예) 너굴너굴섬에 놀러오세요!',
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop((
                          purpose: selectedPurpose,
                          message: messageController.text.trim(),
                        ));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.badgeBlueText,
                        foregroundColor: AppColors.textInverse,
                      ),
                      child: const Text('신청'),
                    ),
                  ],
                );
              },
            );
          },
        );

    messageController.dispose();
    return result;
  }
}
