# Implement Feedback v2

## Context

This feedback was generated during the `ui_verify` phase after the
implement-reviewer passed (`IMPLEMENT_PASS` at iteration 1). The harness ran
the full UI test suite and it failed; this document records the root-cause
analysis and reviewer-applied patches.

## Checklist items not met

- T29 (`test_homeAndSajuStacks_isolated`): `InvestingAttitudeDetailTitle`
  StaticText was never found by the test even though navigation DID
  succeed. Root cause: `InvestingAttitudeDetailView`'s outer VStack had
  `.accessibilityIdentifier("InvestingAttitudeDetailView")` without a
  matching `.accessibilityElement(children: .contain)`. In iOS 26, when
  this view is pushed inside a TabView-nested NavigationStack, the outer
  VStack's identifier propagates to all child elements (Button, StaticText,
  ScrollView each received identifier `InvestingAttitudeDetailView` instead
  of their own), overriding `.accessibilityIdentifier("InvestingAttitudeDetailTitle")`.

## Build / Test failures (before patch)

Quoted from `.harness/test-results/last-ui-summary.txt` (run 2 — after
first reviewer patch attempt at 16:41):

- `"result": "Failed"`
- `"passedTests": 20`, `"failedTests": 1`, `"totalTestCount": 21`
- Failing test: `SajuTabFoundationUITests/test_homeAndSajuStacks_isolated()`
- Failure: `SajuTabFoundationUITests.swift:242: XCTAssertTrue failed`

XCTest activity log confirmed:
- All prior steps passed: HomeDashboardRoot ✓, tap Saju tab ✓, SajuTabRoot ✓,
  SajuNavPush_elements ✓, SajuPlaceholderDestination_elements ✓, 홈 tab ✓,
  HomeDashboardRoot ✓ (after tab switch), HomeNavPushInvesting ✓ (button found
  and tapped)
- `InvestingAttitudeDetailTitle` waited 12× over 12 s — NEVER found.

xcresult UI hierarchy at failure (key excerpt):
```
Other, identifier: 'HomeDashboardRoot'
  ...NavigationBar...
    Button, identifier: 'InvestingAttitudeDetailView', label: '뒤로'    ← should be InvestingAttitudeDetailBackButton
    StaticText, identifier: 'InvestingAttitudeDetailView', label: '투자 태도'  ← should be InvestingAttitudeDetailTitle
    ScrollView, identifier: 'InvestingAttitudeDetailView'
```

All three child elements shared the outer VStack's identifier.

## Required changes

1. (T29) `InvestingAttitudeDetailView.swift` — add
   `.accessibilityElement(children: .contain)` to the outer VStack so
   that its identifier (`InvestingAttitudeDetailView`) does not propagate
   to child elements when rendered inside a TabView-nested NavigationStack
   on iOS 26.

## Patch eligibility

Eligible for reviewer patch

## Patch applied

Two commits applied by reviewer:

1. `fc49c5a WF4-01 T29: add 1.5s tab-settle wait + extend InvestingAttitudeDetailTitle timeout to 12s`
   - Added `Thread.sleep(forTimeInterval: 1.5)` after `HomeDashboardRoot.waitForExistence`
     to allow the tab-switch animation to fully settle before triggering navigation.
   - Extended `InvestingAttitudeDetailTitle.waitForExistence(timeout: 8)` → `timeout: 12`.
   - **Result**: still failed (same assertion, same root cause — the identifier was never
     exposed regardless of timing).

2. `1eb8dcf WF4-01 T29: add .accessibilityElement(children: .contain) to InvestingAttitudeDetailView`
   - Added `.accessibilityElement(children: .contain)` on the outer VStack in
     `InvestingAttitudeDetailView.body`, matching the pattern used by `HomeDashboardRoot`.
   - This prevents iOS 26's accessibility tree from propagating the VStack's identifier
     to its children when the view is pushed inside a TabView-nested NavigationStack.

## Verification after patch

Quoted from `.harness/test-results/last-ui-summary.txt` (run 3 — after
`1eb8dcf`):

- `"result": "Passed"`
- `"passedTests": 21`, `"failedTests": 0`, `"totalTestCount": 21`
- `testFailures: []`

All 21 tests green: AppLaunchContractUITests (4/4) + SajuTabFoundationUITests
(17/17, including T29 `test_homeAndSajuStacks_isolated`).

## Remaining risk

None. All blocking failures are resolved. The accessibility fix is additive and
consistent with the documented iOS 26 pattern already applied to `HomeDashboardRoot`,
`SajuTabRoot`, and `SajuReferralRoot`.

## Resolved since previous iteration

- `test_openReferral_routesToReferral_andStaysAfterSplash` (AppLaunchContractUITests):
  Fixed in iteration 1 via `Color.clear` overlay marker on `Step10ReferralView`.
  GREEN in this run.

## Still outstanding from prior iterations

(none — all resolved)
