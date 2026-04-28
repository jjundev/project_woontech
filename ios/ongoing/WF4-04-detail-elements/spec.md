# WF4-04 — 오행 분포 상세 (사주 탭 카테고리 1번 목적지)

## User story / motivation

사주 탭 홈 카테고리 카드 "오행 분포" 탭 시 push되는 **오행 분포 상세** 화면. 사용자의
사주 8글자에 분포된 5행(火·木·土·金·水)의 비율을 막대 차트로 보여주고, 부족한 원소를
강조하며, 보완을 위한 가이드(방향/색상/시간/행동)를 제공한다. above-fold 카테고리 카드와는
**완전히 독립된 provider**(`SajuElementsDetailProviding`)에서 데이터를 받으며,
`SajuCategoriesProviding`과 타입·인스턴스 어느 쪽도 공유하지 않는다.

## Functional requirements

- 새 View: `SajuElementsDetailView`. `SajuTabView`의 NavigationStack에서 `SajuRoute.elements`
  케이스의 목적지(WF4-01의 placeholder를 본 화면으로 교체).
- NavBar:
  - 타이틀 "오행 분포".
  - Back 버튼(NavigationStack 자동) — 탭 시 pop.
- 독립 provider `SajuElementsDetailProviding`(신규 정의, `Features/Saju/Detail/Elements/`
  하위):
  - `summaryHeadline: String` — 요약 한줄(예: "火가 많고 水가 전혀 없는 사주").
  - `summaryBody: String` — 요약 보조 본문(예: "열정·추진력이 강하나 침착함·저축의 기운이
    부족합니다.").
  - `elements: [ElementDistribution]` — 길이 **고정 5**, 순서 `[火, 木, 土, 金, 水]`. 각 item
    `(symbol: String, koreanName: String, count: Int, max: Int, note: String, isDeficient: Bool)`.
  - `guidance: ElementGuidance?` — 부족 원소 보완 가이드. nil이면 가이드 카드 자체 숨김.
    fields: `(direction: String, color: String, time: String, action: String)` + `targetSymbol:
    String`(예: "水", 카드 헤더에 "부족한 {targetSymbol}를 보완하려면" 형태).
- `MockSajuElementsDetailProvider` 기본값:
  - summary: 와이어프레임 텍스트와 동일.
  - elements: 火 3/4, 木 1/4, 土 2/4, 金 2/4, 水 0/4 (note 각각 "왕성/보통/보통/보통/부족 ⚠",
    isDeficient는 水만 true).
  - guidance: targetSymbol "水", direction "북쪽이 유리", color "검정·파랑 계열", time "저녁
    23시 ~ 새벽 1시", action "계획·독서·수영".
- 레이아웃(수직 `ScrollView`, 좌우 16pt padding, 카드 간 10pt):
  1. **요약 카드** — muted 라벨 "오행 요약" + headline(bold 13pt) + body(muted 10pt).
  2. **5행 분포 카드** — 섹션 라벨 "5행 분포" + 5개 행:
     - 좌측: symbol(한자, bold 13pt) + 한국어명(muted 10pt).
     - 우측: 메타(`note · count/8`).
     - 그 아래 막대 바(높이 8pt, 회색 배경 + 채움). 채움 너비 = `count / max` × 100%. 부족
       원소(`isDeficient = true`)는 채움 색을 약한 톤(예: `WF.line2`) 또는 0%로 시각 구분.
  3. **Disclaimer** — WF1/WF2/WF3와 동일 컴포넌트 재사용.
  4. **보완 가이드 카드** — `guidance` 존재 시 렌더. 헤더 "부족한 {targetSymbol}를 보완하려면"
     + 4개 bullet(방향/색상/시간/행동 라벨 형태로 한 줄씩).
- 화면 진입 시 스크롤 위치는 항상 최상단(요약 카드).
- 주입 방식: `SajuTabDependencies`(또는 별도 주입 경로)를 통해
  `SajuElementsDetailProviding`도 주입 가능하게 구성. 테스트 시 mock 교체 가능.

## Non-functional constraints

- iOS 17+ NavigationStack toolbar API 사용.
- Dynamic Type Large까지 헤드라인/메타/막대 라벨/가이드 bullet 모두 wrapping OK. 막대 바
  최소 두께(6pt)는 유지.
- VoiceOver:
  - 요약 카드 = "오행 요약, {headline}. {body}".
  - 각 행 바 = "{한국어명} {symbol}, {note}, {count}점 8점 만점 중". 부족 원소는 "부족,
    {한국어명}…" 으로 시작하도록 트레잇 부여.
  - 가이드 bullet = "{label} 보완: {value}" (label = 방향/색상/시간/행동).
- 색상/간격은 `DesignTokens` 재사용.
- 모든 텍스트 리터럴은 로컬라이즈 키로 분리.

## Out of scope

- 사주 탭 카테고리 카드 자체 (WF4-02).
- 십성 분석 상세 (WF4-05).
- 학습 리스트 / 레슨 (WF4-06 / WF4-07).
- 실제 5행 계산 로직 — 전부 mock(WF2 `SajuAnalysisEngine`과 직접 연동하지 않음).
- 보완 가이드의 실제 추천 로직, 외부 콘텐츠 딥링크.
- 공유/저장/북마크.
- 다른 카테고리(십성/대운/합충/용신) 상세 화면.
- 5행 항목별 상세 sub-route(예: 水만 더 깊게 보는 화면).

## Acceptance criteria

각 항목은 unit/UI 테스트로 검증 가능해야 한다.

1. WF4-02의 "오행 분포" 카드 탭 시(상호 책임) `SajuElementsDetailView`가 push된다.
2. NavBar 타이틀은 "오행 분포"이고, Back 버튼 탭 시 pop되어 사주 탭 홈으로 복귀한다.
3. 요약 카드의 headline과 body는 provider의 `summaryHeadline`, `summaryBody`를 그대로
   바인딩한다.
4. 5행 분포 카드의 행은 항상 `[火, 木, 土, 金, 水]` 순서로 5개 렌더된다(provider 배열 순서와
   무관하게 symbol 매칭으로 정렬).
5. 각 행 막대의 채움 너비는 `count / max` 비율을 정확히 따른다(count=3, max=4 → 75%).
6. `isDeficient = true`인 행(예: 水, count=0)은 채움 색이 약한 톤(또는 0% 너비)으로 시각
   구분되며, note 영역에 "부족" 텍스트가 표시된다.
7. `elements` 배열 길이가 5가 아닌 mock 주입 시 precondition 실패가 발생한다(테스트로 검증).
8. `guidance != nil` 인 mock 주입 시 보완 가이드 카드가 5행 분포 카드와 Disclaimer 사이에
   렌더되며, 헤더에 "부족한 {targetSymbol}를 보완하려면" 문구가 표시된다.
9. `guidance = nil` 인 mock 주입 시 보완 가이드 카드 전체(헤더 포함)가 숨겨진다.
10. 보완 가이드 카드에 4개 bullet(방향/색상/시간/행동)이 정확한 라벨/값 매핑으로 표시된다.
11. Disclaimer 문구가 5행 분포 카드 직후에 렌더되며 WF1/WF2/WF3와 동일 문구를 포함한다.
12. `SajuElementsDetailProviding`은 `SajuCategoriesProviding`과 별개의 프로토콜이며, 한쪽
    구현체를 다른 쪽으로 대입할 수 없다(컴파일 타임 분리 + 코드 리뷰로 확인).
13. `SajuElementsDetailProviding`을 임의 mock으로 교체하면 화면의 모든 바인딩된 값(요약/
    분포/가이드)이 mock 데이터를 반영한다.
14. VoiceOver focus 순서: NavBar 타이틀 → 요약 → 5행(火→木→土→金→水) → Disclaimer →
    가이드(있을 때).
15. Dynamic Type XL에서 가이드 bullet과 5행 메타가 wrapping되어 잘리지 않고, 막대 바 두께가
    최소 6pt를 유지한다.
