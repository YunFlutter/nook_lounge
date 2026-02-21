import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/animated_scale_button.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_empty_result_panel.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_legend_dot.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_loading_panel.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_prediction_chart.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_prediction_table.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_price_input_field.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_step_circle_button.dart';

class TurnipPage extends ConsumerWidget {
  const TurnipPage({required this.uid, super.key});

  final String uid;

  static const List<String> _dayLabels = <String>[
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(turnipViewModelProvider(uid));
    final viewModel = ref.read(turnipViewModelProvider(uid).notifier);
    final prediction = state.prediction;

    final minValues = _buildDailySeries(
      prediction?.minMaxPattern,
      useMin: true,
    );
    final maxValues = _buildDailySeries(
      prediction?.minMaxPattern,
      useMin: false,
    );
    final avgValues = _buildDailyAverageSeries(prediction?.avgPattern);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.s10,
        AppSpacing.pageHorizontal,
        AppSpacing.pageHorizontal,
      ),
      children: <Widget>[
        const AnimatedFadeSlide(
          child: Text(
            '예측을 위해 무 가격을 입력해주세요.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 40),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '일요일 매수 가격',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '무파니에게 구매한 가격',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: <Widget>[
                      TurnipStepCircleButton(
                        icon: Icons.remove,
                        onTap: () => viewModel.adjustSundayBuyPrice(-1),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${state.sundayBuyPrice}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TurnipStepCircleButton(
                        icon: Icons.add,
                        isAccent: true,
                        onTap: () => viewModel.adjustSundayBuyPrice(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 80),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                '일일 추적기',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.catalogChipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '월-토',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 120),
          child: SizedBox(
            height: 224,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dayLabels.length,
              separatorBuilder: (_, unused) => const SizedBox(width: 10),
              itemBuilder: (context, dayIndex) {
                final morningIndex = dayIndex * 2;
                final afternoonIndex = morningIndex + 1;
                final hasDayInput =
                    state.weekSlots[morningIndex] != null ||
                    state.weekSlots[afternoonIndex] != null;
                final isFocused = state.activeDayIndex == dayIndex;
                final isActive = isFocused || hasDayInput;

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isActive ? 1 : 0.38,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => viewModel.setActiveDay(dayIndex),
                    child: Container(
                      width: 154,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primaryDefault
                              : AppColors.borderDefault,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isFocused
                                ? '입력중'
                                : hasDayInput
                                ? '입력됨'
                                : '예정',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primaryDefault
                                  : AppColors.textHint,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dayLabels[dayIndex],
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '오전가격',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.textSecondary
                                  : AppColors.textHint,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TurnipPriceInputField(
                            fieldId: 'am-$morningIndex',
                            value: state.weekSlots[morningIndex],
                            onChanged: (value) => viewModel.setWeekSlotPrice(
                              index: morningIndex,
                              value: value,
                            ),
                            onFocusChanged: (hasFocus) {
                              if (hasFocus) {
                                viewModel.setActiveDay(dayIndex);
                                return;
                              }
                              viewModel.clearActiveDay(dayIndex);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '오후가격',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.textSecondary
                                  : AppColors.textHint,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TurnipPriceInputField(
                            fieldId: 'pm-$afternoonIndex',
                            value: state.weekSlots[afternoonIndex],
                            onChanged: (value) => viewModel.setWeekSlotPrice(
                              index: afternoonIndex,
                              value: value,
                            ),
                            onFocusChanged: (hasFocus) {
                              if (hasFocus) {
                                viewModel.setActiveDay(dayIndex);
                                return;
                              }
                              viewModel.clearActiveDay(dayIndex);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 140),
          child: AnimatedScaleButton(
            onTap: state.isLoading ? () {} : viewModel.calculate,
            child: Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryDefault,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: state.isLoading
                    ? const Row(
                        key: ValueKey<String>('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '계산중..',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        key: ValueKey<String>('idle'),
                        '계산하기',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (state.errorMessage != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            state.errorMessage!,
            style: const TextStyle(
              color: AppColors.accentDeepOrange,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 160),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: state.isLoading
                ? const TurnipLoadingPanel()
                : prediction == null
                ? const TurnipEmptyResultPanel()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '예측 결과',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              TurnipLegendDot(
                                color: AppColors.badgeYellowText,
                                label: '최소',
                              ),
                              SizedBox(width: 8),
                              TurnipLegendDot(
                                color: AppColors.primaryDefault,
                                label: '최대',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '입력된 정보를 기반으로 한 결과입니다.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TurnipPredictionChart(
                        minValues: minValues,
                        maxValues: maxValues,
                        peakDayIndex: (prediction.peakIndex / 2).floor(),
                        peakLabel: _slotLabel(prediction.peakIndex),
                        peakValue: prediction.peakMaxValue,
                      ),
                      const SizedBox(height: 12),
                      TurnipPredictionTable(
                        minValues: minValues,
                        maxValues: maxValues,
                        avgValues: avgValues,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  static List<int> _buildDailySeries(
    List<List<int>>? minMaxPattern, {
    required bool useMin,
  }) {
    if (minMaxPattern == null || minMaxPattern.isEmpty) {
      return const <int>[];
    }

    if (minMaxPattern.length < 12) {
      return minMaxPattern
          .take(6)
          .map((value) => _readValue(value, useMin))
          .toList(growable: false);
    }

    final result = <int>[];
    for (var day = 0; day < 6; day++) {
      // 유지보수 포인트:
      // 디자인 기준 그래프/표의 일자별 값은 오전 슬롯(짝수 인덱스)을 사용합니다.
      result.add(_readValue(minMaxPattern[day * 2], useMin));
    }
    return result;
  }

  static int _readValue(List<int> point, bool useMin) {
    if (point.isEmpty) {
      return 0;
    }
    if (useMin) {
      return point.first;
    }
    if (point.length >= 2) {
      return point[1];
    }
    return point.first;
  }

  static List<int> _buildDailyAverageSeries(List<double>? avgPattern) {
    if (avgPattern == null || avgPattern.isEmpty) {
      return const <int>[];
    }

    if (avgPattern.length < 12) {
      return avgPattern
          .take(6)
          .map((value) => value.round())
          .toList(growable: false);
    }

    final result = <int>[];
    for (var day = 0; day < 6; day++) {
      // 유지보수 포인트:
      // 평균값도 오전 슬롯 기준으로 표기해 차트/테이블 간 기준을 통일합니다.
      result.add(avgPattern[day * 2].round());
    }
    return result;
  }

  static String _slotLabel(int index) {
    const days = <String>['월', '화', '수', '목', '금', '토'];
    final dayIndex = (index / 2).floor().clamp(0, 5);
    final isAfternoon = index.isOdd;
    return '${days[dayIndex]}요일 ${isAfternoon ? '오후' : '오전'}';
  }
}
