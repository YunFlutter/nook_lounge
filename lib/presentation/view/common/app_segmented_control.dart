import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';

typedef AppSegmentedControlItem<T> = ({
  T value,
  String label,
  IconData? icon,
  Color selectedColor,
  String? semanticsLabel,
});

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.textStyleBuilder,
    super.key,
    this.backgroundColor = AppColors.catalogSegmentBg,
    this.selectedBackgroundColor = AppColors.white,
    this.unselectedColor = AppColors.textMuted,
    this.outerRadius = 18,
    this.innerRadius = 14,
    this.gap = AppSpacing.s4,
    this.outerPadding = const EdgeInsets.all(AppSpacing.s4),
    this.segmentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s8,
      vertical: AppSpacing.s12,
    ),
    this.selectedShadow = const <BoxShadow>[
      BoxShadow(
        color: AppColors.shadowSoft,
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ],
    this.iconSize = 16,
    this.animationDuration = const Duration(milliseconds: 180),
    this.animationCurve = Curves.easeOutCubic,
  }) : assert(items.length >= 2);

  final T value;
  final List<AppSegmentedControlItem<T>> items;
  final ValueChanged<T> onChanged;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color unselectedColor;
  final double outerRadius;
  final double innerRadius;
  final double gap;
  final EdgeInsets outerPadding;
  final EdgeInsets segmentPadding;
  final List<BoxShadow> selectedShadow;
  final double iconSize;
  final Duration animationDuration;
  final Curve animationCurve;
  final TextStyle Function(
    BuildContext context,
    AppSegmentedControlItem<T> item,
    Color foregroundColor,
    bool selected,
  )
  textStyleBuilder;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = items.indexWhere((item) => item.value == value);
    assert(
      selectedIndex >= 0,
      'AppSegmentedControl value must exist in items.',
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth -
              outerPadding.horizontal -
              (gap * (items.length - 1));
          final segmentWidth = contentWidth / items.length;
          final selectedLeft =
              outerPadding.left + ((segmentWidth + gap) * selectedIndex);

          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: animationDuration,
                curve: animationCurve,
                left: selectedLeft,
                top: outerPadding.top,
                bottom: outerPadding.bottom,
                width: segmentWidth,
                child: IgnorePointer(
                  // 유지보수 포인트:
                  // Positioned 계열 위젯은 Stack의 직접 자식이어야 하므로
                  // 터치 무시는 배경 박스에만 적용합니다.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selectedBackgroundColor,
                      borderRadius: BorderRadius.circular(innerRadius),
                      boxShadow: selectedShadow,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: outerPadding,
                child: Row(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < items.length;
                      index++
                    ) ...<Widget>[
                      if (index > 0) SizedBox(width: gap),
                      Expanded(
                        child: _buildSegment(
                          context: context,
                          item: items[index],
                          selected: index == selectedIndex,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required AppSegmentedControlItem<T> item,
    required bool selected,
  }) {
    final foregroundColor = selected ? item.selectedColor : unselectedColor;

    return Semantics(
      button: true,
      selected: selected,
      label: item.semanticsLabel ?? item.label,
      child: AppInkWell(
        borderRadius: BorderRadius.circular(innerRadius),
        onTap: selected ? null : () => onChanged(item.value),
        child: Padding(
          padding: segmentPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              if (item.icon != null) ...<Widget>[
                Icon(item.icon, size: iconSize, color: foregroundColor),
                SizedBox(width: AppSpacing.s6),
              ],
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: textStyleBuilder(
                  context,
                  item,
                  foregroundColor,
                  selected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
