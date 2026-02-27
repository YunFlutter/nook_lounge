import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';

class AirportRequestListPage extends StatefulWidget {
  const AirportRequestListPage({
    required this.pendingRequests,
    required this.initialSelectedRequestIds,
    required this.initialDodoCode,
    super.key,
  });

  final List<AirportVisitRequest> pendingRequests;
  final Set<String> initialSelectedRequestIds;
  final String initialDodoCode;

  @override
  State<AirportRequestListPage> createState() => _AirportRequestListPageState();
}

class _AirportRequestListPageState extends State<AirportRequestListPage> {
  static final RegExp _codePattern = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{5}$');

  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialSelectedRequestIds};
  }

  void _toggleSelection(String requestId) {
    setState(() {
      if (_selectedIds.contains(requestId)) {
        _selectedIds.remove(requestId);
      } else {
        _selectedIds.add(requestId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(widget.pendingRequests.map((request) => request.id));
    });
  }

  void _onInvite() {
    final normalizedCode = widget.initialDodoCode.trim().toUpperCase();
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('초대할 손님을 선택해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (!_codePattern.hasMatch(normalizedCode)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('비행장 탭에서 도도코드를 먼저 등록해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    Navigator.of(context).pop((
      selectedRequestIds: _selectedIds.toList(growable: false),
      dodoCode: normalizedCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final remainSeats = (8 - widget.pendingRequests.length).clamp(0, 8);
    final hasRequests = widget.pendingRequests.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('방문 신청 목록'), centerTitle: true),
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
                    style: AppTextStyles.headingH3,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.badgeBlueBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$remainSeats자리 남음',
                      style: AppTextStyles.captionWithColor(
                        AppColors.badgeBlueText,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: hasRequests ? _selectAll : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      textStyle: AppTextStyles.captionSecondary,
                    ),
                    child: const Text('전체 선택'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                0,
                AppSpacing.pageHorizontal,
                4,
              ),
              child: Text(
                '도도코드는 비행장 탭에 등록된 코드를 사용해요.',
                style: AppTextStyles.captionMuted,
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
                        final selected = _selectedIds.contains(request.id);
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _toggleSelection(request.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.accentOrange
                                    : AppColors.borderDefault,
                                width: selected ? 2 : 1,
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
                                        '${request.requesterIslandName} · ${request.purpose.label}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.captionMuted,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  formatRelativeTime(request.requestedAt),
                                  style: AppTextStyles.captionMuted,
                                ),
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
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '대기 중인 손님이 없어요.',
                            style: AppTextStyles.headingH2,
                          ),
                          const SizedBox(height: 12),
                          Image.asset(
                            'assets/images/no_data_image.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.contain,
                          ),
                        ],
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
                onPressed: hasRequests ? _onInvite : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.badgeBlueText,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text('다음 번호 초대하기(${_selectedIds.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
