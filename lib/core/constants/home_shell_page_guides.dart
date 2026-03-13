import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/domain/model/page_guide_content.dart';
import 'package:nook_lounge_app/domain/model/page_guide_step.dart';

PageGuideContent? resolveHomeShellPageGuide(int tabIndex) {
  switch (tabIndex) {
    case 0:
      return _airportGuide;
    case 1:
      return _marketGuide;
    case 2:
      return _homeGuide;
    case 3:
      return _catalogGuide;
    case 4:
      return _turnipGuide;
    default:
      return null;
  }
}

const PageGuideContent _airportGuide = PageGuideContent(
  storageKey: 'home_shell_airport_tab_v1',
  badgeLabel: '비행장 첫 안내',
  title: '손님 맞이를 한 화면에서 관리해요.',
  description: '게이트 개방부터 방문 승인, 현재 방문자 확인까지 비행장 흐름을 순서대로 볼 수 있어요.',
  primaryActionLabel: '비행장 둘러보기',
  steps: <PageGuideStep>[
    PageGuideStep(
      title: '1. 게이트를 열고 규칙을 확인해요',
      description: '상단 게이트 토글과 규칙 편집으로 손님을 받을 준비를 먼저 마칩니다.',
      icon: Icons.flight_takeoff_rounded,
      accentColor: AppColors.primaryDefault,
    ),
    PageGuideStep(
      title: '2. 도도 코드를 등록해요',
      description: '손님이 입장할 수 있도록 현재 사용할 코드를 입력하고 공유할 수 있어요.',
      icon: Icons.password_rounded,
      accentColor: AppColors.navActive,
    ),
    PageGuideStep(
      title: '3. 대기열과 방문자를 관리해요',
      description: '대기 요청 승인, 입장 중인 손님 확인, 내 방문 신청 현황까지 이어서 확인합니다.',
      icon: Icons.groups_rounded,
      accentColor: AppColors.textAccent,
    ),
  ],
);

const PageGuideContent _marketGuide = PageGuideContent(
  storageKey: 'home_shell_market_tab_v1',
  badgeLabel: '마켓 첫 안내',
  title: '거래 탐색부터 등록까지 빠르게 이어집니다.',
  description: '검색과 카테고리 필터로 원하는 글을 찾고, 상세 화면에서 거래 제안 흐름까지 이어갈 수 있어요.',
  primaryActionLabel: '마켓 둘러보기',
  steps: <PageGuideStep>[
    PageGuideStep(
      title: '1. 검색과 카테고리로 글을 좁혀요',
      description: '상단 검색창과 칩 필터를 함께 써서 필요한 거래만 빠르게 찾을 수 있어요.',
      icon: Icons.search_rounded,
      accentColor: AppColors.primaryDefault,
    ),
    PageGuideStep(
      title: '2. 카드에서 거래 조건을 확인해요',
      description: '카드만 봐도 작성자, 제안 아이템, 원하는 조건을 한 번에 파악할 수 있어요.',
      icon: Icons.storefront_rounded,
      accentColor: AppColors.navActive,
    ),
    PageGuideStep(
      title: '3. 상세로 들어가 제안하거나 관리해요',
      description: '내 글은 수정·완료·삭제를, 다른 사람 글은 거래 제안과 상세 확인을 이어서 진행합니다.',
      icon: Icons.swap_horiz_rounded,
      accentColor: AppColors.accentDeepOrange,
    ),
  ],
);

const PageGuideContent _homeGuide = PageGuideContent(
  storageKey: 'home_shell_home_tab_v1',
  badgeLabel: '홈 첫 안내',
  title: '섬 운영 현황을 요약해서 보는 대시보드예요.',
  description: '대표 섬을 기준으로 주민, 무주식, 도감 진행도, 위시리스트까지 한 번에 체크할 수 있어요.',
  primaryActionLabel: '홈 둘러보기',
  steps: <PageGuideStep>[
    PageGuideStep(
      title: '1. 대표 섬을 선택해요',
      description: '앱바의 섬 선택 버튼에서 현재 관리할 섬을 바꾸면 카드들이 함께 갱신됩니다.',
      icon: Icons.home_work_rounded,
      accentColor: AppColors.primaryDefault,
    ),
    PageGuideStep(
      title: '2. 핵심 상태를 위에서 아래로 훑어요',
      description: '섬 정보와 주민 현황, 무주식 요약을 순서대로 확인하면 오늘 할 일을 빠르게 파악할 수 있어요.',
      icon: Icons.dashboard_rounded,
      accentColor: AppColors.navActive,
    ),
    PageGuideStep(
      title: '3. 필요한 섹션에서 상세 화면으로 이동해요',
      description: '도감 진행도와 위시리스트 섹션을 눌러 더 자세한 작업 화면으로 이어집니다.',
      icon: Icons.arrow_forward_rounded,
      accentColor: AppColors.textAccent,
    ),
  ],
);

const PageGuideContent _catalogGuide = PageGuideContent(
  storageKey: 'home_shell_catalog_tab_v1',
  badgeLabel: '도감 첫 안내',
  title: '수집 진행도를 범주별로 관리해요.',
  description: '주민, 박물관, 컬렉션 진척도를 요약해서 보고 항목별 상세로 내려가 체크할 수 있어요.',
  primaryActionLabel: '도감 둘러보기',
  steps: <PageGuideStep>[
    PageGuideStep(
      title: '1. 상단에서 주민 현황을 확인해요',
      description: '현재 섬에 모아둔 주민 슬롯을 빠르게 보고, 비어 있는 자리도 바로 확인할 수 있어요.',
      icon: Icons.people_alt_rounded,
      accentColor: AppColors.primaryDefault,
    ),
    PageGuideStep(
      title: '2. 박물관 진행도를 비교해요',
      description: '곤충, 물고기, 미술품처럼 범주별 수집률을 요약 카드로 확인할 수 있어요.',
      icon: Icons.museum_rounded,
      accentColor: AppColors.navActive,
    ),
    PageGuideStep(
      title: '3. 컬렉션 페이지에서 세부 체크를 이어가요',
      description: '섹션 제목이나 항목을 눌러 상세 페이지로 들어가 실제 수집 상태를 업데이트합니다.',
      icon: Icons.checklist_rounded,
      accentColor: AppColors.accentDeepOrange,
    ),
  ],
);

const PageGuideContent _turnipGuide = PageGuideContent(
  storageKey: 'home_shell_turnip_tab_v1',
  badgeLabel: '무주식 첫 안내',
  title: '주간 무 가격을 입력하면 예측 차트를 볼 수 있어요.',
  description: '일요일 구매가와 월-토 오전/오후 가격을 채워 넣으면서 패턴 예측을 업데이트하는 화면입니다.',
  primaryActionLabel: '무주식 둘러보기',
  steps: <PageGuideStep>[
    PageGuideStep(
      title: '1. 일요일 매수 가격을 먼저 맞춰요',
      description: '상단 스텝 버튼으로 무파니 구매가를 입력하면 계산의 기준값이 됩니다.',
      icon: Icons.attach_money_rounded,
      accentColor: AppColors.turnipAccent,
    ),
    PageGuideStep(
      title: '2. 요일별 오전/오후 가격을 채워요',
      description: '가로 카드에서 날짜를 선택하고 실제 가격을 순서대로 입력하면 예측이 정교해집니다.',
      icon: Icons.calendar_view_day_rounded,
      accentColor: AppColors.navActive,
    ),
    PageGuideStep(
      title: '3. 차트와 표로 패턴을 읽어요',
      description: '하단 그래프와 표를 통해 고점 예상 구간을 보고, 필요하면 초기화로 다시 시작할 수 있어요.',
      icon: Icons.auto_graph_rounded,
      accentColor: AppColors.primaryDefault,
    ),
  ],
);
