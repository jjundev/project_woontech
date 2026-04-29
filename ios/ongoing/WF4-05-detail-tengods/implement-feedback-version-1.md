# Implement Feedback v1

## Checklist items not met

All checklist items were met by the original implementation. The failing test was a scroll-targeting fragility in the UI test, not a missing feature.

## Build / Test failures

**UI test failure (from `.harness/test-results/last-ui-failures.txt`):**

```
- Woontech > WoontechUITests > SajuTenGodsDetailUITests > testLearnEntry_tap_pushesLessonRoute()
  type: Test Case
  result: Failed
- Woontech > WoontechUITests > SajuTenGodsDetailUITests > testLearnEntry_tap_pushesLessonRoute() > SajuTenGodsDetailUITests.swift:276: XCTAssertTrue failed - SajuPlaceholderDestination_lesson must appear after tapping learn entry
  type: Failure Message
```

**Root cause:** `testLearnEntry_tap_pushesLessonRoute()` (T50) called `app.scrollViews.firstMatch.swipeUp()` which is ambiguous when `SajuTenGodsDetailView` is pushed onto the navigation stack. At that point the accessibility tree contains two scroll views:
1. `SajuTabContentView`'s scroll view (`"SajuTabContent"`) — background, behind navigation
2. `SajuTenGodsDetailView`'s root `ScrollView` — foreground, active

`firstMatch` resolved to the background scroll view. Swiping the wrong scroll view left `TenGodsLearnEntryCard` off-screen (or at coordinates where `tap()` missed the hit-test area), so `onNavigate(.lesson(id:))` was never called and `SajuPlaceholderDestination_lesson` never appeared. `waitForExistence` passed (accessibility finds off-screen elements in scroll views) but `tap()` failed silently.

The other T46–T49, T51–T59 tests all pass because they only call `waitForExistence` or check Y-position ordering — none require the element to be physically hittable.

## Required changes

1. **`SajuTenGodsDetailView.swift`** — Add `.accessibilityElement(children: .contain)` + `.accessibilityIdentifier("SajuTenGodsDetailScroll")` to the root `ScrollView` so XCTest can query it by name.

2. **`SajuTenGodsDetailUITests.swift` — `testLearnEntry_tap_pushesLessonRoute()`** — Replace `app.scrollViews.firstMatch.swipeUp()` with two swipes on the named `app.scrollViews["SajuTenGodsDetailScroll"]`, matching the reliable pattern used in `SajuBelowFoldUITests.scrollToBelowFold()`.

## Patch eligibility

Eligible for reviewer patch

## Patch applied

Both changes applied by reviewer:

**`SajuTenGodsDetailView.swift`** — Added two modifiers immediately after the `ScrollView { ... }` closing brace, before `.background(...)`:
```swift
.accessibilityElement(children: .contain)
.accessibilityIdentifier("SajuTenGodsDetailScroll")
```

**`SajuTenGodsDetailUITests.swift`** — Replaced the `testLearnEntry_tap_pushesLessonRoute()` scroll block:
```swift
// Before
app.scrollViews.firstMatch.swipeUp()
let learnCard = app.buttons["TenGodsLearnEntryCard"]
XCTAssertTrue(learnCard.waitForExistence(timeout: 5), "TenGodsLearnEntryCard must be tappable")
learnCard.tap()

// After
let scroll = app.scrollViews["SajuTenGodsDetailScroll"]
XCTAssertTrue(scroll.waitForExistence(timeout: 5), "SajuTenGodsDetailScroll must exist")
scroll.swipeUp()
scroll.swipeUp()
let learnCard = app.buttons["TenGodsLearnEntryCard"]
XCTAssertTrue(learnCard.waitForExistence(timeout: 5), "TenGodsLearnEntryCard must be tappable")
learnCard.tap()
```

Committed as: `fix: use named SajuTenGodsDetailScroll view to reliably scroll in T50` (90c09c2)

## Verification after patch

**Build:** Passed (exit 0). `python3 tools/xcode_test_runner.py build` completed with no errors.

**Unit tests:** `Total: 32, Passed: 32, Failed: 0, Skipped: 0` — result: Passed
(From `.harness/test-results/last-unit-summary.txt`, bundle: Test-Woontech-unit-20260428-133757-8485-1777351077010439000.xcresult)

**UI tests:** Could not re-run in this reviewer phase (UI test command not in the Bash allowlist for the `ui_verify` phase). The harness will re-run them in the next verification gate. The patch is mechanically correct: `app.scrollViews["SajuTenGodsDetailScroll"]` will resolve exclusively to the foreground detail scroll view (the only one with that identifier), and two `swipeUp()` calls provide sufficient scroll depth to bring `TenGodsLearnEntryCard` into the tappable viewport.

## Remaining risk

Low. The `"SajuTenGodsDetailScroll"` identifier follows the same pattern as `"SajuTabContent"` (already proven reliable in `SajuBelowFoldUITests`). The `.accessibilityElement(children: .contain)` modifier preserves child accessibility so all existing `TenGodsLearnEntryCard`, `TenGodsSummaryCard`, etc. queries remain unaffected. The `Color.clear` root marker (`SajuTenGodsDetailView`) is unmodified.

## Resolved since previous iteration

N/A (this is iteration 1; there is no previous feedback file).

## Still outstanding from prior iterations

N/A
