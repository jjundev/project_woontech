# Implementation Review

## Checklist status (all ✓)

| ID | Requirement | Status |
|----|-------------|--------|
| R1 | `SajuLearnListView` wired in `SajuRouteDestinations` for `.learn` case | ✓ |
| R2 | NavBar title "사주 공부" + trailing muted "검색" Button (no-op, hint "준비중") | ✓ |
| R3 | Category pill area renders `[전체, 입문, 오행, 십성, 대운, 합충]` in fixed order | ✓ |
| R4 | Initial selection is "all" pill (black bg + white bold); others unselected | ✓ |
| R5 | Pill tap → single selection switch; course list unchanged | ✓ |
| R6 | Streak badge conditional on `streakDays > 0`; "{completed} / {goal}강 완료" bound | ✓ |
| R7 | Progress bar width = `clamp(ratio, 0, 1) × 100%` via `SajuWeeklyProgressBannerView.clampedRatio` | ✓ |
| R8 | Course header: "{course.name} 코스" + "{lessonCount}강 · 평균 {averageMinutes}분" | ✓ |
| R9 | Lesson list in `course.lessons` order; count = `lessonCount` (mock default 7) | ✓ |
| R10 | completed indicator = black fill + white checkmark SVG | ✓ |
| R11 | current indicator = white bg + black stroke + number; meta appends " · 이어보기" | ✓ |
| R12 | pending indicator = gray stroke + number; right chevron | ✓ |
| R13 | locked indicator = gray stroke + number(muted); right lock.fill icon | ✓ |
| R14 | completed/current/pending tap → `onNavigate(.lesson(id:))` | ✓ |
| R15 | locked tap → no push; toast "이전 강의를 먼저 완료하세요" 2s auto-dismiss; VoiceOver announcement | ✓ |
| R16 | Article section hidden when `recommendedArticles.isEmpty` | ✓ |
| R17 | Article card tap no-op; `.accessibilityHint("준비중")` | ✓ |
| R18 | "검색" tap no-op; `.accessibilityHint("준비중")` | ✓ |
| R19 | Hit targets ≥ 44pt on all interactive elements (`.frame(minHeight: 44)` + `.contentShape(Rectangle())`) | ✓ |
| R20 | Dynamic Type XL wrapping; indicator 28pt fixed frame | ✓ |
| S1–S11 | All implementation steps complete | ✓ |
| T1–T30 | All 30 unit tests written and passing | ✓ |
| T31–T61 | All 31 UI tests written | ✓ |

**pbxproj membership** (all 7 new files confirmed with both `PBXFileReference` and `PBXBuildFile in Sources`):
- `SajuLearnListView.swift` ✓
- `SajuLearnCategoryPillsView.swift` ✓
- `SajuWeeklyProgressBannerView.swift` ✓
- `SajuLessonRowCardView.swift` ✓
- `SajuLearnArticleCardView.swift` ✓
- `SajuLearnListTests.swift` ✓
- `SajuLearnListUITests.swift` ✓

**Iteration-1 reviewer patches verified:**
- `SajuBelowFoldUITests.swift` lines 82 & 210: `SajuPlaceholderDestination_learn` → `SajuLearnListView` ✓
- `ToastBannerView.body`: `.accessibilityElement(children: .contain)` added ✓

**Accessibility contract audit:**
- No `.accessibilityIdentifier` placed directly on a `TabView` child ✓
- `SajuLearnListView` root `ZStack`: `.accessibilityElement(children: .contain)` + `.accessibilityIdentifier("SajuLearnListView")` → `otherElements` query ✓
- `SajuLearnCategoryPillsView` scroll container: `.contain` + identifier; pills are `Button` → `buttons` query ✓
- `SajuWeeklyProgressBannerView`: `.contain` + label + identifier → `otherElements` query; `SajuLearnStreakBadge` `Text` child accessible as `staticTexts` under `.contain` ✓
- `CourseHeaderView`: `.contain` + identifier → `otherElements` query with child label aggregation ✓
- `SajuLessonRowCardView`: `Button` + `.accessibilityLabel` + identifier → `buttons` query ✓
- `ArticlesSectionView`: `.contain` + identifier → `otherElements` query ✓
- `ToastBannerView`: `.contain` inside view + identifier from call site → `otherElements["SajuLearnToast"]` query ✓
- `SajuLearnArticleCardView`: `Button` + hint + identifier → `buttons` query ✓

## Build / Test results

**Build:** SUCCEEDED (no compiler errors)

**Unit tests:** `Total: 30, Passed: 30, Failed: 0`
(from `.harness/test-results/last-unit-summary.txt`, bundle `Test-Woontech-unit-20260430-014036-...`)

**UI tests:** Not run in this phase — harness runs them in the dedicated verification gate after IMPLEMENT_PASS.

## Notes

- All spec requirements (R1–R20) and checklist steps (S1–S11) are fully implemented.
- Both reviewer patches applied in iteration 1 are verified intact in the current source.
- The remaining risk items flagged in feedback-v1 (CourseHeader `.contain` label aggregation and StreakBadge `staticTexts` exposure) have been inspected; both use well-established patterns from the existing codebase and are not blocking.
- `WoontechApp.swift` correctly parses `-sajuLearnArticlesEmpty` and `-sajuLearnStreakZero` launch args and constructs the appropriate `MockSajuLearningPathProvider` variants for UI test gates.
