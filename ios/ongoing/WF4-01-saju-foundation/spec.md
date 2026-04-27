# WF4-01 — 사주 탭 Shell + NavigationStack + DI 스캐폴드

## User story / motivation

WF3 홈 탭과 동일한 위계로 동작하는 **사주 탭(TabBar index 2)** 의 기반 구조를 구축한다.
이후 슬라이스(02~07)가 올라탈 `SajuTabView` 컨테이너, 사주 탭 전용 NavigationStack과
타입 안전한 라우트 enum, DI 컨테이너(프로토콜 6종 + Mock 구현체), 그리고 가장 단순한
**상단 헤더(타이틀 "사주" + 우측 placeholder 아이콘)** 까지를 하나의 테스트 가능한
단위로 묶는다. 컨텐츠 슬롯은 이번 단계에서 "준비중" placeholder로 둔다.

## Functional requirements

- 앱의 메인 TabBar(WF3에서 도입된 구조)에 **사주 탭(index 2)** 이 추가된다. 탭 셀렉트 시
  `SajuTabView`가 렌더된다. 다른 탭(홈/투자/마이) 의 동작은 변경하지 않는다.
- `SajuTabView`는 상단 고정 **Header**(타이틀 "사주" 좌측 정렬 + 우측 원형 placeholder
  아이콘 1개) + 하단 고정 **TabBar**(공통, active=2) + 가운데 컨텐츠 슬롯으로 구성한다.
  컨텐츠 슬롯은 02~03 슬라이스에서 채워지며, 이번 단계에서는 빈 `ScrollView` + "준비중"
  placeholder 텍스트만 렌더한다.
- `SajuTabView` 내부에 사주 탭 전용 **NavigationStack** 이 포함된다(홈 탭의
  `HomeDashboardView` NavigationStack과 인스턴스 분리).
- 타입 안전한 라우트 enum `SajuRoute` 5케이스를 선언한다:
  1. `elements` — 오행 분포 상세(WF4-04에서 사용).
  2. `tenGods` — 십성 분석 상세(WF4-05).
  3. `learn` — 사주 공부 리스트(WF4-06).
  4. `lesson(id: String)` — 레슨 상세(WF4-07). associated value로 레슨 식별자 전달.
  5. `daewoonPlaceholder` / `hapchungPlaceholder` / `yongsinPlaceholder` — 대운·합충·용신
     상세는 본 WF4 범위에서 제외이며 placeholder 화면("준비중")으로 라우팅한다.
- 각 `SajuRoute` 케이스에 대응하는 목적지 View가 "준비중" placeholder로 존재해, 프로그램적
  push 시 해당 placeholder가 보인다. 이후 슬라이스(WF4-04~07)에서 placeholder를 실제
  화면으로 교체한다.
- **DI 프로토콜 6종 선언**(`ios/Woontech/Features/Saju/Providers/` 하위):
  1. `UserSajuOriginProviding` — `pillars: [Pillar]` (時/日/月/年 4개), `dayMasterLine: String`
     (예: "일간 丙火 · 양의 불 — 따뜻함, 표현력, 리더십").
  2. `SajuCategoriesProviding` — 5개 카테고리(`elements`, `tenGods`, `daewoon`, `hapchung`,
     `yongsin`) 각각의 요약 문자열 + 선택적 badge(예: "부족: 水", "전환기", "핵심") 시그니처.
     (WF4-02에서 본격 사용.)
  3. `SajuElementsDetailProviding` — (시그니처만; WF4-04에서 사용).
  4. `SajuTenGodsDetailProviding` — (시그니처만; WF4-05에서 사용).
  5. `SajuLearningPathProviding` — 주간 진행률, 코스 리스트, 코스 셀 상태(완료/현재/미완료/
     잠금) 시그니처. (WF4-03/06에서 공동 사용.)
  6. `SajuLessonProviding` — (시그니처만; WF4-07에서 사용).
- 각 프로토콜에 대응하는 `MockXxx` 구현체를 함께 제공한다. Mock 기본값은 와이어프레임
  예시(원국 時庚申 / 日丙午 / 月辛卯 / 年庚午, 일간 한줄 "양의 불…", 카테고리 5개 요약
  텍스트, 학습 경로 4코스 등).
- 주입 방식: `SajuTabDependencies` 단일 struct에 6개 providing 필드를 모아 생성자 주입(또는
  `@EnvironmentObject`)으로 `SajuTabView`에 전달한다. 테스트 시 임의 mock 교체 가능.
- 런치 인자 **`-openSajuTab`** 으로 사주 탭에 바로 진입하는 동작을 지원한다. 이 인자가
  주어지면 앱 부팅 후 곧바로 TabBar index 2가 활성화된다(테스트 안정성). 기본 dependencies
  는 `MockSajuTabDependencies`.

## Non-functional constraints

- iOS 17+ SwiftUI(NavigationStack 사용). 세이프 에어리어 준수 — Header는 status bar 영역을
  침범하지 않고, TabBar는 home indicator 영역을 가리지 않는다.
- 색상/간격/타이포는 `ios/Woontech/Shared/DesignTokens.swift` 재사용. 사주 탭 전용 토큰이
  필요하면 동일 파일에 추가.
- VoiceOver: Header 타이틀 = "사주", 우측 아이콘 = "사주 메뉴"(임시 레이블, 후속 슬라이스
  에서 의미 부여). TabBar 사주 셀 = "사주 탭".
- Dynamic Type Large까지 Header 잘림 없음.
- 모든 텍스트 리터럴은 로컬라이즈 키로 분리(1차 한국어).

## Out of scope

- 내 원국 4주 카드 실제 렌더, 5개 카테고리 카드, "근거 보기" 링크 — **WF4-02**.
- 사주 공부하기 섹션(연속 배지/오늘의 한 가지/학습 경로 그리드/용어 사전/Disclaimer/
  하단 카운트 표시) — **WF4-03**.
- 오행 분포 상세 본문 — **WF4-04**(이번 단계에서는 placeholder 화면만).
- 십성 분석 상세 본문 — **WF4-05**(placeholder만).
- 사주 공부 리스트 본문 — **WF4-06**(placeholder만).
- 레슨 상세 본문 — **WF4-07**(placeholder만).
- 대운·세운 / 합충형파 / 용신·희신 상세 — 본 WF4 전체 범위에서 제외(placeholder route만).
- WF2 `SajuResultModel`/`SajuAnalysisEngine`과의 실제 데이터 연동(전부 mock으로 처리).
- 사주 탭에서의 PRO 페이월·결제 진입.

## Acceptance criteria

각 항목은 unit/UI 테스트로 검증 가능해야 한다.

1. TabBar index 2를 탭하면 `SajuTabView`가 렌더된다.
2. 런치 인자 `-openSajuTab`으로 앱을 시작하면, 부팅 직후 TabBar index 2가 활성 상태이며
   `SajuTabView`가 화면에 표시된다.
3. `SajuTabView` 상단 Header에 "사주" 타이틀이 항상 표시되고, 우측에 placeholder 원형
   아이콘이 표시된다.
4. `SajuTabView`의 컨텐츠 슬롯에는 "준비중" placeholder 텍스트가 표시된다(이후 슬라이스
   에서 교체될 자리).
5. `SajuTabView` 내부에 NavigationStack이 존재하며, `SajuRoute` enum의 7개 케이스(`elements`,
   `tenGods`, `learn`, `lesson(id:)`, `daewoonPlaceholder`, `hapchungPlaceholder`,
   `yongsinPlaceholder`)가 컴파일된다.
6. 각 `SajuRoute` 케이스로 프로그램적 push 시 해당 목적지 View가 push된다. 본 슬라이스에서
   는 7케이스 전부 "준비중" placeholder로 동일하게 표시된다(UI 테스트 — push API는 hidden
   button으로 트리거 허용).
7. `SajuRoute.lesson(id: "L-001")`로 push 시 placeholder 화면에 식별자 "L-001"이 표시된다
   (associated value 전달 검증).
8. `SajuTabDependencies`의 6개 providing 필드를 각각 임의 mock으로 교체하여 `SajuTabView`를
   주입할 수 있고, 컴파일 및 렌더가 정상 동작한다.
9. `MockUserSajuOriginProvider`의 기본 `pillars` 길이가 4(時/日/月/年)이며 `dayMasterLine`이
   비어 있지 않다(예: "일간 丙火 …").
10. `MockSajuLearningPathProvider`의 코스 리스트 기본값이 4개(입문/오행/십성/대운)이며 각
    코스에 진행률 값(0.0~1.0)이 포함된다.
11. 사주 탭이 활성 상태일 때 다른 탭(홈/투자/마이) 으로 이동했다가 다시 사주 탭으로
    돌아오면, 사주 탭 NavigationStack의 path가 보존된다(탭 스위칭 시 path 초기화 안 됨).
12. VoiceOver로 TabBar 사주 셀에 focus하면 "사주 탭"이 읽히고, Header 타이틀에 focus하면
    "사주"가 읽힌다.
13. Dynamic Type XL에서 Header와 TabBar의 텍스트가 잘리거나 겹치지 않는다(UI 테스트).
14. 사주 탭 NavigationStack과 홈 탭 `HomeDashboardView` NavigationStack이 서로 다른
    인스턴스이며, 한쪽 path 변경이 다른 쪽에 영향을 주지 않는다.
