import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';

class TurnipPredictionTable extends StatelessWidget {
  const TurnipPredictionTable({
    required this.minValues,
    required this.maxValues,
    required this.avgValues,
    super.key,
  });

  final List<int> minValues;
  final List<int> maxValues;
  final List<int> avgValues;

  static const List<String> _dayLabels = <String>['월', '화', '수', '목', '금', '토'];
  static const double _leadingLabelWidth = 44;
  static const double _leadingLabelStartPadding = 10;
  static const double _rowVerticalPadding = 10;

  @override
  Widget build(BuildContext context) {
    if (minValues.length != 6 ||
        maxValues.length != 6 ||
        avgValues.length != 6) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: <Widget>[
          _buildHeaderRow(),
          _buildValueRow(label: '최소', values: minValues),
          _buildValueRow(label: '최대', values: maxValues),
          _buildValueRow(label: '평균', values: avgValues, isLast: true),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _rowVerticalPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        children: <Widget>[
          _buildLeadingCell(
            '구분',
            style: AppTextStyles.bodyWithSize(
              13,
              color: AppColors.textSecondary,
              weight: FontWeight.w800,
            ),
          ),
          ..._dayLabels.map(
            (day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyWithSize(
                  13,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow({
    required String label,
    required List<int> values,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _rowVerticalPadding),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderDefault),
              ),
            ),
      child: Row(
        children: <Widget>[
          _buildLeadingCell(
            label,
            style: AppTextStyles.bodyWithSize(
              14,
              color: AppColors.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
          ...values.map(
            (value) => Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyWithSize(
                  14,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingCell(String label, {required TextStyle style}) {
    return SizedBox(
      width: _leadingLabelWidth,
      child: Padding(
        // 유지보수 포인트:
        // 첫 열 폭은 차트의 y축(34) + 간격(10)과 맞춰야
        // x축 요일 라벨과 표의 월~토 열 중심이 같은 기준선에 맞습니다.
        padding: const EdgeInsets.only(left: _leadingLabelStartPadding),
        child: Text(label, style: style),
      ),
    );
  }
}
