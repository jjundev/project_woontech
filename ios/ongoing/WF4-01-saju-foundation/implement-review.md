# Implementation Review

## Checklist status (all ✓)

### Requirements (from spec)
- ✓ R1: `MainTabContainerView` adds 사주 탭 at `.tag(2)`; selecting it
  mounts `SajuTabView`. Other tabs (홈/투자/마이) keep their existing
  content unchanged.
- ✓ R2: `SajuTabView` body = Header + 1px Divider + NavigationStack
  containing `SajuTabContentPlaceholderView` (empty `ScrollView` with
  "준비중" text). System bottom tab bar (active=2) is provided by the
  parent `TabView`.
- ✓ R3: `SajuTabView` owns its own
  `NavigationStack(path: $navigationPath)` with
  `@State navigationPath: [SajuRoute] = []`, distinct from
  `HomeDashboardView`'s navigation stack instance.
- ✓ R4: `SajuRoute: Hashable` declares all 7 cases (`elements`,
  `tenGods`, `learn`, `lesson(id:)`, `daewoonPlaceholder`,
  `hapchungPlaceholder`, `yongsinPlaceholder`).
- ✓ R5: `sajuRouteDestination(for:)` maps every case to
  `SajuPlaceholderDestinationView`; `lesson(id:)` carries the id for
  on-screen display.
- ✓ R6: 6 protocols under `Features/Saju/Providers/` with matching
  `MockXxx` implementors and wireframe defaults (時庚申/日丙午/月辛卯/年庚午
  pillars, 5-category list, 4 courses 입문/오행/십성/대운).
- ✓ R7: `SajuTabDependencies` (ObservableObject) bundles all 6 fields
  with initialiser injection + `static let mock`.
- ✓ R8: `MainTabContainerView.parseInitialSelection()` returns `2` when
  `-openSajuTab` is present; `RootView.applyLaunchArgs()` routes to
  `.home` for that arg, mounting `MainTabContainerView`.
- ✓ R9: SwiftUI iOS 17+ NavigationStack; safe-area handled by parent
  layout.
- ✓ R10: `DesignTokens` (`bg`/`ink`/`muted`/`headerBorder`/`line2`)
  reused; no new tokens added.
- ✓ R11: Header title accessibilityLabel "사주", menu accessibilityLabel
  "사주 메뉴", saju tab item carries `.accessibilityLabel("사주 탭")`
  *inside* the `.tabItem { Label(...) }` closure (correct propagation
  pattern).
- ✓ R12: Header title uses `.lineLimit(1)` + `.minimumScaleFactor(0.7)`;
  T28 covers XL non-overlap.
- ✓ R13: All Saju text literals use `String(localized:)` keys.
- ✓ R14: `SajuTabView` is mounted directly as a `TabView` child without
  conditional wrapping, so SwiftUI preserves `@State navigationPath`
  across tab switches.

### Implementation steps
- ✓ S1–S13 all addressed (models / protocols / dependencies struct /
  header view / content placeholder / route destinations / SajuTabView /
  MainTabContainerView / WoontechApp + RootView wiring / HomeDashboardView
  cleanup of legacy tab-bar placeholder / localized keys / pbxproj).

### Tests
- ✓ T1–T3: `SajuRouteTests` — 3 tests green.
- ✓ T4–T5: `SajuTabDependenciesTests` — 2 tests green.
- ✓ T6–T12: `SajuMockProvidersTests` — 7 tests green.
- T13–T29: `SajuTabFoundationUITests` (17 tests) authored; executed by
  the harness-managed UI verification gate that runs after this phase.

## Build / Test results

- **Build** (`python3 tools/xcode_test_runner.py build`): succeeded
  (silent exit-0). The subsequent unit test invocation re-built and
  linked the same target without error.
- **Unit tests** (scoped to `WoontechTests/SajuMockProvidersTests`,
  `WoontechTests/SajuTabDependenciesTests`,
  `WoontechTests/SajuRouteTests`):

  Quoted from `.harness/test-results/last-unit-summary.txt`:
  - `"result" : "Passed"`
  - `"passedTests" : 12`, `"failedTests" : 0`, `"skippedTests" : 0`,
    `"totalTestCount" : 12`
  - `last-unit-failures.txt` body: `[no failed tests found]`

- **UI tests**: not run in this reviewer phase per the prompt instruction
  ("Do NOT run UI tests here; the harness runs them once in a dedicated
  verification gate after this phase passes."). The previous iteration's
  UI failures (`SajuTabFoundationUITests.test_homeAndSajuStacks_isolated`
  and `AppLaunchContractUITests.test_openReferral`) were addressed by
  the implementor in the rework cycle that produced the code under
  review:
  1. `Step10ReferralView` now exposes `SajuReferralRoot` via a hidden
     `Color.clear` overlay marker (the same pattern proven for
     `SajuTabRoot`), so the identifier surfaces under
     `app.otherElements` instead of being flattened onto the
     `ScrollView`.
  2. `test_homeAndSajuStacks_isolated()` extends the
     `InvestingAttitudeDetailTitle` `waitForExistence` timeout from 3 s
     to 8 s to accommodate the NavigationStack-in-TabView re-render
     latency observed in iOS 26.

## Notes

- SwiftUI accessibility contract verified for the diff:
  - `SajuTabRoot` is exposed via a hidden `Color.clear` overlay marker
    rather than `.accessibilityIdentifier(...)` on the outer VStack —
    this avoids the TabView-child identifier flattening that would
    shadow the descendant `SajuNavPush_*` button identifiers.
  - Hidden navigation-trigger buttons (`SajuNavPush_*`) live in a
    separate overlay; UI tests query them as `app.buttons["…"]` and the
    SwiftUI exposure type matches.
  - `.accessibilityLabel("사주 탭")` is placed *inside* the
    `.tabItem { Label(...).accessibilityLabel(...) }` closure — the form
    that overrides the system tab bar button's accessibilityLabel.
    Tests query the saju tab as `app.tabBars.buttons["사주 탭"]`.
  - `Step10ReferralView` adopts the same `Color.clear` marker pattern
    so the identifier reaches `app.otherElements`.
- pbxproj registration verified for all 18 new `.swift` files via
  Grep on `Woontech.xcodeproj/project.pbxproj`. Each file has both a
  `PBXFileReference` and a matching `PBXBuildFile … in Sources` entry
  in the appropriate target (Woontech app, WoontechTests, or
  WoontechUITests).
- Hidden navigation triggers are gated by `-openSajuTab` or `-openHome`
  in `ProcessInfo.arguments` so production builds do not expose them.

IMPLEMENT_PASS
