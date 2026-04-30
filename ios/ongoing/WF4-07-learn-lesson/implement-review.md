# Implementation Review

## Checklist status (all ✓)

- ✓ R1: `SajuRoute.lesson(id:)` → `SajuLessonView` wired in `SajuRouteDestinations.swift`
- ✓ R2: `navigationTitle("\(lesson.number)강 · \(lesson.title)")` inline display mode
- ✓ R3: toolbar trailing item with muted `"\(currentIndex)/\(totalCount)"` + accessibilityLabel
- ✓ R4/R5: `static func progressRatio(currentIndex:totalCount:)` with `min(..., 1.0)` clamp; tested
- ✓ R6: `sectionLabel`, `headline`, `conceptBox`, `diagramPlaceholderLabel` bound from `Lesson`
- ✓ R7: `precondition(quiz.choices.count == 4, ...)` in `QuizCardView`; 4-choice ForEach
- ✓ R8/R9/R10/R11: `choiceAppearance(index:selected:correct:)` pure helper; `guard selectedChoiceIndex == nil` prevents reselection; CTA gated on `selectedChoiceIndex != nil`
- ✓ R12: `onReplaceTop` callback wired in `SajuTabView` (`removeLast + append`); `SajuLessonView` calls `onReplaceTop(.lesson(id: nextId))`
- ✓ R13: `ctaLabel = nextLessonId == nil ? "학습 완료" : "다음 강의"`; `dismiss()` on nil path
- ✓ R14: `MockSajuLessonProvider` returns `fallbackLesson` (`isFallback: true`) for unknown ids; quiz card hidden when `lesson.isFallback`; CTA disabled via `ctaEnabled = !lesson.isFallback && selectedChoiceIndex != nil`
- ✓ R15: `SajuLessonProviding` and `SajuLearningPathProviding` are separate protocols; `MockSajuLessonProvider` does not conform to `SajuLearningPathProviding`; TL07-23 verifies at runtime
- ✓ R16: VoiceOver helpers implemented: `progressBarA11yLabel`, `quizA11yLabel`, `choiceA11yValue`; trailing toolbar `.accessibilityLabel("현재 \(n)강, 총 \(t)강")`; `DiagramPlaceholderView` label `"다이어그램 자리, \(label)"`
- ✓ R17: `.frame(minHeight: 44)` on `ChoiceOptionView` and CTA button label container
- ✓ R18: `.fixedSize(horizontal: false, vertical: true)` on `headline`, `conceptBox`, `question`; progress bar height fixed at 3pt

Implementation steps:
- ✓ S1: `SajuLessonProviding.swift` fully rewritten — `Choice`, `Quiz`, `Lesson` (+`isFallback`), `MockSajuLessonProvider` (default + "L-OH-LAST" + fallback), `NoNextLessonProvider`; `SajuTabDependenciesTests.StubSajuLessonProvider` updated
- ✓ S2: `DesignTokens.swift` — 4 quiz tokens: `quizCorrectBorder`, `quizCorrectBackground`, `quizIncorrectBorder`, `quizIncorrectBg`
- ✓ S3–S7: `SajuLessonView.swift` with `progressBarView`, `ConceptBoxView`, `DiagramPlaceholderView`, `QuizCardView`, `ChoiceOptionView`, `BottomCTABarView`
- ✓ S8: `SajuRouteDestinations.swift` — `onReplaceTop` parameter added; `.lesson(id:)` case uses `SajuLessonView`
- ✓ S9: `SajuTabView.swift` — `onReplaceTop` closure; 3 new push buttons (`SajuNavPush_lessonLOH003`, `SajuNavPush_lessonNoNext`, `SajuNavPush_lessonUnknownId`)
- ✓ S10: `WoontechApp.swift` — `-sajuLessonNoNextId` launch arg parsed; `NoNextLessonProvider` injected into `SajuTabDependencies` when present
- ✓ S11: `SajuLessonTests.swift` — 32 tests covering TL07-01 through TL07-32
- ✓ S12: `SajuLessonUITests.swift` — 24 tests covering TU-LS01 through TU-LS24

Target membership (`project.pbxproj`):
- ✓ `SajuLessonView.swift` — PBXFileReference (A0010848…) + PBXBuildFile in Sources (B0010848…)
- ✓ `SajuLessonTests.swift` — PBXFileReference (A0010849…) + PBXBuildFile in Sources (B0010849…)
- ✓ `SajuLessonUITests.swift` — PBXFileReference (A0010850…) + PBXBuildFile in Sources (B0010850…)

Accessibility contract (no topology change; SajuLessonView is a new destination in the existing NavigationStack):
- `SajuLessonView` root: `Color.clear` 1×1 overlay leaf-marker → `otherElements` ✓
- `SajuLessonProgressBar`: `.accessibilityElement(children: .ignore)` on GeometryReader → `otherElements` ✓
- `SajuLessonSectionLabel`, `SajuLessonHeadline`: plain `Text` → `staticTexts` ✓
- `SajuLessonConceptBox`: `Text` chain + `.accessibilityElement(children: .ignore)` → `otherElements` ✓
- `SajuLessonDiagramPlaceholder`: `ZStack` + `.accessibilityElement(children: .ignore)` → `otherElements` ✓
- `SajuLessonQuizCard`: `VStack` + `.accessibilityElement(children: .contain)` — children accessible ✓
- `SajuLessonQuizChoice_0`–`_3`: `Button` → `buttons` ✓
- `SajuLessonNextCTA`: `Button` → `buttons` ✓
- No identifier placed on TabView child or above `.tabItem`/`.toolbar` ✓

## Build / Test results

Build: PASSED (exit 0, no errors)

Unit tests (WoontechTests/SajuLessonTests + WoontechTests/SajuTabDependenciesTests):
```
Total: 34, Passed: 34, Failed: 0
result: "Passed"
```
*(Quoted from `.harness/test-results/last-unit-summary.txt`)*

UI tests: Not run in this phase (reserved for the dedicated harness verification gate).

## Notes

- `choiceA11yValue` correctly returns `"정답"` for the correct-index slot even when an *incorrect* answer was selected (the third branch: `index == correct && sel != correct`), matching spec AC#10.
- Fallback lesson CTA is disabled via `ctaEnabled = !lesson.isFallback && selectedChoiceIndex != nil`, ensuring the "학습 완료" path is unreachable for unknown-id lessons as intended.
- `NoNextLessonProvider` (returns `lastLesson` for any id) is correctly injected when `-sajuLessonNoNextId` launch arg is present, supporting TU-LS16/17 without requiring a separate mock class per test.
