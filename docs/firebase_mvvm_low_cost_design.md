# Nook Lounge Firebase 저비용 MVVM 설계

## 1) 이미지 기반 앱 플로우 요약
1. 스플래시/데이터 로딩
2. 로그인(Apple, Google, 비회원)
3. 섬 생성(여권 등록)
4. 메인 탭 진입: 비행장 / 마켓 / 홈 / 도감 / 무주식
5. 상세 플로우: 거래 등록/수락, 방문 대기열, 도도코드, 신고, 도감 검색

## 2) 비용 최소화 원칙
- 원칙 A: **정적 마스터 데이터는 Firebase에 저장하지 않음**
  - `assets/json`(주민/도감/아이템)을 앱 로컬에서 로드
  - Firebase에는 "사용자 상태"만 저장(보유 여부, 거래, 방문 대기)
- 원칙 B: **요약 문서 1개 + 상세 컬렉션 분리**
  - 홈 첫 렌더는 `homeSummaries/{islandId}` 1 read
  - 상세 탭 진입 시에만 추가 fetch
- 원칙 C: **실시간 구독 범위 최소화**
  - 실시간은 "비행장 대기열", "진행중 거래"만
  - 도감/프로필/기록성 화면은 on-demand fetch
- 원칙 D: **문서 구조 비정규화 + fan-out 최소화**
  - 홈 집계를 미리 써두고 조회 시 조인 금지
- 원칙 E: **페이징 기본값 강제**
  - 리스트는 `limit(20)` 기본, 무한스크롤은 마지막 문서 커서 사용

## 3) Firestore 제안 스키마
- `users/{uid}`
  - `primaryIslandId`, `updatedAt`
- `users/{uid}/islands/{islandId}`
  - 섬 프로필(섬 이름, 반구, 특산물, 대표 주민)
- `users/{uid}/homeSummaries/{islandId}`
  - 주민 수, 도감 진행률, 마지막 동기화 시간
- `marketPosts/{postId}`
  - 거래 카드(요약 필드 중심)
- `airportQueues/{islandId}`
  - 방문 대기/입장 상태
- `reports/{reportId}`
  - 신고 기록

## 4) MVVM 계층
- View: `lib/presentation/view/*`
- ViewModel: `lib/presentation/viewmodel/*` (`StateNotifier` + Riverpod)
- ViewState: `lib/presentation/state/*` (`freezed` immutable state)
- Repository: `lib/domain/repository/*` + `lib/data/repository/*`
- DataSource:
  - Firebase: 인증/섬/실시간 상태
  - Local JSON: 도감/아이템/주민 검색

## 5) 애니메이션 정책
- 모든 화면/요소는 공통 토큰 사용
  - `AppMotion.screen`, `AppMotion.element`, `AppMotion.press`
- 페이지 진입: `AnimatedFadeSlide`
- 버튼 인터랙션: `AnimatedScaleButton`
- 탭 전환: `AnimatedSwitcher`

## 6) 운영 팁
- Cloud Functions는 "필요할 때만" 사용
  - 예: 도도코드 만료/정리 배치, 거래 상태 전이 검증
- Firestore TTL(만료 데이터 자동 삭제) 적용
  - 방문 대기, 만료된 거래 카드, 일회성 알림
- Analytics/Crashlytics 이벤트는 최소 핵심 이벤트만 수집
