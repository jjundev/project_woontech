# Implementation Review — WF4-03 사주 탭 Below-the-Fold

## Checklist status (all ✓)

| Step | Item | Status |
|------|------|--------|
| S1 | `SajuLearningPathProviding.swift` — `FeaturedLesson`, `CoursePath` structs; protocol + 4 props; default extensions; `MockSajuLearningPathProvider` mock defaults | ✓ |
| S2 | `SajuStudySectionHeaderView.swift` — Block A (header + streak badge + "전체 ›" button); `streakDays > 0` conditional; identifiers; VoiceOver labels | ✓ |
| S3 | `SajuFeaturedLessonCardView.swift` — Block B (50×50 placeholder + 3-line text); full-card Button; `.accessibilityElement(children: .ignore)` + label; identifier | ✓ |
| S4 | `SajuCourseCardView.swift` — Block C card; locked state; `GeometryReader` progress bar (3pt, clamp 0…1); `static func clampedProgress`; VoiceOver label; identifier | ✓ |
| S5 | `SajuCourseGridView.swift` — Block C grid; `static let fixedOrder`; name-match lookup; `LazyVGrid` 2-column spacing:8; identifier | ✓ |
| S6 | `SajuGlossaryCardView.swift` — Block D; no-op Button; subtitle conditional; `.accessibilityHint("준비중")`; identifier | ✓ |
| S7 | `SajuStudySectionView.swift` — Assembles Blocks A–E; `DisclaimerView()` reused; `.padding(.horizontal, 16)`; `.accessibilityElement(children: .contain)`; identifier | ✓ |
| S8 | `SajuTabContentView.swift` modified — `learningPathProvider` param added; `Spacer` replaced with `SajuStudySectionView` + `.padding(.top, 18)` | ✓ |
| S9 | `SajuTabView.swift` modified — passes `deps.learningPath` to `SajuTabContentView` | ✓ |
| S10 | `WoontechApp.swift` — Parses `-sajuStreakDays` / `-sajuFeaturedLessonNil` launch args; overrides `MockSajuLearningPathProvider` for UI tests TU-B03 / TU-B08 | ✓ |
| S11 | `WoontechTests/Saju/SajuBelowFoldTests.swift` — TB-01 through TB-25 (25 unit tests) | ✓ |
| S12 | `WoontechUITests/Saju/SajuBelowFoldUITests.swift` — TU-B01 through TU-B21 (21 UI tests) | ✓ |

**Requirements checked:**

| ID | Description | Verified |
|----|-------------|---------|
| R1 | 18pt top margin, below above-fold, single scroll | ✓ (`.padding(.top, 18)` on `SajuStudySectionView` in `SajuTabContentView`) |
| R2 | Streak badge `streakDays > 0` conditional pill | ✓ |
| R3 | "전체 ›" tap → `.learn` route | ✓ |
| R4 | Featured lesson card binds title/duration/level | ✓ |
| R5 | Featured lesson card tap → `.lesson(id:)` route | ✓ |
| R6 | `featuredLesson = nil` → card hidden | ✓ (`if let lesson = provider.featuredLesson`) |
| R7 | Fixed 4-slot grid `["입문","오행","십성","대운"]`; locked state for missing | ✓ |
| R8 | Progress bar `clamp(progress, 0…1) × 100%` | ✓ |
| R9 | Course card tap → `.learn` route | ✓ |
| R10 | Glossary subtitle conditional on `glossaryTermCount` | ✓ |
| R11 | Glossary tap no-op; `.accessibilityHint("준비중")` | ✓ |
| R12 | `DisclaimerView` reused; "본 앱은 학습·참고용이며 투자 권유가 아닙니다." text present | ✓ |
| R13 | TabBar active=2 via `-openSajuTab` launch arg (existing WF4-01 infra) | ✓ |
| R14 | Dynamic Type XL — cards use `fixedSize`-compatible layout; progress bar in `.frame(height: 3)` | ✓ |
| R15 | VoiceOver label "오늘의 한 가지, {title}, {duration}, {level}" | ✓ |
| R16 | All cards `.frame(minHeight: 44)` | ✓ |
| R17 | Streak badge `.accessibilityLabel("연속 학습 {n}일")` | ✓ |
| R18 | Course card VoiceOver `"{name} 코스, {lessonCount}강, 진행률 {pct}%"` | ✓ |
| R19 | Glossary VoiceOver label | ✓ |
| R20 | 16pt horizontal padding; 8pt grid spacing; 18pt section margin; DesignTokens used | ✓ |
| R21 | Mock defaults: streakDays=3, featuredLesson L-TEN-001 "십성이란 무엇인가?", 4 courses, glossary=120 | ✓ |

## Build / Test results

**Build:** Passed (exit 0)

**Unit tests:**  
`Total: 27, Passed: 27, Failed: 0, Skipped: 0`  
_(from `.harness/test-results/last-unit-summary.txt` — SajuBelowFoldTests TB-01…TB-25 + SajuTabDependenciesTests T4/T5)_

**UI tests:** Deferred to dedicated harness verification gate (per reviewer instructions; not run in this phase).

## Accessibility contract audit

No `TabView` topology changes in this diff. The diff adds `SajuStudySectionView` inside `SajuTabContentView` (inside an existing `NavigationStack`); no new `TabView`, `navigationDestination`, `.sheet`, or `.fullScreenCover` were introduced.

All accessibility identifiers use `accessibilityElement(children: .contain)` on containers, and `accessibilityElement(children: .ignore)` on leaf Button cards — preventing identifier scope flattening. Query type alignment verified:

| Test query | Identifier | SwiftUI type | Match |
|-----------|-----------|-------------|-------|
| `app.otherElements["SajuStudySection"]` | VStack w/ `.contain` | container | ✓ |
| `app.staticTexts["SajuStreakBadge"]` | Text | staticTexts | ✓ |
| `app.buttons["SajuStudyAllButton"]` | Button | buttons | ✓ |
| `app.buttons["SajuFeaturedLessonCard"]` | Button | buttons | ✓ |
| `app.otherElements["SajuCourseGrid"]` | LazyVGrid w/ `.contain` | container | ✓ |
| `app.buttons["SajuCourseCard_*"]` | Button | buttons | ✓ |
| `app.buttons["SajuGlossaryCard"]` | Button | buttons | ✓ |
| `app.staticTexts["DisclaimerText"]` | Text | staticTexts | ✓ |

No TabView-child identifier attachment; no `children: .combine` (default) used on identifier-bearing containers.

## Notes

- `SajuCourseGridView.fixedOrder` is `static let`, enabling direct unit-test access in TB-10 without SwiftUI rendering.
- `SajuCourseCardView.clampedProgress(_:)` is `static func`, enabling direct unit-test calls in TB-12/TB-13.
- `SajuGlossaryCardView.subtitle` is an `internal var`, enabling direct unit-test access in TB-18/TB-19.
- Launch arg handling in `WoontechApp.swift` follows the existing `-resetOnboarding`/`-openSajuTab` pattern, correctly overriding `MockSajuLearningPathProvider` for `-sajuStreakDays 0` and `-sajuFeaturedLessonNil 1`.
- `DisclaimerView` reused directly from `Features/Home/`; no copy created (plan risk #3 addressed).
- pbxproj: all 8 new `.swift` files confirmed with both `PBXFileReference` and `PBXBuildFile in Sources` entries.
