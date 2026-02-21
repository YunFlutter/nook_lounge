import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';

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
          height: 260,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(width: 34, child: _YAxisLabels(yMax: yMax)),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chartRect = Rect.fromLTWH(
                      0,
                      36,
                      constraints.maxWidth,
                      constraints.maxHeight - 36,
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
                              chartTopPadding: 36,
                            ),
                          ),
                        ),
                        Positioned(
                          left: (peakPoint.dx - 52).clamp(
                            0,
                            constraints.maxWidth - 104,
                          ),
                          top: (peakPoint.dy - 108).clamp(0, chartRect.top - 4),
                          child: _PeakBubble(
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
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(6, (index) {
            const labels = <String>['월', '화', '수', '목', '금', '토'];
            final isPeak = index == peakDayIndex;
            return Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isPeak
                      ? AppColors.primaryDefault
                      : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }),
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
    final stepX = values.length == 1
        ? 0.0
        : chartRect.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final x = chartRect.left + (stepX * i);
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
  const _YAxisLabels({required this.yMax});

  final double yMax;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      yMax.toInt().toString(),
      ((yMax * (2 / 3))).round().toString(),
      ((yMax * (1 / 3))).round().toString(),
      '0',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: labels
            .map(
              (label) => Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _PeakBubble extends StatelessWidget {
  const _PeakBubble({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
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
            style: const TextStyle(
              color: AppColors.primaryDefault,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            '최대',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
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
      color: AppColors.badgeYellowText,
      strokeWidth: 4,
      dashed: true,
    );
    _drawSeries(
      canvas,
      chartRect,
      values: maxValues,
      color: AppColors.primaryDefault,
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
        _drawDashedLine(canvas, points[i], points[i + 1], paint);
      } else {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  List<Offset> _buildPoints(Rect rect, List<int> values) {
    final stepX = values.length == 1 ? 0.0 : rect.width / (values.length - 1);
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = rect.left + (stepX * i);
      final ratio = (values[i] / yMax).clamp(0, 1);
      final y = rect.bottom - (rect.height * ratio);
      points.add(Offset(x, y));
    }

    return points;
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;

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
