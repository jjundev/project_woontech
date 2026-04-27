# Implement Feedback v1

## Checklist items not met

- R11 / T26 / AC-12: System tab bar `사주 탭` button was not exposed with the
  required VoiceOver label "사주 탭" — `.accessibilityLabel(...)` placed on the
  TabView child view does not propagate to the system tab bar item; the tab
  bar still showed the default Label text "사주". Fixed by reviewer.
- T29 (`test_homeAndSajuStacks_isolated`): The test asserts the home-tab
  navigation push destination using a stale identifier
  `HomeRoute_investingDest` belonging to a deprecated placeholder
  (`InvestingPlaceholderView` in `HomeRouteDestinations.swift`, marked
  `@available(*, deprecated, message: "Use InvestingAttitudeDetailView
  instead")`). The actual `.investing` `navigationDestination` resolves to
  `InvestingAttitudeDetailView` (no `HomeRoute_investingDest` is rendered).
  Reviewer changed the assertion to query
  `app.staticTexts["InvestingAttitudeDetailTitle"]`, which matches the
  identifier other home UI tests already use successfully — but the test
  still fails (see "Build / Test failures" — push does not surface the
  destination within the 3 s timeout in this tab-switch sequence).
- AppLaunchContractUITests.test_openReferral: pre-existing-or-related
  contract regression. The `SajuReferralRoot` accessibility identifier sits
  on a `ScrollView` in `Step10ReferralView`, but the contract test queries
  `app.otherElements["SajuReferralRoot"]`. Reviewer wrapped the ScrollView
  in a `VStack(spacing: 0) { ScrollView { … } }` carrying
  `.accessibilityElement(children: .contain) +
  .accessibilityIdentifier("SajuReferralRoot")` — but the test STILL fails
  (see below). Implementor needs a deeper fix.

## Build / Test failures

Verified via `.harness/test-results/last-ui-summary.txt` after reviewer
patch:

- Result: `"Failed"`
- `"passedTests" : 19`, `"failedTests" : 2`, `"totalTestCount" : 21`

Remaining failures (after reviewer patch):

1. `WoontechUITests/SajuTabFoundationUITests/test_homeAndSajuStacks_isolated()`
   — `SajuTabFoundationUITests.swift:229: XCTAssertTrue failed`. After my
   patch, line 229 is
   `XCTAssertTrue(app.staticTexts["InvestingAttitudeDetailTitle"].waitForExistence(timeout: 3))`.
   The push of `.investing` from `HomeNavPushInvesting` after the
   `home → saju → push elements → home` tab-switch sequence is not landing
   on `InvestingAttitudeDetailView` within the 3 s window. The same
   identifier is found reliably by `InvestingAttitudeDetailUITests` in a
   single-tab boot, so the regression is specific to the
   tab-switch-then-push sequence inside `MainTabContainerView`. Likely
   root cause: the home tab's `NavigationStack(path: $navigationPath)` is
   getting its `@State` reset (or its `navigationDestination` not picking
   up the path append) after the home tab is reselected from inside
   `MainTabContainerView`. Needs investigation of `MainTabContainerView`
   wrapping pattern and possibly a longer wait or a different navigation
   verification anchor.

2. `WoontechUITests/AppLaunchContractUITests/test_openReferral_routesToReferral_andStaysAfterSplash()`
   — `AppLaunchContractUITests.swift:54: XCTAssertTrue failed -
   SajuReferralRoot should appear after launch with -openReferral`.
   Reviewer wrapper of the ScrollView did not make the identifier
   `app.otherElements`-queryable. Either:
   (a) `applyLaunchArgs()` in `RootView` is no longer reaching
   `route = .referral` in time before splash takes over, OR
   (b) the SwiftUI accessibility tree under iOS 26 still flattens the
   wrapper VStack onto the ScrollView (so the identifier remains exposed
   only as `app.scrollViews["SajuReferralRoot"]`).

## Required changes

Implementor must:

1. (T29 / R14) Investigate why `HomeNavPushInvesting` appended to
   `HomeDashboardView.navigationPath` does not result in
   `InvestingAttitudeDetailView` rendering after the
   `home → saju → push elements → home` tab-switch sequence in
   `MainTabContainerView`. Options:
   - Verify `MainTabContainerView`'s `TabView` is not recreating the
     home tab's `HomeDashboardView` on tab reselection (which would reset
     `@State navigationPath` to `[]`).
   - If view identity is the cause, lift navigation path to a parent
     `@StateObject` or `@SceneStorage` so it survives.
   - If the issue is purely test timing, increase the
     `waitForExistence(timeout:)` to 5 s.
   - If the issue is destination-renderer-side, ensure
     `InvestingAttitudeDetailView` is reached and its
     `InvestingAttitudeDetailTitle` text is exposed.
2. (AppLaunchContract / `-openReferral`) Investigate why
   `app.otherElements["SajuReferralRoot"]` is not found after
   `-openReferral`. Concrete next steps:
   - Confirm via the xcresult UI hierarchy whether `Step10ReferralView` is
     being rendered at all after `-openReferral` (i.e. is the route
     `.referral` even active when the test runs?).
   - If the view IS rendered, replace the wrapping change with a
     non-flattening anchor: e.g. an invisible `Color.clear` overlay that
     carries `.accessibilityIdentifier("SajuReferralRoot")` (the same
     pattern this slice already uses for `SajuTabRoot`).
   - If the route is NOT being applied, check whether the `applyLaunchArgs()`
     ordering or splash callback is overriding the route in the
     `-resetOnboarding -resetSajuInput -openReferral` argument combination.
3. Re-run UI tests until `AppLaunchContractUITests` and
   `SajuTabFoundationUITests` are fully green (21/21).

## Patch eligibility

Requires implementor rework.

The reviewer patch already covered the eligible/mechanical fixes (saju tab
a11y label, stale identifier in T29 assertion, ScrollView wrapping in
Step10ReferralView). The two remaining failures appear to require deeper
investigation (NavigationStack-in-TabView identity, route timing under
splash + multi-flag launch arg combo, or accessibility-tree flattening
under iOS 26) that exceed the reviewer's surgical-patch mandate.

## Patch applied

Reviewer applied three patches in this iteration (committed as
`c624b9c WF4-01 reviewer patches: saju tab a11y label + stale identifier + referral wrap`):

1. `Woontech/App/MainTabContainerView.swift` — moved
   `.accessibilityLabel(Text("사주 탭"))` from the TabView child view INTO
   the `.tabItem { Label(...) }` closure so it overrides the system tab
   bar item's accessibility label.
2. `WoontechUITests/Saju/SajuTabFoundationUITests.swift` —
   `test_homeAndSajuStacks_isolated()`: replaced two assertions on the
   deprecated identifier `HomeRoute_investingDest` with assertions on the
   currently-used `InvestingAttitudeDetailTitle`.
3. `Woontech/Features/SajuInput/Referral/Step10ReferralView.swift` —
   wrapped the body's `ScrollView` in a `VStack(spacing: 0)` and moved the
   `.accessibilityIdentifier("SajuReferralRoot")` (with
   `.accessibilityElement(children: .contain)`) onto that wrapper so the
   identifier sits on an `otherElements`-eligible container instead of
   the ScrollView.

## Verification after patch

Re-ran UI command:
`python3 tools/xcode_test_runner.py test --target WoontechUITests --ui
-only-testing:WoontechUITests/AppLaunchContractUITests
-only-testing:WoontechUITests/SajuTabFoundationUITests`

Result quoted from `.harness/test-results/last-ui-summary.txt`:
- `"result" : "Failed"`
- `"passedTests" : 19`, `"failedTests" : 2`, `"totalTestCount" : 21`

Patch #1 (saju tab a11y label) verified GREEN — the four saju-tab-bar
tests that previously failed (`test_tabBar_index2_tap_showsSajuTabView`,
`test_tabSwitch_preservesSajuPath`, `test_voiceOver_sajuTabBar_label_사주탭`,
and the saju portion of `test_homeAndSajuStacks_isolated`) now pass for
the tab-bar lookup. The saju tab cell is exposed as
`app.tabBars.buttons["사주 탭"]` with VoiceOver label "사주 탭".

Patch #2 (stale identifier) DID compile and is in the binary used for
the second run (the failure now reports the new line 229 with the new
assertion, confirming my edit was picked up), but the underlying
home-tab navigation push after a tab-switch sequence still does not
land on `InvestingAttitudeDetailTitle` within 3 s. The test still fails.

Patch #3 (Step10ReferralView wrapper) is in the binary (file is
committed) but the SajuReferralRoot identifier remains undiscoverable
under `app.otherElements`. The test still fails.

## Remaining risk

- The two remaining failures are gating the publish-readiness UI gate.
- Both failures are now well-characterised — the implementor has clear
  hypotheses to test (NavigationStack-in-TabView identity for #1; route
  application order or accessibility-tree flattening for #2).
- The saju-tab-foundation slice's own primary tests (T13-T28) all pass,
  so the WF4-01 slice itself is functionally correct; the remaining
  failures are at the integration boundary with the larger app shell
  (home navigation re-render, referral routing).

## Resolved since previous iteration

(none — this is iteration 1)

## Still outstanding from prior iterations

(none — this is iteration 1)
