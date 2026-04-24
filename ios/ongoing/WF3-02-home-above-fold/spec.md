# WF3-02 — 홈 above-the-fold (Hero + Insights)

## User story / motivation

홈 탭 진입 시 사용자가 가장 먼저 보는 **Hero(투자 태도 원형 지수 + 한줄)** 와
**Insights(가로 스크롤 3카드 — 금기/일진/실천)** 를 구현한다. 각 카드는 탭 시
`HomeDashboardView`의 NavigationStack에 해당 상세 라우트를 push한다. 이 슬라이스는
WF3-01에서 선언만 해둔 `HeroInvestingProviding`·`InsightsProviding`의 mock 구현과
데이터 바인딩을 완성한다.

## Functional requirements

- **Section 1 Hero** (HomeDashboardView 컨텐츠 슬롯 상단):
  - 날짜 라벨: `YYYY.MM.DD 요일` 포맷 (예: "2026.04.23 목요일"). 포맷터는 `HeroInvestingProviding.displayDate`로부터 주입된 날짜를 사용.
  - 그리팅 문구: `"{displayName}님, 오늘의 투자 태도예요"` (displayName은 `UserProfileProviding`에서).
  - 카드 내부:
    - "투자 관점" 배지(작은 pill).
    - 원형 지수: 숫자 + `/100` (0~100 정수 범위, 범위 밖이면 clamp).
    - 한줄 카피: 큰 본문 텍스트.
    - 카드 하단 우측 "상세 보기 ›" 인디케이터.
  - 카드 전체(원형/한줄/상세 보기 포함 전 영역) 탭 → `HomeRoute.investing` push.
- **Section 3 Insights** (Hero 아래):
  - 섹션 라벨 "오늘의 인사이트".
  - `ScrollView(.horizontal)`에 **항상 3카드** 렌더, **고정 순서** `[금기, 일진, 실천]`.
  - 각 카드 컴포넌트:
    - 상단 badge(label + 지정 color, 예: 금기=빨강, 일진=회색, 실천=초록).
    - 아이콘 (큰 사이즈).
    - title (bold).
    - desc (multi-line, 줄바꿈 `\n` 유지).
    - 하단 label(작은 캡션 — "오늘의 금기" 등).
  - 카드 탭 라우팅:
    - 금기 → `HomeRoute.tabooPlaceholder` push.
    - 일진 → `HomeRoute.today` push.
    - 실천 → `HomeRoute.practicePlaceholder` push.
- `MockHeroInvestingProvider` 기본값: score=72, oneLiner="공격보다 관찰이 내 성향에 맞아요", displayDate=2026-04-23.
- `MockInsightsProvider` 기본값: 와이어프레임의 3카드 고정 데이터.

## Non-functional constraints

- 가로 스크롤 카드 너비 고정, 카드 간 8pt 간격, 좌우 16pt padding.
- Dynamic Type Large까지 Hero 원형 지수와 Insights 카드 내부 텍스트가 wrapping되며 잘림 없음.
- VoiceOver: 원형 지수 = "72점", Insights 각 카드 = "{label}, {title}".
- Hero 카드 탭 영역은 단일 hit-test (카드 위 자식 뷰가 탭 가로채지 않음).

## Out of scope

- Header (WF3-01 완료).
- Below-fold (Weekly/Share/PRO/Disclaimer — WF3-03).
- 투자 태도 상세 실제 화면 (WF3-04).
- 일진 상세 실제 화면 (WF3-06).
- 금기/실천 상세 실제 화면 — placeholder route만 push.
- Pull-to-refresh.

## Acceptance criteria

1. Hero 카드는 Header 바로 아래, Insights는 Hero 바로 아래 순서로 렌더된다.
2. 날짜 라벨은 `HeroInvestingProviding.displayDate`를 `YYYY.MM.DD 요일` 포맷으로 표시한다. (unit test: provider에 2026-01-01 주입 시 "2026.01.01 목요일" 렌더)
3. 그리팅은 `UserProfileProviding.displayName` 값을 반영한다. (displayName="민수" mock 주입 시 "민수님, 오늘의 투자 태도예요")
4. 원형 지수는 `HeroInvestingProviding.score` 정수를 표시한다. score=120 mock 주입 시 화면에는 `100`으로 clamp.
5. 한줄 카피는 `HeroInvestingProviding.oneLiner` 값을 표시한다.
6. Hero 카드 탭 시 `HomeDashboardView`의 NavigationStack path에 `HomeRoute.investing`이 append된다 (스파이/path 검증).
7. Insights 영역은 항상 3카드를 `[금기, 일진, 실천]` 순서로 렌더한다 (순서는 provider 데이터와 무관하게 고정).
8. 각 Insight 카드는 `InsightsProviding`이 반환한 해당 slot의 데이터(badge, icon, title, desc, label)를 바인딩한다.
9. 금기 카드 탭 시 path에 `tabooPlaceholder`가 append된다.
10. 일진 카드 탭 시 path에 `today`가 append된다.
11. 실천 카드 탭 시 path에 `practicePlaceholder`가 append된다.
12. Dynamic Type XL에서 Hero 원형 지수와 한줄 카피가 한 줄/여러 줄로 wrapping되어 잘리지 않는다 (UI 테스트).
13. 가로 스크롤로 3번째 카드(실천)까지 접근 가능하다 (UI 테스트 — 스와이프 후 label 가시).
14. `MockInsightsProvider`를 card 배열 2개만 반환하도록 교체해도 화면은 정해진 3슬롯을 렌더하며 누락 슬롯은 empty/placeholder로 복구 (또는 precondition 실패로 테스트가 명시적으로 실패). 어느 동작을 채택했는지 spec 구현 시 고정.
