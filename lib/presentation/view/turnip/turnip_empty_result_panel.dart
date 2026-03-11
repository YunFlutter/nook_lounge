import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_owl_empty_state.dart';

class TurnipEmptyResultPanel extends StatelessWidget {
  const TurnipEmptyResultPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppOwlEmptyState(
      useCard: false,
      minHeight: 260,
      title: '데이터가 없어요.',
      subtitle: '일요일 매수가와 월~토 가격을 입력하고\n계산하기를 눌러주세요.',
      imageSemanticLabel: '무주식 데이터 없음 이미지',
    );
  }
}
