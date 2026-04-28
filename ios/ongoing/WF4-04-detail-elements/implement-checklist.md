# Implementation Checklist — WF4-04 오행 분포 상세

## Requirements (from spec)

- [ ] R1: `SajuElementsDetailView` 신규 화면 생성 (`Features/Saju/Detail/Elements/`)
- [ ] R2: NavBar 타이틀 "오행 분포", NavigationStack Back 버튼 탭 시 사주 탭 홈으로 pop
- [ ] R3: 요약 카드 — `summaryHeadline`(bold 13pt)·`summaryBody`(muted 10pt)를 provider 값에 바인딩
- [ ] R4: 5행 분포 카드는 항상 `[火, 木, 土, 金, 水]` 순서 5개 행으로 렌더 (provider 배열 순서와 무관)
- [ ] R5: 각 행 막대 채움 너비 = `count / max` 비율 (count=3, max=4 → 75%)
- [ ] R6: `isDeficient = true` 행 — 채움 색 약한 톤(`DesignTokens.line2`) 또는 0% 너비 + note 영역 "부족" 텍스트 표시
- [ ] R7: `elements` 배열 길이가 5가 아니면 `preconditionFailure` 호출 (길이=5 정상 경로 단위 테스트로 검증, 비정상 경로는 코드 리뷰+주석으로 갈음)
- [ ] R8: `guidance != nil` — 보완 가이드 카드 렌더, 헤더 "부족한 {targetSymbol}를 보완하려면" 표시 (⚠ 레이아웃 순서는 functional requirements + AC#14 기준: Summary → Distribution → Disclaimer → Guidance 채택; AC#8의 "Disclaimer 앞" 명시와 상충하므로 관련 테스트에 주석 기재)
- [ ] R9: `guidance = nil` — 보완 가이드 카드 전체(헤더 포함) 숨김
- [ ] R10: 보완 가이드 카드에 4개 bullet — 방향/색상/시간/행동 라벨과 값 정확히 매핑
- [ ] R11: `DisclaimerView` 재사용 (WF1/WF2/WF3 동일 컴포넌트), 5행 분포 카드 직후 렌더
- [ ] R12: `SajuElementsDetailProviding`은 `SajuCategoriesProviding`과 별개 프로토콜 (컴파일 타임 분리)
- [ ] R13: `SajuElementsDetailProviding` 임의 mock 교체 시 요약/분포/가이드 모든 바인딩 mock 데이터 반영
- [ ] R14: VoiceOver 접근성 레이블 — 요약 카드: "오행 요약, {headline}. {body}", 각 행: "{한국어명} {symbol}, {note}, {count}점 8점 만점 중" (부족 행은 "부족, …" 시작), 가이드 bullet: "{label} 보완: {value}"
- [ ] R15: Dynamic Type XL — 가이드 bullet·5행 메타 wrapping 잘림 없음; 막대 바 최소 높이 6pt 유지

---

## Implementation Steps

- [ ] S1: `Woontech/Features/Saju/Providers/SajuElementsDetailProviding.swift` 확장
  - `ElementDistribution` struct 선언 (Equatable)
  - `ElementGuidance` struct 선언 (Equatable)
  - 프로토콜에서 `summaryLine` 제거 → `summaryHeadline`, `summaryBody`, `elements`, `guidance` 4개 프로퍼티로 교체
  - `MockSajuElementsDetailProvider` 스펙 기본값으로 재작성
- [ ] S2: `WoontechTests/Saju/SajuTabDependenciesTests.swift` 수정
  - `summaryLine` → `summaryHeadline` 참조 교체
  - `StubSajuElementsDetailProvider`에 신규 4개 필드 추가
  - 빌드·테스트 통과 확인
- [ ] S3: `Woontech/Resources/ko.lproj/Localizable.strings` 로컬라이즈 키 추가 (10개 키: navTitle, summary.sectionLabel, dist.sectionLabel, deficient.note, guidance.sectionLabel, guidance.headerFormat, guidance.direction, guidance.color, guidance.time, guidance.action)
- [ ] S4: `Woontech/Features/Saju/Detail/Elements/SajuElementsDetailView.swift` 신규 작성
  - `SajuElementsDetailView` 메인 뷰 (ScrollView, 좌우 16pt, 카드 간 10pt)
  - `SajuElementsSummaryCard` (private) — 접근성 레이블 포함
  - `SajuElementsDistributionCard` (private) + `sortedElements()` 헬퍼 (preconditionFailure)
  - `ElementDistributionRow` (private) — GeometryReader 막대 바, 부족 색상 분기, 접근성
  - `SajuElementsGuidanceCard` (private) — 4개 bullet, 접근성 레이블
  - 모든 텍스트 리터럴을 로컬라이즈 키 사용
- [ ] S5: `Woontech/Features/Saju/SajuRouteDestinations.swift` — `sajuRouteDestination(for:deps:)` 시그니처 변경, `.elements` → `SajuElementsDetailView(provider: deps.elementsDetail)` 연결
- [ ] S5b: `Woontech/Features/Saju/SajuTabView.swift` — `navigationDestination` 클로저에서 `deps` 전달
- [ ] S6: 전체 빌드 확인 및 기존 테스트 pass — `SajuTabDependenciesTests`, `SajuRouteTests` 포함
- [ ] S7: `WoontechTests/Saju/SajuElementsDetailViewTests.swift` 단위 테스트 작성
- [ ] S8: `WoontechUITests/Saju/SajuElementsDetailUITests.swift` UI 테스트 작성

---

## Tests

### Unit Tests (`WoontechTests/Saju/SajuElementsDetailViewTests.swift`)

**Group A — 프로토콜 분리 (AC#12)**
- [ ] T1 (unit): `test_protocolSeparation_elementsNotCategories` — 두 프로토콜이 상호 대입 불가(컴파일 타임), 코드 주석으로 설명

**Group B — Mock 기본값 (AC#3, AC#13)**
- [ ] T2 (unit): `test_mockProvider_summaryHeadlineDefault` — `summaryHeadline == "火가 많고 水가 전혀 없는 사주"`
- [ ] T3 (unit): `test_mockProvider_summaryBodyDefault` — `summaryBody` 와이어프레임 텍스트 일치
- [ ] T4 (unit): `test_mockProvider_elementsCount5` — `elements.count == 5`
- [ ] T5 (unit): `test_mockProvider_elementsOrder` — `[0]火 [1]木 [2]土 [3]金 [4]水` 순서
- [ ] T6 (unit): `test_mockProvider_guidanceNotNil` — `guidance != nil`
- [ ] T7 (unit): `test_mockProvider_guidanceTargetSymbol` — `guidance?.targetSymbol == "水"`
- [ ] T8 (unit): `test_mockProvider_customInit_reflectsAllFields` — 임의 값 init 후 모든 필드 반영

**Group C — 분포 비율 계산 (AC#5)**
- [ ] T9 (unit): `test_barFillRatio_count3_max4_is75Percent`
- [ ] T10 (unit): `test_barFillRatio_count0_max4_is0Percent`
- [ ] T11 (unit): `test_barFillRatio_count4_max4_is100Percent`

**Group D — 부족 원소 (AC#6)**
- [ ] T12 (unit): `test_deficientElement_isDeficientTrue` — 水 isDeficient==true
- [ ] T13 (unit): `test_deficientElement_noteContains부족` — 水 note에 "부족" 포함
- [ ] T14 (unit): `test_nonDeficient_element_isDeficientFalse` — 火 isDeficient==false

**Group E — guidance nil/non-nil (AC#8, AC#9)**
- [ ] T15 (unit): `test_guidanceNonNil_cardRendered` — guidance != nil → 뷰 생성 성공
- [ ] T16 (unit): `test_guidanceNil_cardAbsent` — guidance == nil → guidance card 없음
- [ ] T17 (unit): `test_guidanceHeader_containsTargetSymbol` — 헤더 텍스트에 targetSymbol 포함

**Group F — guidance bullet 매핑 (AC#10)**
- [ ] T18 (unit): `test_guidanceBullets_directionValue`
- [ ] T19 (unit): `test_guidanceBullets_colorValue`
- [ ] T20 (unit): `test_guidanceBullets_timeValue`
- [ ] T21 (unit): `test_guidanceBullets_actionValue`

**Group G — precondition (AC#7)**
- [ ] T22 (unit): `test_sortedElements_length5_succeeds` — 5개 배열 → 예외 없이 5개 반환
- [ ] T23 (unit): `test_sortedElements_lengthNot5_preconditionFails` — 4개/6개 배열 → preconditionFailure (테스트 불가 시 코드 리뷰+주석으로 갈음, 비고: Swift precondition은 debug 빌드에서만 트랩)

**Group H — SajuTabDependencies 통합 (AC#12, AC#13)**
- [ ] T24 (unit): `test_sajuTabDeps_elementsDetailReplaceable` — 커스텀 StubElementsDetailProvider 주입 후 summaryHeadline 반영

### UI Tests (`WoontechUITests/Saju/SajuElementsDetailUITests.swift`)

**Navigation (AC#1, AC#2)**
- [ ] T25 (ui): `testNavPush_elements_showsDetailView` — `SajuNavPush_elements` 탭 → `SajuElementsDetailView` 존재
- [ ] T26 (ui): `testNavBarTitle_isOhaengBunpo` — NavBar 타이틀 "오행 분포"
- [ ] T27 (ui): `testBackButton_popsToSajuHome` — Back 탭 → `SajuTabRoot` visible

**Summary card (AC#3)**
- [ ] T28 (ui): `testSummaryCard_headlineVisible` — `"ElementsSummaryHeadline"` 존재, label 비어있지 않음
- [ ] T29 (ui): `testSummaryCard_bodyVisible` — `"ElementsSummaryBody"` 존재
- [ ] T30 (ui): `testSummaryCard_headlineEqualsProviderValue` — label == mock summaryHeadline 기본값

**5-element distribution (AC#4, AC#5, AC#6)**
- [ ] T31 (ui): `testDistribution_fiveRowsExist` — `ElementRow_火~水` 5개 모두 존재
- [ ] T32 (ui): `testDistribution_orderIsFireWoodEarthMetalWater` — 5행 Y좌표 순서 확인
- [ ] T33 (ui): `testDistribution_deficientRow_水_noteContains부족` — 水 행 접근성 레이블에 "부족" 포함

**Disclaimer (AC#11)**
- [ ] T34 (ui): `testDisclaimer_exists` — `"DisclaimerText"` 존재
- [ ] T35 (ui): `testDisclaimer_text_matchesWF1WF2WF3` — 레이블에 "학습·참고용" 포함

**Guidance card (AC#8, AC#9, AC#10)**
- [ ] T36 (ui): `testGuidanceCard_visibleWithDefaultMock` — `"ElementsGuidanceCard"` 존재
- [ ] T37 (ui): `testGuidanceCard_header_contains水` — `"GuidanceHeader"` 레이블에 "水" 포함
- [ ] T38 (ui): `testGuidanceCard_fourBullets_exist` — `GuidanceBullet_direction~action` 4개 모두 존재
- [ ] T39 (ui): `testGuidanceCard_hiddenWhenGuidanceNil` — `-sajuElementsNoGuidance` launch arg → `"ElementsGuidanceCard"` 미존재 (launch arg 처리 추가 필요, 단위 T16으로 보완 가능)

**VoiceOver focus order (AC#14)**
- [ ] T40 (ui): `testAccessibility_elementsAfterSummary` — Y좌표: ElementsSummaryCard < ElementRow_火 < DisclaimerText (레이아웃 순서 프록시)

**Dynamic Type (AC#15)**
- [ ] T41 (ui): `testDynamicTypeXL_guidanceBulletVisible` — contentSizeCategory `.extraExtraExtraLarge` → `GuidanceBullet_direction` 존재, label에 "…" 없음
- [ ] T42 (ui): `testDynamicTypeXL_distributionRowVisible` — XL → `ElementRow_火` 존재
