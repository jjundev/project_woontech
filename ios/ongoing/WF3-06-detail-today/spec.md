# WF3-06 — 오늘의 일진 상세 (Insights 일진 카드 탭 목적지)

## User story / motivation

홈 Insights 가로 스크롤의 "일진" 카드를 탭했을 때 push되는 상세 화면. 사용자에게
**사주 원국**(4기둥 + 오행 분포), **오늘의 십성**(사주와 오늘 기운의 관계), **오늘의
합충**(지지 간 작용)을 설명한다. 와이어프레임 기준: `ScrTodayDetailV2` +
`ScrTodayDetailV2Scroll` (screens-02-home-v6.jsx의 WF-03 HTML 내 정의).

## Functional requirements

- 새 View: `TodayDetailView`. `HomeRoute.today` 목적지.
- NavBar:
  - 타이틀 "오늘의 일진".
  - Back(자동).
- 신규 provider `TodayDetailProviding`:
  - `sajuChart: SajuChartData` — 4기둥(년/월/일/시) + 오행 분포 카운트 5개(목·화·토·금·수).
  - `weakElement: WuXingElement?` — 부족한 오행(0개인 오행).
  - `sipseong: SipseongInfo` — `name`(한글), `hanja`(한자), `oneLiner`, `relation`, `examples`.
  - `hapchungEvents: [HapchungEvent]` — 각 event: `branch1`, `branch2`, `kind`("육합"/"월지충"/…), `impact`(positive/negative), `score`, `note`.
  - `dailyMotto: String?` (옵션 — "오늘의 한마디").
  - `dailyTaboo: String?` (옵션 — "오늘의 금기" 요약).
- `MockTodayDetailProvider` 기본값은 와이어프레임 예시(경금 일주, 목1·화3·토1·금3·수0, 수 부족, 편관 십성, 申+巳 육합 +12 / 卯↔酉 월지충 −18 등).
- 레이아웃(수직 `ScrollView`):
  1. **사주 원국 카드**:
     - 제목 "나의 사주 원국" + 우측 보조 "일간(日干) = 나".
     - 4기둥 차트 — 가능하면 WF2의 `SajuMiniChartView`(`ios/Woontech/Features/SajuInput/Result/SajuMiniChartView.swift`) 재사용.
     - 오행 분포 바(목·화·토·금·수 5칸, 각 칸에 한글+한자+숫자).
     - `weakElement`가 있으면 "{한자} 부족 → {한자} 기운의 날 주의" 경고 문구.
  2. **십성 카드**:
     - 제목 "오늘의 십성(十星)" + 보조 "십성: 내 사주와 오늘의 기운이 어떤 관계로 만나는지".
     - 좌측 검정 stamp(56x56) — 한글 name(bold) + 한자.
     - 우측 — `oneLiner`(bold) + `relation`(caption) + `examples`(small caption).
  3. **합충 카드**:
     - 제목 "오늘의 합충(合沖)" + 우측 "합(+) · 충(−)" 범례.
     - `hapchungEvents` 배열 순서대로 row 렌더.
     - impact=positive: 실선 border; impact=negative: 점선 border + 빨강.
     - 각 row: 지지1 박스(한자 + 한글) + 기호(+/↔) + 지지2 박스 + `kind` 배지 + 우측 score(±값).
  4. (옵션) **오늘의 한마디 / 오늘의 금기** — provider 값이 있을 때만 하단 카드로 렌더.
  5. **Disclaimer** 푸터.

## Non-functional constraints

- 재사용 우선: 사주 4기둥 표시는 `SajuMiniChartView` 또는 동등한 뷰 재사용. 재사용이 불가하면 이유를 구현 시 주석 없이 PR 설명에 기록.
- 색/타입: `DesignTokens` + 기존 WF2 색 팔레트 재사용.
- Dynamic Type Large: 합충 row 내 텍스트 wrapping.
- VoiceOver: 사주 원국은 "년주, 월주, 일주, 시주" 순서로 focus; 합충 row는 "{branch1} {기호} {branch2}, {kind}, {score}점".

## Out of scope

- 일진 계산 실제 로직 (전부 mock).
- 사주 차트 신규 디자인 — 기존 `SajuMiniChartView` 재사용 전제.
- 금기 상세 / 실천 상세 — 이 화면은 "일진" 카드에만 연결.
- 공유/저장/북마크.

## Acceptance criteria

1. Insights "일진" 카드 탭 시(WF3-02) `TodayDetailView`가 push된다. (WF3-02 acceptance #10과 짝)
2. NavBar 타이틀은 "오늘의 일진"이고 Back 탭 시 pop된다.
3. 사주 원국 카드는 `TodayDetailProviding.sajuChart`의 4기둥과 오행 분포를 렌더한다.
4. 오행 분포 바는 항상 5칸을 목·화·토·금·수 순서로 표시하며, 각 칸은 `sajuChart`의 카운트를 반영한다.
5. `weakElement`가 `.water`이면 "水 부족 → 水 기운의 날 주의" 문구가 렌더된다. `weakElement`가 nil이면 문구가 숨겨진다.
6. 십성 카드의 stamp에는 `sipseong.name`(한글 bold)과 `sipseong.hanja`(한자 caption)가 렌더된다.
7. 십성 카드 우측 영역에 `oneLiner`, `relation`, `examples` 3줄이 모두 표시된다.
8. 합충 카드는 `hapchungEvents` 배열 순서대로 row를 렌더한다. 배열이 비어 있으면 **합충 카드 자체가 숨겨진다**(섹션 헤더 포함).
9. impact=negative인 row는 점선 border + 빨간 텍스트/border 스타일을 가진다 (시각 조건 검증).
10. 각 row의 score가 양수면 "+12", 음수면 "−18" 형태로 부호와 함께 표시된다.
11. `dailyMotto`가 nil이 아니면 해당 카드가 렌더되고, nil이면 숨겨진다. `dailyTaboo`도 동일.
12. Disclaimer가 ScrollView 최하단 요소로 존재한다.
13. `TodayDetailProviding`을 사용자 정의 mock으로 교체하면 사주 원국·십성·합충의 모든 필드가 해당 mock 값을 반영한다 (단위 테스트).
14. Dynamic Type XL에서 합충 row 내부 텍스트가 wrapping되어 우측 score가 잘리지 않는다 (UI 테스트).
15. 사주 원국 차트 렌더에 `SajuMiniChartView`가 재사용된다 (import/참조 확인).
