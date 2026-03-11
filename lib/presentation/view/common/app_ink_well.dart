import 'package:flutter/material.dart';

class AppInkWell extends StatelessWidget {
  const AppInkWell({
    super.key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressUp,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapCancel,
    this.onHighlightChanged,
    this.onHover,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.overlayColor,
    this.splashColor,
    this.splashFactory,
    this.radius,
    this.borderRadius,
    this.customBorder,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
    this.statesController,
    this.hoverDuration,
  });

  static const WidgetStateProperty<Color?> _transparentOverlayColor =
      WidgetStatePropertyAll<Color?>(Colors.transparent);

  final Widget? child;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureLongPressUpCallback? onLongPressUp;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapCallback? onSecondaryTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureTapCancelCallback? onSecondaryTapCancel;
  final ValueChanged<bool>? onHighlightChanged;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final Color? splashColor;
  final InteractiveInkFeatureFactory? splashFactory;
  final double? radius;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final WidgetStatesController? statesController;
  final Duration? hoverDuration;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: customBorder == null ? borderRadius : null,
      shape: customBorder,
      // 유지보수 포인트:
      // Ink 반응을 개별 Material에 가둬서, 부모 Material 전체가 함께 깜빡이는
      // 현상을 막습니다. 호출부는 기존 InkWell처럼 그대로 사용할 수 있습니다.
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onLongPressUp: onLongPressUp,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onSecondaryTap: onSecondaryTap,
        onSecondaryTapUp: onSecondaryTapUp,
        onSecondaryTapDown: onSecondaryTapDown,
        onSecondaryTapCancel: onSecondaryTapCancel,
        onHighlightChanged: onHighlightChanged,
        onHover: onHover,
        mouseCursor: mouseCursor,
        focusColor: focusColor,
        hoverColor: hoverColor,
        // 유지보수 포인트:
        // 공용 탭 영역 기본값은 무색 오버레이로 고정합니다.
        // 일부 화면에서 눌림 효과가 필요하면 호출부에서만 값을 덮어씁니다.
        highlightColor: highlightColor ?? Colors.transparent,
        overlayColor: overlayColor ?? _transparentOverlayColor,
        splashColor: splashColor ?? Colors.transparent,
        splashFactory: splashFactory ?? NoSplash.splashFactory,
        radius: radius,
        borderRadius: borderRadius,
        customBorder: customBorder,
        enableFeedback: enableFeedback,
        excludeFromSemantics: excludeFromSemantics,
        focusNode: focusNode,
        canRequestFocus: canRequestFocus,
        onFocusChange: onFocusChange,
        autofocus: autofocus,
        statesController: statesController,
        hoverDuration: hoverDuration,
        child: child,
      ),
    );
  }
}
