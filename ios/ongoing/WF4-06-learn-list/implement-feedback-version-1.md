# Implement Feedback v1

## Checklist items not met

All checklist items (R1–R20, S1–S11, T1–T30) were implemented correctly.  
Two issues were found that required reviewer patches before the UI test gate.

---

## Build / Test failures

- **Build**: SUCCEEDED (no compiler errors).
- **Unit tests**: `Total: 30, Passed: 30, Failed: 0` — all 30 `SajuLearnListTests` tests passed.
- **UI tests**: Not run in this phase (harness gate). Two regressions pre-empted:
  1. `SajuBelowFoldUITests.test_allButton_tap_pushesLearnRoute` — expected `SajuPlaceholderDestination_learn` (stale assertion); now `.learn` pushes `SajuLearnListView`.
  2. `SajuBelowFoldUITests.test_courseCard_tap_pushesLearn` — same stale assertion.
  3. `SajuLearnListView.ToastBannerView` — `Text`-based view without `.accessibilityElement(children: .contain)` would be exposed as `staticTexts`, but tests query `otherElements["SajuLearnToast"]` (type mismatch).

---

## Required changes

1. `WoontechUITests/Saju/SajuBelowFoldUITests.swift` lines 82 and 210: Replace `SajuPlaceholderDestination_learn` with `SajuLearnListView` (two assertions broken by the `.learn`-route change).
2. `Woontech/Features/Saju/Learn/SajuLearnListView.swift` `ToastBannerView`: Add `.accessibilityElement(children: .contain)` to ensure `otherElements["SajuLearnToast"]` resolves in XCTest (avoids `Text` → `staticTexts` type mismatch).

---

## Patch eligibility

`Eligible for reviewer patch`

Both fixes are:
- Small and localized (2 lines in test file + 1 line in source)
- Do not change `spec.md` / `implement-checklist.md` meaning
- Do not change public API contracts or data model
- Do not introduce new dependencies or architecture

---

## Patch applied

**Commit**: `6018210` — "reviewer: fix SajuBelowFoldUITests learn-route assertions and ToastBannerView accessibility type"

Changed files:
- `WoontechUITests/Saju/SajuBelowFoldUITests.swift`: Two `waitForExistence` assertions updated from `SajuPlaceholderDestination_learn` to `SajuLearnListView`.
- `Woontech/Features/Saju/Learn/SajuLearnListView.swift`: Added `.accessibilityElement(children: .contain)` to `ToastBannerView.body` after `.background(...)`.

---

## Verification after patch

- Build: SUCCEEDED (no compiler errors).
- Unit tests (post-patch): `Total: 30, Passed: 30, Failed: 0`.

---

## Remaining risk

1. **`SajuLearnCourseHeader` label assertion (TU-L14)**: `CourseHeaderView` uses `.accessibilityElement(children: .contain)` without an explicit `.accessibilityLabel`. The UI test checks `header.label.contains("입문 코스")` and `.contains("7강")`. If XCTest doesn't aggregate child labels for `.contain` containers, TU-L14 may fail. However, this mirrors the pattern used by other similar views in the codebase and is expected to work.
2. **`SajuLearnStreakBadge` as `staticTexts` (TU-L11/TU-L12)**: The badge is a `Text` inside `SajuWeeklyProgressBannerView` which uses `.accessibilityElement(children: .contain)`. The test queries `app.staticTexts.matching(identifier == 'SajuLearnStreakBadge')`. Assuming children remain accessible as `staticTexts` under a `.contain` container, this should work.

---

## Resolved since previous iteration

*(Iteration 1 — no prior feedback file)*

---

## Still outstanding from prior iterations

*(Iteration 1 — no prior feedback file)*
