# Implementation Review

## Checklist status (all ✓)

### Requirements
- ✓ R1: `MainTabContainerView` adds 4 tabs incl. saju at `.tag(2)`; selecting it renders `SajuTabView`. Other tabs unchanged behaviorally (home tab still hosts `HomeDashboardView` content as TabView child).
- ✓ R2: `SajuTabView` body = `SajuTabHeaderView` (title + circle button) → 1px Divider → `NavigationStack { SajuTabContentPlaceholderView }`. System TabBar comes from the parent `TabView`.
- ✓ R3: `SajuTabView` declares `@State navigationPath: [SajuRoute]` and `NavigationStack(path:$navigationPath)`. Distinct from `HomeDashboardView`'s own NavigationStack.
- ✓ R4: `SajuRoute: Hashable` with all 7 cases (`elements`, `tenGods`, `learn`, `lesson(id: String)`, `daewoonPlaceholder`, `hapchungPlaceholder`, `yongsinPlaceholder`).
- ✓ R5: `SajuPlaceholderDestinationView` + `sajuRouteDestination(for:)` switch over all 7 cases. `lesson(id:)` propagates id and renders identifier label.
- ✓ R6: 6 protocols (`UserSajuOriginProviding`, `SajuCategoriesProviding`, `SajuElementsDetailProviding`, `SajuTenGodsDetailProviding`, `SajuLearningPathProviding`, `SajuLessonProviding`) each with a `Mock*` implementation. Wireframe defaults (時庚申/日丙午/月辛卯/年庚午, 5 categories, 4 courses 입문/오행/십성/대운) populated.
- ✓ R7: `SajuTabDependencies: ObservableObject` with 6 providing fields, constructor injection, and `static let mock`. Tests inject custom stubs successfully (T5).
- ✓ R8: `MainTabContainerView.parseInitialSelection()` returns 2 when `-openSajuTab` is present; `RootView.applyLaunchArgs()` routes to `.home` for that arg.
- ✓ R9: NavigationStack used (iOS 17+). `SajuTabHeaderView` lives inside the SwiftUI safe area; system TabBar at bottom respects home indicator.
- ✓ R10: `DesignTokens` (ink/muted/bg/headerBorder/line2) reused throughout; no new tokens introduced.
- ✓ R11: VoiceOver labels — header title "사주", menu button "사주 메뉴", saju tab a11y label "사주 탭".
- ✓ R12: Header title uses `lineLimit(1)` + `minimumScaleFactor(0.7)`; `Spacer(minLength: 8)` between title and menu button.
- ✓ R13: All visible literals use `String(localized: "saju.tab.*", defaultValue: ...)`.
- ✓ R14: `SajuTabView` is mounted directly inside `TabView` `.tag(2)` without conditional wrapping; SwiftUI preserves @State path across tab switches.

### Steps
- ✓ S1–S13 all complete (models, protocols, dependencies struct, header, content placeholder, route destinations, SajuTabView, MainTabContainerView, app/root wiring, HomeTabBarPlaceholder removal kept compatible, localized keys via String(localized:), pbxproj registration).

### Tests
- ✓ T1–T12 unit tests all written and passing.
- ✓ T13–T29 UI tests authored under `WoontechUITests/Saju/SajuTabFoundationUITests.swift` (run in dedicated UI verify gate).

## Build / Test results

- Build: succeeded (preflight ok; unit test command implicitly compiles app + tests; no failures reported).
- Unit tests (`WoontechTests/SajuRouteTests`, `WoontechTests/SajuTabDependenciesTests`, `WoontechTests/SajuMockProvidersTests`):
  - From `.harness/test-results/last-unit-summary.txt`:
    - `"passedTests" : 12`
    - `"failedTests" : 0`
    - `"skippedTests" : 0`
    - `"result" : "Passed"`
    - `"totalTestCount" : 12`
  - From `.harness/test-results/last-unit-failures.txt`: `[no failed tests found]`
- UI tests: not executed in this phase (per harness contract — runs in dedicated UI verification gate).

## Notes

- Reviewer specifically verified the SwiftUI accessibility contract:
  - `SajuTabRoot` is intentionally NOT attached to the TabView child's outermost VStack; instead, an invisible `Color.clear` overlay carries `accessibilityIdentifier("SajuTabRoot")`. This avoids the well-known TabView child identifier shadowing pattern noted in the implementor guide.
  - Hidden push trigger buttons (`SajuNavPush_*`) are placed in a separate overlay so the saju root container does not flatten them.
  - UI test query types match SwiftUI exposure types: `staticTexts` for `Text` (`SajuTabHeaderTitle`, `SajuTabContentPlaceholderText`, `SajuPlaceholderDestination_lesson_Identifier`), `buttons` for `Button` (`SajuTabHeaderMenuButton`, `SajuNavPush_*`), `otherElements` for the hidden `Color.clear` marker (`SajuTabRoot`) and the destination VStack (`SajuPlaceholderDestination_*`), `tabBars.buttons` for system tab items keyed by accessibility label.
- pbxproj registration verified for all 17 new `.swift` files (each has both a `PBXFileReference` and a `PBXBuildFile … in Sources` entry).
- `RootView.applyLaunchArgs()` routes both `-openSajuTab` and `-openHome` to `.home`, leaving the actual tab selection to `MainTabContainerView.parseInitialSelection()`.
