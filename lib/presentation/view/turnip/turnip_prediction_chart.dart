import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';

const List<String> _turnipChartDayLabels = <String>[
  '월',
  '화',
  '수',
  '목',
  '금',
  '토',
];
const double _turnipChartHeight = 260;
const double _turnipChartYAxisWidth = 34;
const double _turnipChartAxisGap = 10;
const double _turnipChartTopPadding = 36;
const double _turnipChartDayLabelGap = 18;
const double _turnipChartDayLabelHeight = 28;
const double _turnipChartDayLabelWidth = 28;
const double _turnipChartPeakBubbleWidth = 104;
const double _turnipChartGridDashWidth = 8;
const double _turnipChartGridDashSpace = 4;
const double _turnipChartPredictionDashWidth = 12;
const double _turnipChartPredictionDashSpace = 10;

class TurnipPredictionChart extends StatelessWidget {
  const TurnipPredictionChart({
    required this.minValues,
    required this.maxValues,
    required this.peakDayIndex,
    required this.peakLabel,
    required this.peakValue,
    super.key,
  });

  final List<int> minValues;
  final List<int> maxValues;
  final int peakDayIndex;
  final String peakLabel;
  final int peakValue;

  @override
  Widget build(BuildContext context) {
    if (minValues.isEmpty || maxValues.isEmpty) {
      return const SizedBox.shrink();
    }

    final yMax = _resolveYMax();
    final graphMinValues = _normalizeSize(minValues);
    final graphMaxValues = _normalizeSize(maxValues);

    return Column(
      children: <Widget>[
        SizedBox(
          height: _turnipChartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: _turnipChartYAxisWidth,
                child: _YAxisLabels(
                  yMax: yMax,
                  topPadding: _turnipChartTopPadding,
                ),
              ),
              const SizedBox(width: _turnipChartAxisGap),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bubbleWidth = math.min(
                      constraints.maxWidth,
                      _turnipChartPeakBubbleWidth,
                    );
                    final maxBubbleLeft = math.max(
                      0.0,
                      constraints.maxWidth - bubbleWidth,
                    );
                    final chartRect = Rect.fromLTWH(
                      0,
                      _turnipChartTopPadding,
                      constraints.maxWidth,
                      constraints.maxHeight - _turnipChartTopPadding,
                    );

                    final points = _buildPoints(
                      chartRect: chartRect,
                      values: graphMaxValues,
                      yMax: yMax,
                    );
                    final peakIndex = peakDayIndex.clamp(0, points.length - 1);
                    final peakPoint = points[peakIndex];

                    return Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TurnipLineChartPainter(
                              minValues: graphMinValues,
                              maxValues: graphMaxValues,
                              yMax: yMax,
                              chartTopPadding: _turnipChartTopPadding,
                            ),
                          ),
                        ),
                        Positioned(
                          left: (peakPoint.dx - (bubbleWidth / 2)).clamp(
                            0.0,
                            maxBubbleLeft,
                          ),
                          top: (peakPoint.dy - 108).clamp(0, chartRect.top - 4),
                          child: _PeakBubble(
                            width: bubbleWidth,
                            label: peakLabel,
                            value: peakValue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _turnipChartDayLabelGap),
        Padding(
          padding: EdgeInsets.only(
            left: _turnipChartYAxisWidth + _turnipChartAxisGap,
          ),
          child: _DayAxisLabels(peakDayIndex: peakDayIndex),
        ),
      ],
    );
  }

  List<int> _normalizeSize(List<int> source) {
    if (source.length == 6) {
      return source;
    }
    if (source.length < 12) {
      return List<int>.filled(6, 0);
    }

    final normalized = <int>[];
    for (var day = 0; day < 6; day++) {
      final first = source[day * 2];
      final second = source[(day * 2) + 1];
      normalized.add(((first + second) / 2).round());
    }
    return normalized;
  }

  List<Offset> _buildPoints({
    required Rect chartRect,
    required List<int> values,
    required double yMax,
  }) {
    final points = <Offset>[];
    final stepX = values.isEmpty ? 0.0 : chartRect.width / values.length;

    for (var i = 0; i < values.length; i++) {
      final x = chartRect.left + (stepX * i) + (stepX / 2);
      final ratio = (values[i] / yMax).clamp(0, 1);
      final y = chartRect.bottom - (chartRect.height * ratio);
      points.add(Offset(x, y));
    }
    return points;
  }

  double _resolveYMax() {
    var max = 100;
    for (final value in maxValues) {
      if (value > max) {
        max = value;
      }
    }

    final rounded = ((max + 99) ~/ 100) * 100;
    return rounded < 200 ? 200 : rounded.toDouble();
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.yMax, required this.topPadding});

  final double yMax;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      yMax.toInt().toString(),
      ((yMax * (2 / 3))).round().toString(),
      ((yMax * (1 / 3))).round().toString(),
      '0',
    ];

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: labels
            .map(
              (label) => Text(
                label,
                style: AppTextStyles.bodyWithSize(
                  16,
                  color: AppColors.textHint,
                  weight: FontWeight.w700,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DayAxisLabels extends StatelessWidget {
  const _DayAxisLabels({required this.peakDayIndex});

  final int peakDayIndex;

  @override
  Widget build(BuildContext context) {
    final highlightedIndex = peakDayIndex
        .clamp(0, _turnipChartDayLabels.length - 1)
        .toInt();

    return SizedBox(
      height: _turnipChartDayLabelHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepX = _turnipChartDayLabels.isEmpty
              ? 0.0
              : constraints.maxWidth / _turnipChartDayLabels.length;

          return Stack(
            clipBehavior: Clip.none,
            children: List<Widget>.generate(_turnipChartDayLabels.length, (
              index,
            ) {
              final isPeak = index == highlightedIndex;

              return Positioned(
                left: (stepX * index) + (stepX / 2),
                top: 0,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: SizedBox(
                    width: _turnipChartDayLabelWidth,
                    child: Text(
                      _turnipChartDayLabels[index],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyWithSize(
                        18,
                        color: isPeak
                            ? AppColors.turnipAccent
                            : AppColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _PeakBubble extends StatelessWidget {
  const _PeakBubble({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyWithSize(
              14,
              color: AppColors.turnipAccent,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '최대 ',
                style: AppTextStyles.bodyWithSize(
                  16,
                  color: AppColors.black,
                  weight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                '$value',
                style: AppTextStyles.bodyWithSize(
                  18,
                  color: AppColors.black,
                  weight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TurnipLineChartPainter extends CustomPainter {
  _TurnipLineChartPainter({
    required this.minValues,
    required this.maxValues,
    required this.yMax,
    required this.chartTopPadding,
  });

  final List<int> minValues;
  final List<int> maxValues;
  final double yMax;
  final double chartTopPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(
      0,
      chartTopPadding,
      size.width,
      size.height - chartTopPadding,
    );

    _drawGrid(canvas, chartRect);
    _drawSeries(
      canvas,
      chartRect,
      values: minValues,
      color: AppColors.turnipPredictionMinLine,
      strokeWidth: 4,
      dashed: true,
    );
    _drawSeries(
      canvas,
      chartRect,
      values: maxValues,
      color: AppColors.turnipPredictionMaxLine,
      strokeWidth: 4,
      dashed: false,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.borderDefault
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = rect.top + (rect.height * i / 3);
      _drawDashedLine(
        canvas,
        Offset(rect.left, y),
        Offset(rect.right, y),
        paint,
        dashWidth: _turnipChartGridDashWidth,
        dashSpace: _turnipChartGridDashSpace,
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    Rect rect, {
    required List<int> values,
    required Color color,
    required double strokeWidth,
    required bool dashed,
  }) {
    if (values.isEmpty) {
      return;
    }

    final points = _buildPoints(rect, values);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      if (dashed) {
        _drawDashedLine(
          canvas,
          points[i],
          points[i + 1],
          paint,
          dashWidth: _turnipChartPredictionDashWidth,
          dashSpace: _turnipChartPredictionDashSpace,
        );
      } else {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  List<Offset> _buildPoints(Rect rect, List<int> values) {
    final stepX = values.isEmpty ? 0.0 : rect.width / values.length;
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = rect.left + (stepX * i) + (stepX / 2);
      final ratio = (values[i] / yMax).clamp(0, 1);
      final y = rect.bottom - (rect.height * ratio);
      points.add(Offset(x, y));
    }

    return points;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    final distance = (p2 - p1).distance;
    if (distance == 0) {
      return;
    }

    final direction = (p2 - p1) / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final from = p1 + direction * drawn;
      final to = p1 + direction * (drawn + dashWidth).clamp(0, distance);
      canvas.drawLine(from, to, paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TurnipLineChartPainter oldDelegate) {
    return !_sameList(oldDelegate.minValues, minValues) ||
        !_sameList(oldDelegate.maxValues, maxValues) ||
        oldDelegate.yMax != yMax ||
        oldDelegate.chartTopPadding != chartTopPadding;
  }

  bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
