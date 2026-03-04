import 'package:flutter/widgets.dart';

class AppSpacing {
  const AppSpacing._();

  /// 유지보수 포인트:
  /// 프로젝트 공통 spacing 스케일입니다.
  /// 디자인 기준 간격이 바뀌면 이 파일만 수정해 화면 전반 간격을 통일합니다.
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s22 = 22;
  static const double s24 = 24;
  static const double s26 = 26;
  static const double s28 = 28;
  static const double s30 = 30;
  static const double s32 = 32;
  static const double s40 = 40;

  /// 유지보수 포인트:
  /// 페이지 기본 좌우 여백(20px)
  static const double pageHorizontal = s20;
  static const double pageTop = s10;
  static const double pageBottom = s20;

  /// 유지보수 포인트:
  /// 도감 화면 전용 좌우 여백(10px)
  static const double catalogHorizontal = s10;

  /// 유지보수 포인트:
  /// 모달 여백 규칙(바깥 10px, 내부 20px)
  static const double modalOuter = s10;
  static const double modalInner = s20;

  /// 유지보수 포인트:
  /// 리스트/스크롤 기본 패딩 프리셋입니다.
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );
  static const EdgeInsets pageContentPadding = EdgeInsets.fromLTRB(
    pageHorizontal,
    pageTop,
    pageHorizontal,
    pageBottom,
  );

  /// 유지보수 포인트:
  /// 하단 플로팅 액션 버튼이 있는 리스트의 기본 하단 여백입니다.
  static const double fabListBottomInset = 98;
}
