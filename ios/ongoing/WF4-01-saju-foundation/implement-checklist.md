# Implementation Checklist

## Requirements (from spec)
- [ ] R1: Main TabBar에 사주 탭(index 2) 추가, 탭 셀렉트 시 `SajuTabView` 렌더, 다른 탭(홈/투자/마이) 동작 변경 없음.
- [ ] R2: `SajuTabView` = 상단 고정 Header("사주" 좌측 + 우측 원형 placeholder 아이콘) + 가운데 컨텐츠 슬롯(빈 ScrollView + "준비중") + 하단 공통 TabBar(active=2).
- [ ] R3: `SajuTabView` 내부에 사주 탭 전용 NavigationStack — 홈 탭 NavigationStack과 인스턴스 분리.
- [ ] R4: `SajuRoute` enum 7 케이스(`elements`, `tenGods`, `learn`, `lesson(id: String)`, `daewoonPlaceholder`, `hapchungPlaceholder`, `yongsinPlaceholder`) 컴파일 + `Hashable`.
- [ ] R5: 각 `SajuRoute` 케이스에 대응하는 placeholder 목적지 View(공통 "준비중") 존재. `lesson(id:)`는 식별자 화면 표시.
- [ ] R6: DI 프로토콜 6종 선언(`UserSajuOriginProviding`, `SajuCategoriesProviding`, `SajuElementsDetailProviding`, `SajuTenGodsDetailProviding`, `SajuLearningPathProviding`, `SajuLessonProviding`) + 각 `MockXxx` 구현체 + 와이어프레임 기본값.
- [ ] R7: `SajuTabDependencies` 단일 struct/ObservableObject로 6 providing 필드 묶어 주입(생성자 또는 EnvironmentObject), 테스트 시 mock 교체 가능.
- [ ] R8: 런치 인자 `-openSajuTab` 처리 — 부팅 직후 TabBar index 2가 활성 상태.
- [ ] R9: iOS 17+ SwiftUI NavigationStack, safe area 준수(Header≠status bar 침범, TabBar≠home indicator 가림).
- [ ] R10: `DesignTokens.swift` 색/간격/타이포 재사용. 신규 토큰 필요 시 동일 파일에 추가.
- [ ] R11: VoiceOver — Header 타이틀 "사주", 우측 아이콘 "사주 메뉴", TabBar 사주 셀 "사주 탭".
- [ ] R12: Dynamic Type Large(및 XL UI 테스트)에서 Header/TabBar 잘림·겹침 없음.
- [ ] R13: 모든 텍스트 리터럴 로컬라이즈 키로 분리(1차 한국어).
- [ ] R14: 탭 전환 시 사주 탭 NavigationStack path 보존.

## Implementation steps
- [ ] S1: `Pillar`(Position enum 포함), `SajuCourse`(상태 enum + progress), `WeeklyProgress`, `SajuCategorySummary`, `SajuRoute`(7케이스, `Hashable`) 모델 파일 생성.
- [ ] S2: `Features/Saju/Providers/` 하위에 6 프로토콜 + 각 Mock 구현체 작성(원국 4주 / 일간 한줄 / 카테고리 5개 / 4코스 학습 경로 등 와이어프레임 기본값).
- [ ] S3: `SajuTabDependencies` 정의(6 필드 + 생성자 주입 + `static let mock`).
- [ ] S4: `SajuTabHeaderView`(좌측 "사주" + 우측 원형 placeholder, 식별자 `SajuTabHeaderTitle`/`SajuTabHeaderMenuButton`, accessibilityLabel "사주 메뉴") 구현.
- [ ] S5: `SajuTabContentPlaceholderView`(빈 ScrollView + "준비중", 식별자 `SajuTabContentPlaceholder`) 구현.
- [ ] S6: `SajuRouteDestinations` — 7 케이스 placeholder 목적지(공통 placeholder + lesson은 id 표시, 식별자 `SajuPlaceholderDestination_<route>`).
- [ ] S7: `SajuTabView` 구현 — `VStack { Header / Divider / NavigationStack(path:$path){ Content + .navigationDestination(for: SajuRoute.self) } }`, 식별자 `SajuTabRoot`. `-openSajuTab` 시 hidden push 트리거 7개(`SajuNavPush_elements/tenGods/learn/lessonL001/daewoon/hapchung/yongsin`).
- [ ] S8: `MainTabContainerView` 도입 — `TabView(selection: $selection)` 4탭(`MainTab_Home/Invest/Saju/My`), `.tag(0..3)`, 사주 탭 item label "사주 탭", `init(initialSelection:)` + ProcessInfo로 `-openSajuTab` 파싱(2). 투자/마이는 단순 "준비중" placeholder.
- [ ] S9: `WoontechApp`에 `@StateObject sajuTabDeps`(기본 `.mock`) 추가, `RootView`에 environmentObject 주입.
- [ ] S10: `RootView.applyLaunchArgs()`에 `-openSajuTab` 분기(`route = .home`); `.home` 케이스 destination을 `MainTabContainerView()`로 교체(homeDeps/sajuTabDeps 주입 유지).
- [ ] S11: `HomeDashboardView` 내부 `HomeTabBarPlaceholderView` 제거 — `HomeTabBarPlaceholder` 식별자가 다른 UI 테스트에서 미참조 grep 검증 후 안전 제거. `HomeDashboardRoot` 등 핵심 식별자는 유지.
- [ ] S12: 신규 텍스트 리터럴 로컬라이즈 키(`saju.tab.title`, `saju.tab.menu.label`, `saju.tab.content.placeholder`, `saju.tab.tabBar.label`, 7 placeholder 라벨)를 `String(localized:)`로 노출.
- [ ] S13: 신규 `.swift` 파일을 `Woontech.xcodeproj/project.pbxproj`의 Woontech app target / WoontechTests / WoontechUITests에 등록.

## Tests
- [ ] T1 (unit) `SajuRouteTests.test_sajuRoute_allSevenCasesHashable` — Set count == 7. (R4)
- [ ] T2 (unit) `SajuRouteTests.test_sajuRoute_lesson_associatedValue_equality` — 동일/다른 id 비교. (R4, AC-7 사전)
- [ ] T3 (unit) `SajuRouteTests.test_sajuRoute_lesson_distinctIdsAreDifferentHashes` — Set 안에 두 lesson id 보존.
- [ ] T4 (unit) `SajuTabDependenciesTests.test_sajuTabDependencies_mock_compilesAndDefaults` — 6필드 접근 가능 + non-empty. (R7)
- [ ] T5 (unit) `SajuTabDependenciesTests.test_sajuTabDependencies_customMockReplace_compiles` — 임의 mock 교체 컴파일/렌더. (R7)
- [ ] T6 (unit) `SajuMockProvidersTests.test_mockUserSajuOrigin_pillarsCountIs4` — `pillars.count == 4`. (R6, AC-9)
- [ ] T7 (unit) `SajuMockProvidersTests.test_mockUserSajuOrigin_pillarsContain_時日月年` — 각 Position 1개씩.
- [ ] T8 (unit) `SajuMockProvidersTests.test_mockUserSajuOrigin_dayMasterLine_isNotEmpty` — 비어 있지 않음 + 와이어프레임 텍스트 포함. (AC-9)
- [ ] T9 (unit) `SajuMockProvidersTests.test_mockSajuCategories_count_is5`.
- [ ] T10 (unit) `SajuMockProvidersTests.test_mockSajuLearningPath_courseCountIs4`. (AC-10)
- [ ] T11 (unit) `SajuMockProvidersTests.test_mockSajuLearningPath_progressIsInRange` — 모든 progress ∈ [0, 1]. (AC-10)
- [ ] T12 (unit) `SajuMockProvidersTests.test_mockSajuLearningPath_courseTitlesContain_입문오행십성대운`.
- [ ] T13 (ui) `SajuTabFoundationUITests.test_launch_openSajuTab_landsOnSajuTab` — 부팅 직후 `SajuTabRoot`/`MainTab_Saju` selected. (AC-2)
- [ ] T14 (ui) `SajuTabFoundationUITests.test_tabBar_index2_tap_showsSajuTabView` — `-openHome` 부팅 → `MainTab_Saju` 탭 → `SajuTabRoot` 표시. (AC-1)
- [ ] T15 (ui) `SajuTabFoundationUITests.test_sajuHeader_titleVisible` — `SajuTabHeaderTitle` == "사주". (AC-3)
- [ ] T16 (ui) `SajuTabFoundationUITests.test_sajuHeader_menuButtonVisible` — `SajuTabHeaderMenuButton` exists. (AC-3)
- [ ] T17 (ui) `SajuTabFoundationUITests.test_sajuContent_placeholderVisible` — `SajuTabContentPlaceholder` 또는 "준비중". (AC-4)
- [ ] T18 (ui) `SajuTabFoundationUITests.test_sajuRoute_pushElements_showsPlaceholder`. (AC-6)
- [ ] T19 (ui) `SajuTabFoundationUITests.test_sajuRoute_pushTenGods_showsPlaceholder`. (AC-6)
- [ ] T20 (ui) `SajuTabFoundationUITests.test_sajuRoute_pushLearn_showsPlaceholder`. (AC-6)
- [ ] T21 (ui) `SajuTabFoundationUITests.test_sajuRoute_pushDaewoon_showsPlaceholder`. (AC-6)
- [ ] T22 (ui) `SajuTabFoundationUITests.test_sajuRoute_pushHapchung_showsPlaceholder`. (AC-6)
- [ ] T23 (ui) `SajuTabFoundationUITests.test_sajuRoute_pushYongsin_showsPlaceholder`. (AC-6)
- [ ] T24 (ui) `SajuTabFoundationUITests.test_sajuRoute_pushLesson_showsIdentifier_L001` — placeholder 화면에 "L-001" 표시. (AC-7)
- [ ] T25 (ui) `SajuTabFoundationUITests.test_tabSwitch_preservesSajuPath` — 사주 탭 push → 홈 탭 → 사주 탭 시 push된 화면 유지. (AC-11)
- [ ] T26 (ui) `SajuTabFoundationUITests.test_voiceOver_sajuTabBar_label_사주탭` — `MainTab_Saju` accessibilityLabel == "사주 탭". (AC-12)
- [ ] T27 (ui) `SajuTabFoundationUITests.test_voiceOver_sajuHeader_titleLabel_사주` — Header 타이틀 accessibilityLabel == "사주". (AC-12)
- [ ] T28 (ui) `SajuTabFoundationUITests.test_dynamicType_xl_headerNoTruncation` — XL launchArg, Header/TabBar frame 미충돌·미잘림. (AC-13)
- [ ] T29 (ui) `SajuTabFoundationUITests.test_homeAndSajuStacks_isolated` — 사주 탭 push → 홈 탭 push → 상호 비노출. (AC-14)
