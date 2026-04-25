# Implement Feedback v1

## Checklist items not met

- **R3 / R4 / R6 / R7 / R8 / R9 / R10 / R11 / R12 / R14 / R15 / T12–T27 (UI tests)**:
  The full UI test target is failing. According to
  `/tmp/woontech-derived-data/ui/Logs/Test/LogStoreManifest.plist`,
  `totalNumberOfTestFailures = 16` while only 17 UI tests exist in
  `TodayDetailUITests`. That means essentially the entire UI test suite added in
  this iteration is red. The build is green and the WoontechTests unit suite
  (`TodayDetailViewTests`, T1–T11) passes, so the failure is specific to the
  UI / accessibility / navigation surface of `TodayDetailView`.

  At least one concrete cause is identifiable from inspection (see "Required
  changes" below); the remaining failures cannot be diagnosed from the
  truncated runner output, so the implementor must reproduce locally with full
  xcresult output (e.g. `xcrun xcresulttool get --legacy --path …`) and trace
  the root cause(s).

## Build / Test failures

- `python3 tools/xcode_test_runner.py build` — succeeded (no errors emitted).
- `python3 tools/xcode_test_runner.py test --target WoontechTests -only-testing:WoontechTests/TodayDetailViewTests` — succeeded
  (no failures observed; "Testing started completed" terminated cleanly).
- `python3 tools/xcode_test_runner.py test --target WoontechUITests --ui -only-testing:WoontechUITests/TodayDetailUITests` — **FAILED**
  - Exit code 65, "** TEST FAILED **".
  - Manifest at
    `/tmp/woontech-derived-data/ui/Logs/Test/Test-Woontech-2026.04.25_14-41-52-+0900.xcresult`
    reports `totalNumberOfTestFailures = 16`.
  - The runner's environment-failure repair triggered on the first attempt
    (DebuggerVersionStore / "no debugger version") and then re-ran; the second
    attempt also ended in TEST FAILED, so this is not a transient simulator
    environment issue.
  - Per-test failure messages were truncated by the harness, so individual
    XCTAssert messages are not available in this review. The implementor
    must run the suite locally and read the xcresult.

## Required changes

### C1 — Fix the accessibility hierarchy of `HapchungRowView` (definite bug)

`Woontech/Features/Home/Detail/Today/TodayDetailView.swift`, `HapchungRowView`
applies:

```swift
.accessibilityElement(children: .ignore)
.accessibilityLabel("\(event.branch1.hanja) \(symbol) \(event.branch2.hanja), \(event.kind), \(event.score)점")
.accessibilityIdentifier("HapchungRow_\(index)")
```

`children: .ignore` collapses the row into a single accessibility element, so
the child identifiers placed inside the same `VStack`
(`HapchungRow_\(index)_Score` on the score `Text`, and the
`HapchungRow_\(index)_NegativeStyle` invisible `Color.clear`) are **not** exposed
to XCUITest. This directly breaks at minimum these tests:

- T21 / UI10 `testHapchungNegativeRowStyling` — looks up
  `app.otherElements["HapchungRow_1_NegativeStyle"]`.
- T22 / UI11 `testHapchungScoreFormatting` — looks up
  `app.staticTexts["HapchungRow_0_Score"]` / `HapchungRow_1_Score`.
- T26 / UI16 `testDynamicTypeXL_hapchungWrapsScoreVisible` — looks up
  `app.staticTexts["HapchungRow_0_Score"]`.

Fix options (pick one and apply consistently to all rows):

1. Replace `.accessibilityElement(children: .ignore)` with
   `.accessibilityElement(children: .contain)` (children remain queryable; the
   row itself stays addressable via `HapchungRow_\(index)` and the explicit
   `accessibilityLabel`).
2. Or drop `.accessibilityElement(...)` entirely and instead attach the
   container identifier and label via a sibling background/overlay that
   doesn't suppress children.

Either way, after the fix XCUITest must be able to resolve
`app.staticTexts["HapchungRow_0_Score"].label == "+12"` and
`app.otherElements["HapchungRow_1_NegativeStyle"].exists`.

### C2 — Investigate the remaining UI test failures

With 16 failures across independent tests (NavBar back, pillar IDs, wuxing
cells, sipseong stamp, motto/taboo, Disclaimer, etc.), the cause is almost
certainly *not* limited to C1. Probable categories:

- App crashes on `TodayDetailView.appear` (e.g. SwiftUI runtime trap inside
  `SajuMiniChartView` when re-used with this caller's parameters — the data
  shape passed by `SajuOriginCard.makeWuxingBars` etc. is new).
- `HomeNavPushToday` button tap not actually pushing `.today`, or
  `TodayDetailTitle` not appearing for some other reason (e.g. parent
  `.toolbar(.hidden, for: .navigationBar)` / `NavigationStack` interaction
  pattern differs from `InvestingAttitudeDetailView`).
- A SwiftUI layout error in `HapchungCard` / `WuxingDistributionRow` causing
  the whole detail view to fail to render.

Required: the implementor must reproduce the suite locally, retrieve the
per-test failure messages from the xcresult bundle (`xcrun xcresulttool get
--legacy --path /tmp/woontech-derived-data/ui/Logs/Test/Test-Woontech-*.xcresult`
or open it in Xcode), and address each root cause until the suite is green.

### C3 — Verify `accessibilityIdentifier("HapchungSection")` actually registers

`HapchungCard(events: provider.hapchungEvents).accessibilityIdentifier("HapchungSection")`
attaches the identifier to the wrapping struct. The internal `VStack` already
has padding/overlay; verify in the XCUITest debugger
(`po app.debugDescription`) that an `XCUIElementType` actually exposes
`HapchungSection`. If not, push the identifier onto the inner `VStack` so
T20 (`testHapchungCardHiddenWhenEmpty`) can rely on it.

### C4 — Confirm `WuxingCell_*` cell labels include the hanja and count

T15 / UI4 asserts `woodCell.label.contains("木")` and `woodCell.label.contains("1")`.
Current implementation sets `accessibilityLabel("\(element.label) \(element.hanja) \(count)")`
on each cell, which should satisfy that — but verify after fixing the broader
crash/render issue.

## Patch eligibility

Requires implementor rework.

C1 alone is a small localized fix and would be patch-eligible, but C2 — the
bulk of the failing tests — requires running the suite locally with full
xcresult inspection to determine root causes. That goes beyond a "small,
localized" reviewer patch. Patching C1 in isolation would still leave the
suite red and would obscure the real problem from the next iteration.
The fix set must be developed and verified by the implementor against actual
per-test failure output.

## Patch applied

Not applied; requires implementor rework.

## Verification after patch

Not run after patch; no reviewer patch was applied.

## Remaining risk

- Until the implementor sees the per-test failure messages, the actual cause
  of most of the 16 failures is unknown. The fix set listed above (C1, C3,
  C4) addresses inspection-level findings only; C2 may require non-trivial
  changes (e.g. how `SajuMiniChartView` is called, navigation pattern, or
  view hierarchy).
- pbxproj target membership for all four new `.swift` files
  (`TodayDetailProviding.swift`, `TodayDetailView.swift`,
  `TodayDetailViewTests.swift`, `TodayDetailUITests.swift`) is already
  correct — confirmed both `PBXFileReference` and `PBXBuildFile … in Sources`
  entries exist (lines 96–99, 209–212, 339, 386, 497–498, 647, 719–720, 736
  of `Woontech.xcodeproj/project.pbxproj`). No false positive there.

## Resolved since previous iteration

(Iteration 1 — no prior feedback.)

## Still outstanding from prior iterations

(Iteration 1 — no prior feedback.)
