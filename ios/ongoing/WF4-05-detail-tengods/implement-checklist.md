# Implementation Checklist
## WF4-05 — 십성 분석 상세

---

## Requirements (from spec)

- [ ] R1 (AC#1): WF4-02의 "십성 분석" 카드 탭 시 `SajuTenGodsDetailView`가 NavigationStack에 push된다.
- [ ] R2 (AC#2): NavBar 타이틀이 "십성 분석"이고, Back 버튼 탭 시 pop되어 사주 탭 홈으로 복귀한다.
- [ ] R3 (AC#3): 요약 카드의 headline과 body가 provider의 `summaryHeadline`, `summaryBody`를 정확히 바인딩한다.
- [ ] R4 (AC#4): 5그룹 분포 행이 항상 [비겁, 식상, 재성, 관성, 인성] 고정 순서로 5개 렌더된다 (provider 배열 순서 무관, name 매칭 정렬).
- [ ] R5 (AC#5): `isCore=true` 그룹에만 검정 배경 "핵심" 배지가 표시된다; 나머지 그룹에는 표시되지 않는다.
- [ ] R6 (AC#6): `isAbsent=true` 그룹 우측 메타가 빨강 "부재 ⚠"로 표시되고, 막대 채움이 약한 톤(또는 0% 너비)으로 렌더된다.
- [ ] R7 (AC#7): 막대 채움 너비 = `min(total / 3.0, 1.0) × 100%` (total=2 → ≈66.7%, total≥3 → 100%).
- [ ] R8 (AC#8): 보조 라인 우측 표출 십성 = `counts[i]>0`인 items만 ` · ` join; 전부 0이면 "—".
- [ ] R9 (AC#9): `groups.count≠5` 또는 임의 item의 `items.count≠2` / `counts.count≠2` 시 precondition 실패.
- [ ] R10 (AC#10): 핵심 십성 카드가 항상 3개 렌더된다; `topThree.count≠3` 시 precondition 실패; 첫 번째 카드 배경·테두리가 시각적으로 구분된다.
- [ ] R11 (AC#11): 각 핵심 십성 카드의 `name`, `han`, `count`, `meaning`, `investImplication`이 mock 기본값(정재×2, 비견×1, 정인×1) 기준 정확히 바인딩된다.
- [ ] R12 (AC#12): `absentWarning≠nil` 시 경고 카드가 핵심 카드 다음 렌더; 카드 테두리 빨강; copy 박스 배경 연한 빨강.
- [ ] R13 (AC#13): `absentWarning=nil` 시 경고 카드 전체 숨김.
- [ ] R14 (AC#14): `learnEntry≠nil` 시 학습 유도 카드 렌더; 카드 탭 시 `SajuRoute.lesson(id: "L-TEN-001")` NavigationStack에 append.
- [ ] R15 (AC#15): `learnEntry=nil` 시 학습 유도 카드 전체 숨김.
- [ ] R16 (AC#16): Disclaimer가 화면 최하단에 렌더되며 WF1/WF2/WF3와 동일 문구 포함.
- [ ] R17 (AC#17): `SajuTenGodsDetailProviding`은 `SajuCategoriesProviding` 및 `SajuElementsDetailProviding`과 별개의 프로토콜; 컴파일 타임 타입 분리.
- [ ] R18 (AC#18): VoiceOver 포커스 순서 — NavBar 타이틀 → 요약 카드 → 5그룹(비겁→식상→재성→관성→인성) → 핵심 Top3 → 부재 경고(있을 때) → 학습 유도(있을 때) → Disclaimer.
- [ ] R19 (AC#19): Dynamic Type XL에서 핵심 카드 `investImplication` 박스와 경고 카드 `copy` 텍스트가 잘리지 않고 wrapping된다.

---

## Implementation Steps

- [ ] S1 (Step 1): `DesignTokens.swift`에 `coreBadgeBg`, `absentRed`, `absentRedLight` 3개 정적 프로퍼티 추가; 빌드 통과 확인.
- [ ] S2 (Step 2): `SajuTenGodsDetailProviding.swift`에 `TenGodGroup`, `CoreTenGod`, `AbsentWarning`, `LearnEntry` 구조체(Equatable) 선언; 프로토콜을 6-프로퍼티 버전으로 교체(`summaryLine` 삭제); `MockSajuTenGodsDetailProvider` 풀 버전 재작성(섹션 3.3 기본값 준수); `SajuTabDependencies` 재컴파일 확인.
- [ ] S3 (Step 3): `SajuTenGodsDetailView.swift` 파일 생성; `sortedTenGodGroups(_:)` 자유 함수; `validateGroups(_:) throws`, `validateGroupLengths(_:) throws`, `validateTopThree(_:) throws` internal 헬퍼; `TenGodsValidationError: Error` enum; precondition 이중 방어 패턴 적용; 빌드 통과.
- [ ] S4 (Step 4): `TenGodsSummaryCard` private struct (섹션 라벨 "십성 요약", headline bold 13pt, body muted 10pt fixedSize); NavBar 타이틀 "십성 분석" inline; root marker `SajuTenGodsDetailView`; identifiers: `TenGodsSummaryCard`, `TenGodsSummaryHeadline`, `TenGodsSummaryBody`.
- [ ] S5 (Step 5): `TenGodsGroupRow` private struct — 상단 HStack(name bold 12pt, han serif 9pt muted, isCore 핵심 배지), 우측(isAbsent 빨강 "부재 ⚠" 또는 "{total}/8" muted), 막대 바(높이 7pt, fillRatio = min(total/3.0, 1.0), isAbsent → `line2`), 보조 라인 (meaning 좌, displayedItems 우); **보조 라인 우측 Text에 `.accessibilityIdentifier("TenGodsDisplayedItems_\(group.name)")` 부여**; VoiceOver label 명세 준수; identifier `TenGodsGroupRow_{name}`; `TenGodsDistributionCard` 섹션 라벨 "5그룹 분포" + ForEach(sortedGroups), identifier `TenGodsDistributionCard`.
- [ ] S6 (Step 6): `TenGodsCoreCard` private struct (name bold 13pt, han serif 9pt muted, ×count, meaning fixedSize, 투자 함의 박스 💹 + investImplication fixedSize; isFirst 배경·테두리 강조); VoiceOver label 명세 준수; identifiers `TenGodsCoreCard_{index}`, **`TenGodsInvestImplication_{index}`**; `TenGodsCoreSection` 섹션 라벨 "나의 핵심 십성" + topThree precondition 검증 후 enumerated ForEach, identifier `TenGodsCoreSection`.
- [ ] S7 (Step 7): `TenGodsAbsentWarningCard` private struct (빨강 테두리, 섹션 라벨 "주의 — 부재 십성" absentRed, groupTitle bold 12pt, copy 박스 absentRedLight 배경 fixedSize); **copy 박스 Text에 `.accessibilityIdentifier("TenGodsAbsentWarningCopy")` 부여** (T56 필수); VoiceOver label 명세 준수; container identifier `TenGodsAbsentWarningCard`; `if let absentWarning` 조건부 렌더.
- [ ] S8 (Step 8): `TenGodsLearnEntryCard` private struct (📚, title bold 12pt, "{durationLabel} 레슨 · {levelLabel}" muted caption2, ›); `SajuTenGodsDetailView`에 `onNavigate: (SajuRoute) -> Void` 파라미터 추가; 탭 → `onNavigate(.lesson(id: entry.lessonId))`; identifier `TenGodsLearnEntryCard`; VoiceOver label 명세 준수; `if let learnEntry` 조건부 렌더.
- [ ] S9 (Step 9): ScrollView > VStack(spacing: 10) 순서 — TenGodsSummaryCard → TenGodsDistributionCard → TenGodsCoreSection → TenGodsAbsentWarningCard(optional) → TenGodsLearnEntryCard(optional) → DisclaimerView(); 좌우 padding 16pt, 수직 padding 16pt; background `DesignTokens.bg`.
- [ ] S10 (Step 10, Option A): `SajuRouteDestinations.swift`의 `.tenGods` destination을 `SajuTenGodsDetailView(provider:onNavigate:)`로 교체; destination-builder 함수에 `onNavigate: (SajuRoute) -> Void` 파라미터 추가; `SajuTabView`에서 `{ route in navigationPath.append(route) }` 전달; 기존 뷰(`SajuElementsDetailView` 등)는 변경 없음; 시뮬레이터 전환 검증.
- [ ] S11 (Step 11): `WoontechTests/Saju/SajuTenGodsDetailViewTests.swift` 작성 (T1–T30, Groups A–H). `summaryLine` 참조 기존 테스트 파일 있을 경우 `summaryHeadline`으로 업데이트.
- [ ] S12 (Step 12): `WoontechUITests/Saju/SajuTenGodsDetailUITests.swift` 작성 (T31–T59). launch arguments `-sajuTenGodsNoAbsentWarning`, `-sajuTenGodsNoLearnEntry` 처리 포함.

---

## Tests

### Unit Tests (WoontechTests/Saju/SajuTenGodsDetailViewTests.swift)

#### Group A — 프로토콜 분리 (AC#17)
- [ ] T1 (unit): `test_protocol_tenGodsNotCategories` — 런타임에서 두 프로토콜 타입이 상이함 XCTAssert
- [ ] T2 (unit): `test_protocol_tenGodsNotElements` — 런타임에서 두 프로토콜 타입이 상이함 XCTAssert

#### Group B — Mock 기본값 (AC#3, AC#11)
- [ ] T3 (unit): `test_mock_summaryHeadline` — `== "정재가 중심인 사주"`
- [ ] T4 (unit): `test_mock_summaryBody_notEmpty` — `.isEmpty == false`
- [ ] T5 (unit): `test_mock_groupsCount5` — `groups.count == 5`
- [ ] T6 (unit): `test_mock_groupsOrder` — 인덱스 0~4가 비겁/식상/재성/관성/인성 순
- [ ] T7 (unit): `test_mock_재성_isCore` — `groups.first{$0.name=="재성"}?.isCore == true`
- [ ] T8 (unit): `test_mock_식상_isAbsent` — `groups.first{$0.name=="식상"}?.isAbsent == true`
- [ ] T9 (unit): `test_mock_topThreeCount3` — `topThree.count == 3`
- [ ] T10 (unit): `test_mock_topThree_정재_count2` — `topThree[0].name == "정재"`, `topThree[0].count == 2`
- [ ] T11 (unit): `test_mock_absentWarning_notNil` — `absentWarning != nil`
- [ ] T12 (unit): `test_mock_absentWarning_groupTitle` — `== "식상(식신·상관) 부재"`
- [ ] T13 (unit): `test_mock_learnEntry_notNil` — `learnEntry != nil`
- [ ] T14 (unit): `test_mock_learnEntry_lessonId` — `== "L-TEN-001"`

#### Group C — 막대 채움 비율 (AC#7)
- [ ] T15 (unit): `test_fillRatio_total2_is66pct` — `min(2.0/3.0, 1.0) ≈ 0.667` (accuracy: 0.001)
- [ ] T16 (unit): `test_fillRatio_total3_is100pct` — `== 1.0`
- [ ] T17 (unit): `test_fillRatio_total0_is0pct` — `== 0.0`
- [ ] T18 (unit): `test_fillRatio_total4_clamped100pct` — `min(4.0/3.0, 1.0) == 1.0`

#### Group D — 표출 십성 텍스트 (AC#8)
- [ ] T19 (unit): `test_displayedItems_oneActive` — counts=[1,0] → "비견"
- [ ] T20 (unit): `test_displayedItems_allZero` — counts=[0,0] → "—"
- [ ] T21 (unit): `test_displayedItems_bothActive` — counts=[1,1] → "비견 · 겁재"

#### Group E — precondition / validation (AC#9)
- [ ] T22 (unit): `test_sortedGroups_length5_succeeds` — 순서 뒤섞은 5개 배열 → 정렬 성공, 각 name 확인
- [ ] T23 (unit): `test_validateGroups_lengthNot5_throws` — 4개 배열 → `validateGroups` throws (`XCTAssertThrowsError`)
- [ ] T24 (unit): `test_validateGroupLengths_itemsCountNot2_throws` — items.count=1 그룹 → `validateGroupLengths` throws

#### Group F — topThree validation (AC#10)
- [ ] T25 (unit): `test_validateTopThree_countNot3_throws` — 2개 배열 → `validateTopThree` throws

#### Group G — Optional 카드 nil/non-nil (AC#12–15)
- [ ] T26 (unit): `test_absentWarningNonNil_viewCreates` — View 생성 crash 없음
- [ ] T27 (unit): `test_absentWarningNil_viewCreates` — `Mock(absentWarning: nil)` + crash 없음
- [ ] T28 (unit): `test_learnEntryNonNil_viewCreates` — View 생성 crash 없음
- [ ] T29 (unit): `test_learnEntryNil_viewCreates` — `Mock(learnEntry: nil)` + crash 없음

#### Group H — SajuTabDependencies 통합 (AC#17)
- [ ] T30 (unit): `test_deps_tenGodsDetailReplaceable` — Stub provider 주입 → `.summaryHeadline == "stub"`

---

### UI Tests (WoontechUITests/Saju/SajuTenGodsDetailUITests.swift)

#### 6.1 Navigation (AC#1, AC#2)
- [ ] T31 (ui): `testNavPush_tenGods_showsDetailView` — `SajuNavPush_tenGods` 탭 → `SajuTenGodsDetailView` 존재
- [ ] T32 (ui): `testNavBarTitle_is십성분석` — `app.navigationBars.staticTexts["십성 분석"]` 존재
- [ ] T33 (ui): `testBackButton_popsToSajuHome` — Back 탭 → `SajuTabRoot` 존재

#### 6.2 요약 카드 (AC#3)
- [ ] T34 (ui): `testSummaryCard_headlineVisible` — `TenGodsSummaryHeadline` 존재 + label 비어있지 않음
- [ ] T35 (ui): `testSummaryCard_bodyVisible` — `TenGodsSummaryBody` 존재
- [ ] T36 (ui): `testSummaryCard_headlineMatchesMock` — `.label == "정재가 중심인 사주"`

#### 6.3 5그룹 분포 (AC#4–8)
- [ ] T37 (ui): `testDistribution_fiveGroupRowsExist` — `TenGodsGroupRow_비겁` ~ `TenGodsGroupRow_인성` 5개 존재
- [ ] T38 (ui): `testDistribution_orderIsSpec` — Y좌표: 비겁 < 식상 < 재성 < 관성 < 인성
- [ ] T39 (ui): `testDistribution_재성_hasCoreBadge` — `TenGodsCoreBadge_재성` 또는 `TenGodsGroupRow_재성` label에 "핵심" 포함
- [ ] T40 (ui): `testDistribution_식상_isAbsent_accessibilityLabel` — `TenGodsGroupRow_식상` label에 "부재" 포함
- [ ] T41 (ui): `testDistribution_비겁_displayedItems` — `TenGodsDisplayedItems_비겁` label == "비견"
- [ ] T42 (ui): `testDistribution_식상_displayedItemsIsEmpty` — `TenGodsDisplayedItems_식상` label == "—"

#### 6.4 핵심 십성 카드 (AC#10, AC#11)
- [ ] T43 (ui): `testCoreSection_threeCardsExist` — `TenGodsCoreCard_0`, `_1`, `_2` 존재
- [ ] T44 (ui): `testCoreSection_firstCard_containsProvider` — `TenGodsCoreCard_0` label에 "정재" 포함
- [ ] T45 (ui): `testCoreSection_firstCard_differentBg` — `TenGodsCoreCard_0` 표시 확인; 시각 배경 구분은 코드리뷰

#### 6.5 부재 경고 카드 (AC#12, AC#13)
- [ ] T46 (ui): `testAbsentWarning_visibleByDefault` — 스크롤 후 `TenGodsAbsentWarningCard` 존재
- [ ] T47 (ui): `testAbsentWarning_accessibilityLabel_contains주의` — label에 "주의" 포함
- [ ] T48 (ui): `testAbsentWarning_hiddenWhenNil` — `-sajuTenGodsNoAbsentWarning` → `TenGodsAbsentWarningCard` NOT exist

#### 6.6 학습 유도 카드 (AC#14, AC#15)
- [ ] T49 (ui): `testLearnEntry_visibleByDefault` — 스크롤 후 `TenGodsLearnEntryCard` 존재
- [ ] T50 (ui): `testLearnEntry_tap_pushesLessonRoute` — 카드 탭 → `SajuPlaceholderDestination_lesson` + "L-TEN-001" 존재
- [ ] T51 (ui): `testLearnEntry_hiddenWhenNil` — `-sajuTenGodsNoLearnEntry` → `TenGodsLearnEntryCard` NOT exist

#### 6.7 Disclaimer (AC#16)
- [ ] T52 (ui): `testDisclaimer_existsAfterScroll` — swipeUp 후 `DisclaimerText` 존재 + "학습·참고용" 포함

#### 6.8 VoiceOver 포커스 순서 (AC#18)
- [ ] T53 (ui): `testA11yOrder_summaryBeforeDistribution` — `TenGodsSummaryCard`.maxY < `TenGodsGroupRow_비겁`.minY
- [ ] T54 (ui): `testA11yOrder_distributionBeforeCore` — `TenGodsGroupRow_인성`.maxY < `TenGodsCoreCard_0`.minY
- [ ] T57 (ui): `testA11yOrder_coreBeforeAbsentWarning` — `TenGodsCoreCard_2`.maxY < `TenGodsAbsentWarningCard`.minY (absentWarning 있을 때)
- [ ] T58 (ui): `testA11yOrder_absentWarningBeforeLearnEntry` — `TenGodsAbsentWarningCard`.maxY < `TenGodsLearnEntryCard`.minY (둘 다 있을 때)
- [ ] T59 (ui): `testA11yOrder_learnEntryBeforeDisclaimer` — `TenGodsLearnEntryCard`.maxY < `DisclaimerText`.minY (learnEntry 있을 때)

#### 6.9 Dynamic Type (AC#19)
- [ ] T55 (ui): `testDynamicTypeXL_investImplicationNotTruncated` — env XL → `TenGodsInvestImplication_0` label에 "…" 미포함
- [ ] T56 (ui): `testDynamicTypeXL_absentWarnCopyNotTruncated` — env XL → `TenGodsAbsentWarningCopy` label에 "…" 미포함

---

## Implementation Notes

1. **`TenGodsAbsentWarningCopy` identifier (S7)**: Step 7의 copy 박스 Text에 `.accessibilityIdentifier("TenGodsAbsentWarningCopy")` 추가 필수 — T56(AC#19) 의존.
2. **`summaryLine` 제거 영향**: Step 2 후 전체 빌드 실행 → 기존 `summaryLine` 참조 파일 색출 후 `summaryHeadline`으로 업데이트.
3. **`SajuNavPush_tenGods` 버튼 존재 확인**: `SajuTabView`에 `SajuNavPush_elements` 패턴과 동일하게 버튼 존재 여부 확인; 없으면 WF4-01 코드 참조 후 추가.
4. **isCore 배지 VoiceOver**: 행 `accessibilityLabel` 앞에 "핵심, " 접두어 추가 방식 권장 (별도 element 불필요).
5. **onNavigate Option A 확정**: Option B 사용 금지. `SajuRouteDestinations.swift` 빌더에 `onNavigate` 파라미터 추가, `SajuTabView`에서 `{ route in navigationPath.append(route) }` 전달.
