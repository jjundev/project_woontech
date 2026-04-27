# WF4-01 — 사주 탭 Foundation 구현 계획 v1

## 1. Goal

WF3 홈 탭과 분리된 **사주 탭(TabBar index 2)** 의 기반(컨테이너 `SajuTabView`,
전용 NavigationStack, 타입 안전 라우트 `SajuRoute`, 6종 DI 프로토콜+Mock,
헤더+placeholder 컨텐츠)을 구축해 후속 WF4-02~07이 올라탈 발판을 만든다. 본 슬라이스는
"준비중" placeholder만 렌더하며 실제 컨텐츠는 도입하지 않는다.

## 2. Affected files

### New (신규 생성)

#### App-level container
- `ios/Woontech/App/MainTabContainerView.swift` — 4개 탭(`홈`/`투자`/`사주`/`마이`)을 담는
  SwiftUI `TabView` 컨테이너. 사주 탭(index 2)에 `SajuTabView` 마운트. 투자·마이 탭은 본
  슬라이스에서 단순 placeholder. `-openSajuTab` 런치 인자에 따른 초기 selection 처리.

#### Saju tab feature
- `ios/Woontech/Features/Saju/SajuTabView.swift` — 헤더 + NavigationStack + 컨텐츠 슬롯의
  컨테이너. `@EnvironmentObject SajuTabDependencies` 주입.
- `ios/Woontech/Features/Saju/SajuTabHeaderView.swift` — 좌측 "사주" 타이틀 + 우측 원형
  placeholder 아이콘 + 1px 하단 보더.
- `ios/Woontech/Features/Saju/SajuTabContentPlaceholderView.swift` — `ScrollView` + "준비중"
  텍스트.
- `ios/Woontech/Features/Saju/SajuRoute.swift` — `enum SajuRoute: Hashable` 7케이스.
- `ios/Woontech/Features/Saju/SajuRouteDestinations.swift` — 각 라우트별 placeholder 목적지
  View 7개(또는 단일 `SajuPlaceholderView(routeLabel:identifier:)` 재사용). `lesson(id:)`는
  id 표시.
- `ios/Woontech/Features/Saju/SajuTabDependencies.swift` — 6 providing 필드를 담는 단일
  struct(또는 `ObservableObject`). 기본값은 Mock. `static let mock` 제공.

#### DI providers (Saju)
- `ios/Woontech/Features/Saju/Providers/UserSajuOriginProviding.swift`
  — 프로토콜 + `Pillar` 모델(柱: 시·일·월·년) + `MockUserSajuOriginProvider` 와이어프레임
  기본값(時庚申 / 日丙午 / 月辛卯 / 年庚午, 일간 한줄 "일간 丙火 · 양의 불 — 따뜻함, 표현력,
  리더십").
- `ios/Woontech/Features/Saju/Providers/SajuCategoriesProviding.swift`
  — 5개 카테고리 모델(elements/tenGods/daewoon/hapchung/yongsin) + 요약 + optional badge +
  `MockSajuCategoriesProvider`.
- `ios/Woontech/Features/Saju/Providers/SajuElementsDetailProviding.swift`
  — 시그니처만 (WF4-04 본격 사용) + 빈 Mock.
- `ios/Woontech/Features/Saju/Providers/SajuTenGodsDetailProviding.swift`
  — 시그니처만 (WF4-05) + 빈 Mock.
- `ios/Woontech/Features/Saju/Providers/SajuLearningPathProviding.swift`
  — `WeeklyProgress`, `Course`(상태 enum: 완료/현재/미완료/잠금, 진행률 0.0~1.0) 모델 +
  `MockSajuLearningPathProvider` 4코스(입문/오행/십성/대운).
- `ios/Woontech/Features/Saju/Providers/SajuLessonProviding.swift`
  — 시그니처만 (WF4-07) + 빈 Mock.

#### Tests
- `ios/WoontechTests/Saju/SajuRouteTests.swift`
- `ios/WoontechTests/Saju/SajuTabDependenciesTests.swift`
- `ios/WoontechTests/Saju/SajuMockProvidersTests.swift`
- `ios/WoontechUITests/Saju/SajuTabFoundationUITests.swift`

### Modified (기존 파일 수정)

- `ios/Woontech/App/WoontechApp.swift`
  - `@StateObject sajuTabDeps: SajuTabDependencies` 추가, `MainTabContainerView` 경로에서
    환경에 주입.
  - `-openSajuTab` 런치 인자 파싱(초기 탭 selection=2 결정).
  - 기존 home dependency 빌드 로직은 유지.
- `ios/Woontech/App/RootView.swift`
  - `.home` 케이스 → `MainTabContainerView()`로 교체. 기존 `HomeDashboardView()` 직접 push는
    탭 컨테이너 내부로 이동.
  - `applyLaunchArgs()`에 `-openSajuTab` 분기 추가(`route = .home`이지만
    `MainTabContainerView`가 selection=2로 시작).
- `ios/Woontech/Features/Home/HomeDashboardView.swift`
  - 내부 `HomeTabBarPlaceholderView`는 main TabView가 시스템 탭바를 그리므로 **제거** 또는
    `if showsLegacyTabBarPlaceholder` 플래그로 비활성화. 동작/식별자는 유지(다른 UI 테스트
    영향 최소화) — `HomeTabBarPlaceholder` accessibilityIdentifier가 다른 테스트에서
    참조되지 않음을 grep으로 확인 후 제거.
  - `accessibilityIdentifier("HomeDashboardRoot")` 등 기존 핵심 식별자는 그대로 유지하여
    `HomeDashboardUITests`가 회귀하지 않도록 한다.
- (옵션) `ios/Woontech/Shared/DesignTokens.swift`
  - 사주 탭에 헤더 아이콘 배경색 등 신규 토큰이 필요하면 추가(기존 `avatarBg`/`headerBorder`
    재사용으로 충분하면 변경 없음).
- `ios/Woontech.xcodeproj/project.pbxproj`
  - 신규 Swift 파일 reference 등록(목표: Woontech app target / WoontechTests / WoontechUITests).

## 3. Data model / state changes

### New types

```swift
// 柱(주) — 사주 4기둥 표현 (時/日/月/年)
struct Pillar: Hashable {
    enum Position: String, Hashable { case hour, day, month, year }
    let position: Position
    let heavenlyStem: String   // 천간 한자 1자 (예: "丙")
    let earthlyBranch: String  // 지지 한자 1자 (예: "午")
    let element: String        // 색상 매핑용 오행 키 (예: "fire")
}

// 사주 탭 Navigation 라우트
enum SajuRoute: Hashable {
    case elements
    case tenGods
    case learn
    case lesson(id: String)
    case daewoonPlaceholder
    case hapchungPlaceholder
    case yongsinPlaceholder
}

// 6 protocols (signatures excerpt)
protocol UserSajuOriginProviding { var pillars: [Pillar] { get }; var dayMasterLine: String { get } }
protocol SajuCategoriesProviding { var categories: [SajuCategorySummary] { get } }
protocol SajuElementsDetailProviding { /* WF4-04 */ }
protocol SajuTenGodsDetailProviding { /* WF4-05 */ }
protocol SajuLearningPathProviding {
    var weeklyProgress: WeeklyProgress { get }
    var courses: [SajuCourse] { get }
}
protocol SajuLessonProviding { /* WF4-07 */ }

// DI bundle
final class SajuTabDependencies: ObservableObject {
    let userSajuOrigin: any UserSajuOriginProviding
    let categories: any SajuCategoriesProviding
    let elementsDetail: any SajuElementsDetailProviding
    let tenGodsDetail: any SajuTenGodsDetailProviding
    let learningPath: any SajuLearningPathProviding
    let lesson: any SajuLessonProviding
    static let mock: SajuTabDependencies
}
```

### State

- `MainTabContainerView`: `@State private var selection: Int` (초기값은 `-openSajuTab` 파싱
  결과에 따라 0 또는 2).
- `SajuTabView`: `@State private var navigationPath: [SajuRoute] = []` — 사주 탭 전용 path.
  홈 탭의 `HomeDashboardView` `navigationPath`와 인스턴스 분리됨(서로 다른 View 트리).
- 탭 전환 시 path 보존: `MainTabContainerView` 안에 `SajuTabView`가 항상 인스턴스로 유지되도록
  TabView의 자식으로 직접 마운트(`.tag(2)`). SwiftUI TabView는 자식 View를 보존하므로
  `@State path`가 살아남는다 (AC-11).

## 4. Implementation steps (ordered, each independently testable)

### Step A — Pillar / SajuRoute / Course models
1. `Pillar` struct, `SajuCourse` struct(상태 enum 포함), `WeeklyProgress` struct, `SajuCategorySummary` struct를 각자 파일에 정의.
2. `SajuRoute` enum 7케이스 정의 + `Hashable` 자동 도출 검증.

### Step B — DI providers (6종) + Mock
1. 6 프로토콜 파일을 `Features/Saju/Providers/` 하위에 생성.
2. 각 Mock 구현체에 와이어프레임 기본값(원국 4주, 일간 한줄, 4코스 학습 경로 등) 작성.
3. `SajuTabDependencies` 생성자 주입 + `static let mock` 제공.

### Step C — Saju tab UI scaffolding
1. `SajuTabHeaderView` 구현(타이틀 + 우측 원형 placeholder, 식별자 `SajuTabHeaderTitle`,
   `SajuTabHeaderMenuButton`, accessibilityLabel "사주 메뉴").
2. `SajuTabContentPlaceholderView` 구현(빈 ScrollView + "준비중", 식별자
   `SajuTabContentPlaceholder`).
3. `SajuRouteDestinations`에 7케이스 placeholder View 매핑(공통 `SajuPlaceholderDestinationView(label:)`
   재사용 + lesson은 id 표시, 식별자 `SajuPlaceholderDestination_<route>`).
4. `SajuTabView` 구현:
   - `VStack(spacing: 0) { Header / Divider / NavigationStack(path:$path) { Content + .navigationDestination(for: SajuRoute.self) } }`
   - `accessibilityIdentifier("SajuTabRoot")`.
   - `-openSajuTab` (런치 인자) 일 때만 hidden push 트리거 버튼 7개 노출(SajuNavPush_elements,
     SajuNavPush_tenGods, SajuNavPush_learn, SajuNavPush_lessonL001, SajuNavPush_daewoon,
     SajuNavPush_hapchung, SajuNavPush_yongsin) — `HomeDashboardView`의 패턴과 동일.

### Step D — Main tab container 도입
1. `MainTabContainerView`: SwiftUI `TabView(selection: $selection)`로 4개 탭 구성. 식별자
   `MainTabContainerRoot`, 각 탭 식별자 `MainTab_Home/Invest/Saju/My`. `.tag(0..3)`. 사주 탭
   item: `Image(systemName:"sparkles")` + Text "사주", accessibilityLabel "사주 탭".
2. `init(initialSelection: Int = 0)` + 내부에서 ProcessInfo 파싱(`-openSajuTab` → 2).
3. 투자·마이는 단순 `Text("준비중")` placeholder.
4. 홈 탭은 `HomeDashboardView()` 그대로 마운트(env object 주입은 상위에서).
5. 사주 탭은 `SajuTabView().environmentObject(sajuTabDeps)` 마운트.

### Step E — App / Root wiring
1. `WoontechApp`에 `@StateObject sajuTabDeps`(기본값 `.mock`) 추가, `RootView`에
   `.environmentObject(sajuTabDeps)` 주입.
2. `RootView.applyLaunchArgs()`에서 `-openSajuTab`을 만나면 `route = .home`으로 설정(이후
   `MainTabContainerView` 내부가 selection=2로 시작).
3. `.home` 케이스를 `HomeDashboardView()` → `MainTabContainerView()` 로 교체하고 기존
   `homeDeps`/`sajuTabDeps` 환경을 함께 전달.

### Step F — HomeDashboardView 정리
1. `HomeTabBarPlaceholderView` 제거(또는 `#if DEBUG && !WF4` 같은 컴파일 가드 없이 단순 제거).
   `HomeTabBarPlaceholder` 식별자는 어떤 UI 테스트에서도 참조되지 않음을 사전에 grep으로 확인.

### Step G — Localization keys
1. `Localizable.strings`에 신규 키 등록(기본 한국어):
   - `saju.tab.title` = "사주"
   - `saju.tab.menu.label` = "사주 메뉴"
   - `saju.tab.content.placeholder` = "준비중"
   - `saju.tab.tabBar.label` = "사주 탭"
   - `saju.placeholder.elements` 등 7케이스 라벨.
   (프로젝트에 Localizable.strings이 없으면 `String(localized:)` 키만 코드에 노출하고 파일은
   후속에 생성 — 구현자 판단.)

### Step H — Project file 등록
1. 신규 `.swift` 파일을 `project.pbxproj`에 Woontech app target / Tests target / UITests target에
   각각 등록.

각 단계는 독립적으로 빌드 가능하며, A→B→C→D→E→F→G→H 순으로 점진 통합한다.

## 5. Unit test plan (`WoontechTests/Saju/`)

매핑은 Functional requirements와 Acceptance criteria 기준이다.

### `SajuRouteTests.swift`
- `test_sajuRoute_allSevenCasesHashable` — Set에 7케이스 넣었을 때 count == 7 (AC-5).
- `test_sajuRoute_lesson_associatedValue_equality` — `.lesson(id:"L-001") == .lesson(id:"L-001")`,
  `.lesson(id:"L-001") != .lesson(id:"L-002")` (AC-7 사전 검증).
- `test_sajuRoute_lesson_distinctIdsAreDifferentHashes` — Set 안에 두 lesson id 모두 보존됨.

### `SajuTabDependenciesTests.swift`
- `test_sajuTabDependencies_mock_compilesAndDefaults` — 6개 필드 모두 접근 가능, mock이 빈
  값이 아님 (AC-8).
- `test_sajuTabDependencies_customMockReplace_compiles` — 임의 Provider 구현체로 6필드 각각
  교체 가능, 컴파일/렌더 OK (AC-8).

### `SajuMockProvidersTests.swift`
- `test_mockUserSajuOrigin_pillarsCountIs4` — `pillars.count == 4` (AC-9).
- `test_mockUserSajuOrigin_pillarsContain_時日月年` — 각 Position이 정확히 1개씩 존재.
- `test_mockUserSajuOrigin_dayMasterLine_isNotEmpty` — 비어 있지 않음, 와이어프레임 텍스트
  포함 (AC-9).
- `test_mockSajuCategories_count_is5` — 5개(elements/tenGods/daewoon/hapchung/yongsin) (스펙 §
  카테고리).
- `test_mockSajuLearningPath_courseCountIs4` — 4코스 (AC-10).
- `test_mockSajuLearningPath_progressIsInRange` — 모든 코스 progress ∈ [0.0, 1.0] (AC-10).
- `test_mockSajuLearningPath_courseTitlesContain_입문오행십성대운` — 4코스 타이틀 검증.

## 6. UI test plan (`WoontechUITests/Saju/SajuTabFoundationUITests.swift`)

각 케이스는 `XCUIApplication`을 `-openSajuTab`으로 시작.

| 테스트 | AC | 검증 |
|---|---|---|
| `test_launch_openSajuTab_landsOnSajuTab` | 2 | 부팅 직후 `SajuTabRoot` exists, `MainTab_Saju` selected. |
| `test_tabBar_index2_tap_showsSajuTabView` | 1 | `-openHome` 으로 부팅 → `MainTab_Saju` 탭 → `SajuTabRoot` 표시. |
| `test_sajuHeader_titleVisible` | 3 | `SajuTabHeaderTitle` 라벨 == "사주". |
| `test_sajuHeader_menuButtonVisible` | 3 | `SajuTabHeaderMenuButton` exists, 원형. |
| `test_sajuContent_placeholderVisible` | 4 | `SajuTabContentPlaceholder` 또는 텍스트 "준비중" 표시. |
| `test_sajuRoute_pushElements_showsPlaceholder` | 6 | `SajuNavPush_elements` 탭 → `SajuPlaceholderDestination_elements` 표시. |
| `test_sajuRoute_pushTenGods_showsPlaceholder` | 6 | 동일 패턴. |
| `test_sajuRoute_pushLearn_showsPlaceholder` | 6 | 동일 패턴. |
| `test_sajuRoute_pushDaewoon_showsPlaceholder` | 6 | 동일 패턴. |
| `test_sajuRoute_pushHapchung_showsPlaceholder` | 6 | 동일 패턴. |
| `test_sajuRoute_pushYongsin_showsPlaceholder` | 6 | 동일 패턴. |
| `test_sajuRoute_pushLesson_showsIdentifier_L001` | 7 | `SajuNavPush_lessonL001` 탭 → 화면에 "L-001" 표시. |
| `test_tabSwitch_preservesSajuPath` | 11 | 사주 탭에서 push → 홈 탭 → 다시 사주 탭 시 push된 화면이 유지(상세 식별자 still on screen). |
| `test_voiceOver_sajuTabBar_label_사주탭` | 12 | `MainTab_Saju` accessibilityLabel == "사주 탭". |
| `test_voiceOver_sajuHeader_titleLabel_사주` | 12 | Header 타이틀 accessibilityLabel == "사주". |
| `test_dynamicType_xl_headerNoTruncation` | 13 | `app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryXL"]`로 부팅 후 헤더/탭바 텍스트 element width <= screen width, frames 미충돌. |
| `test_homeAndSajuStacks_isolated` | 14 | `-openHome`로 부팅 → 사주 탭 push elements → 홈 탭 push (예: `HomeNavPushInvesting`) → 홈 탭에 사주 placeholder 미표시 / 사주 탭에 투자 미표시. |

테스트는 작성하되 본 구현 슬라이스에서는 실행만 의무화하지 않음(스펙: "implementor가 작성,
실행은 후속에서").

## 7. Risks / open questions

### Risks
- **Main TabBar 부재**: 스펙은 "WF3에서 도입된 메인 TabBar"를 가정하지만, 워크트리에는 실제
  TabBar가 없고 `HomeDashboardView` 안에 49pt placeholder(`HomeTabBarPlaceholderView`)만 존재.
  본 계획에서는 `MainTabContainerView` SwiftUI `TabView`를 신규 도입하여 4개 탭을 묶고, 홈 탭
  내부의 placeholder bar를 제거한다. `HomeDashboardUITests` 회귀 위험을 피하려면
  `HomeDashboardRoot`/`HomeBellButton` 등 기존 식별자가 TabView 자식 안에서도 그대로 노출되어야
  한다(SwiftUI 기본 동작).
- **Tab 전환 시 path 보존**: SwiftUI `TabView`는 비활성 탭 자식 View를 메모리에 유지하지만
  내부 `@State` 보존 보장은 self가 동일한 식별자/형식일 때만. `SajuTabView`를 직접 자식으로
  쓰면 OK이지만, `if`로 감싸면 다시 생성됨. 계획에서는 if 없이 TabView 직속 child로 둠.
- **Localization**: 프로젝트에 Localizable.strings 자체가 없을 수 있음. 1차로 `String(localized:)`
  키만 사용하고 strings 파일은 비어 있어도 무방(Apple이 default value fallback).
- **pbxproj 편집**: 다수 파일 신규 등록은 충돌 위험. 하나씩 추가하고 빌드 검증.
- **Dynamic Type XL UI test**: launchArgument로 ContentSizeCategory를 강제하는 표준 키가
  `UIPreferredContentSizeCategoryName`. 시뮬레이터 의존성 — 실패 시 unit test로 폴백
  (헤더/탭바의 `minimumScaleFactor` 적용 검증).

### Open questions
- `SajuCategoriesProviding`의 정확한 모델 형태(badge: `Color`? `String`?)는 WF4-02에서 본격
  사용된다 — 본 슬라이스에서는 최소한의 형태(`title:String, summary:String, badge:String?`)로
  스케치하고, WF4-02에서 확장.
- 사주 탭 헤더의 우측 placeholder 아이콘 의미가 미정. SF Symbol "ellipsis.circle" 또는 빈 원만
  표시(`Circle().stroke()`). 와이어프레임 정합성을 위해 빈 원을 기본으로 쓰되 후속 슬라이스에서
  교체 가능하도록 구조화.
- 투자/마이 탭 placeholder의 식별자 명명 일관성 — 본 슬라이스 범위가 아니므로 단순 "준비중"
  Text + accessibilityIdentifier만 노출.
- `MainTabContainerView` 도입 후 RootView의 `.home` 케이스 의미가 "메인 탭 진입"으로 바뀌므로
  내부 enum case 명을 `.mainTabs`로 리네이밍할지 — 영향 범위가 크므로 본 슬라이스에서는
  case 이름은 유지하고 destination만 교체.

PLAN_WRITTEN
