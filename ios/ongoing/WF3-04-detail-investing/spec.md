# WF3-04 — 투자 태도 상세 (Hero 탭 목적지)

## User story / motivation

홈 Hero 카드 탭 시 push되는 **투자 태도 상세** 화면. 원형 지수(예: 72점)가 어떻게
구성되는지, 사용자의 태도 유형은 무엇인지, 어떤 실천을 권하는지 안내한다.
Hero와는 **완전히 독립된 provider**(`InvestingAttitudeDetailProviding`)에서 데이터를
받으며, `HeroInvestingProviding`과 타입·인스턴스 어느 쪽도 공유하지 않는다.

## Functional requirements

- 새 View: `InvestingAttitudeDetailView`. `HomeDashboardView`의 NavigationStack에서
  `HomeRoute.investing` 케이스의 목적지.
- NavBar:
  - 타이틀 "투자 태도".
  - Back 버튼(자동) — 탭 시 pop.
- 독립 provider `InvestingAttitudeDetailProviding` (신규 정의, `Features/Home/Detail/Investing/` 하위):
  - `score: Int` (0~100, 범위 밖 clamp).
  - `attitudeName: String` (예: "신중한 탐험가").
  - `oneLiner: String`.
  - `breakdown: [ScoreBreakdownItem]` — 각 item은 `name`, `value`(0~100), `description`.
  - `recommendations: [String]`.
- `MockInvestingAttitudeDetailProvider` 기본값:
  - score=72, attitudeName="신중한 탐험가", oneLiner="공격보다 관찰이 내 성향에 맞아요",
  - breakdown 3건(예: 위험 선호·분석 의존·감정 통제), recommendations 3건.
- 레이아웃(수직 `ScrollView`):
  1. 상단 큰 원형 지수(숫자 + `/100`).
  2. 태도 이름(bold) + 한줄 설명(caption).
  3. "점수 구성" 섹션 — breakdown을 카드 리스트로. 각 item: name + value bar + description.
  4. "추천 액션" 섹션 — recommendations를 bullet 리스트로.
  5. Disclaimer 푸터.
- `HomeDependencies`(또는 별도 주입)를 통해 `InvestingAttitudeDetailProviding`도 주입
  가능하게 구성. 테스트 시 mock 교체 가능.

## Non-functional constraints

- iOS 17+ NavigationStack toolbar API 사용.
- Dynamic Type Large까지 원형 지수/breakdown bar/추천 문구 모두 wrapping OK.
- VoiceOver: 원형 지수 = "{score}점", breakdown item = "{name}, {value}점, {description}".
- 색상/간격은 `DesignTokens` 재사용.

## Out of scope

- Hero 카드 자체 (WF3-02에서 완료).
- 실제 점수 계산 로직 — 전부 mock.
- WF2 `SajuResultModel` / `SajuAnalysisEngine` 연동 (완전 독립).
- 상세 화면 내 추가 네비게이션 (학습 콘텐츠 딥링크 등).
- 공유/저장/북마크.

## Acceptance criteria

1. Hero 카드 탭 시(WF3-02) `InvestingAttitudeDetailView`가 push된다. (WF3-02 acceptance #6과 짝을 이룸)
2. NavBar 타이틀은 "투자 태도"이고, Back 버튼 탭 시 pop되어 홈으로 복귀한다.
3. 원형 지수는 `InvestingAttitudeDetailProviding.score` 값을 표시한다. score=-10 주입 시 0으로, score=120 주입 시 100으로 clamp되어 렌더된다.
4. 태도 이름과 한줄 설명은 provider의 `attitudeName`, `oneLiner`를 그대로 바인딩한다.
5. breakdown 배열이 3개이면 카드 3개가 렌더되고, 각 카드는 해당 item의 name/value bar/description을 표시한다.
6. breakdown 배열이 비어 있으면 "점수 구성" 섹션 전체(헤더 포함)가 숨겨진다.
7. recommendations 배열이 N개이면 bullet N개가 렌더된다. 빈 배열이면 "추천 액션" 섹션 전체가 숨겨진다.
8. Disclaimer 문구가 ScrollView 최하단에 렌더된다.
9. `InvestingAttitudeDetailProviding`은 `HeroInvestingProviding`과 별개의 프로토콜이며, 한쪽 구현체를 다른 쪽으로 사용할 수 없다 (컴파일 타임 분리 + 코드 리뷰로 확인).
10. 테스트 시 `InvestingAttitudeDetailProviding`을 임의 mock으로 교체하면 화면의 모든 바인딩된 값이 해당 mock 데이터를 반영한다.
11. VoiceOver focus 순서: NavBar 타이틀 → 원형 지수 → 태도명 → 한줄 → breakdown → recommendations → disclaimer.
12. Dynamic Type XL에서 breakdown description이 wrapping되어 잘리지 않는다.
