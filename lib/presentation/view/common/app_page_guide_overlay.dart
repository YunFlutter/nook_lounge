import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/page_guide_content.dart';
import 'package:nook_lounge_app/domain/model/page_guide_step.dart';

class AppPageGuideOverlay extends ConsumerStatefulWidget {
  const AppPageGuideOverlay({
    required this.content,
    required this.child,
    super.key,
  });

  final PageGuideContent content;
  final Widget child;

  @override
  ConsumerState<AppPageGuideOverlay> createState() =>
      _AppPageGuideOverlayState();
}

class _AppPageGuideOverlayState extends ConsumerState<AppPageGuideOverlay> {
  static const Color _overlayColor = Color(0x9E5F4F24);

  // 유지보수 포인트:
  // 탭 전환으로 다른 가이드가 들어오면 이전 비동기 조회 결과를 버려야 해서
  // 가장 최근 visibility 체크만 반영하도록 토큰을 함께 관리합니다.
  int _visibilityCheckToken = 0;
  bool _isVisible = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _prepareGuideVisibility();
  }

  @override
  void didUpdateWidget(covariant AppPageGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.storageKey == widget.content.storageKey) {
      return;
    }

    _visibilityCheckToken += 1;
    setState(() {
      _isVisible = false;
      _isDismissing = false;
    });
    _prepareGuideVisibility();
  }

  Future<void> _prepareGuideVisibility() async {
    final requestToken = ++_visibilityCheckToken;
    final hasSeen = await ref
        .read(pageGuideServiceProvider)
        .hasSeen(widget.content.storageKey);
    if (!mounted || requestToken != _visibilityCheckToken || hasSeen) {
      return;
    }

    setState(() {
      _isVisible = true;
    });
  }

  Future<void> _dismissGuide() async {
    if (_isDismissing) {
      return;
    }

    setState(() {
      _isDismissing = true;
    });
    final storageKey = widget.content.storageKey;
    await ref.read(pageGuideServiceProvider).markSeen(storageKey);
    if (!mounted || storageKey != widget.content.storageKey) {
      return;
    }

    setState(() {
      _isVisible = false;
      _isDismissing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      pageGuidePresentationTickProvider(widget.content.storageKey),
      (previous, next) {
        if (previous == next) {
          return;
        }
        _showGuide();
      },
    );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[widget.child, if (_isVisible) _buildOverlay(context)],
    );
  }

  void _showGuide() {
    if (_isVisible || _isDismissing || !mounted) {
      return;
    }

    setState(() {
      _isVisible = true;
    });
  }

  Widget _buildOverlay(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compactTopPadding = screenHeight < 760
        ? AppSpacing.s10
        : AppSpacing.s20;

    return Positioned.fill(
      child: Semantics(
        container: true,
        label: '${widget.content.title} 안내 오버레이',
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ModalBarrier(dismissible: false, color: _overlayColor),
            SafeArea(
              minimum: EdgeInsets.fromLTRB(
                AppSpacing.s16,
                compactTopPadding,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.borderDefault),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: AppColors.shadowStrong,
                            blurRadius: 28,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s20,
                        AppSpacing.s20,
                        AppSpacing.s20,
                        AppSpacing.s20,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _buildBadge(),
                            const SizedBox(height: AppSpacing.s12),
                            _buildHeader(context),
                            const SizedBox(height: AppSpacing.s12),
                            Text(
                              widget.content.description,
                              style: AppTextStyles.bodySecondaryStrong.copyWith(
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s18),
                            ...widget.content.steps.asMap().entries.map((
                              entry,
                            ) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      entry.key ==
                                          widget.content.steps.length - 1
                                      ? 0
                                      : AppSpacing.s12,
                                ),
                                child: _buildStepCard(entry.key, entry.value),
                              );
                            }),
                            const SizedBox(height: AppSpacing.s20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isDismissing ? null : _dismissGuide,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryDefault,
                                  foregroundColor: AppColors.textInverse,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  _isDismissing
                                      ? '가이드를 저장하는 중...'
                                      : widget.content.primaryActionLabel,
                                  style: AppTextStyles.buttonPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.navActiveBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        widget.content.badgeLabel,
        style: AppTextStyles.captionWithColor(
          AppColors.navActive,
          weight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            widget.content.title,
            style: AppTextStyles.headingH1.copyWith(height: 1.2),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        IconButton(
          onPressed: _isDismissing ? null : _dismissGuide,
          tooltip: '가이드 닫기',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.bgSecondary,
            foregroundColor: AppColors.textSecondary,
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildStepCard(int index, PageGuideStep step) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: step.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(step.icon, color: step.accentColor),
          ),
          const SizedBox(width: AppSpacing.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'STEP ${index + 1}',
                  style: AppTextStyles.captionWithColor(
                    step.accentColor,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(step.title, style: AppTextStyles.bodyPrimaryHeavy),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  step.description,
                  style: AppTextStyles.captionSecondary.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
