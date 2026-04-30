# Plan Feedback v2

## Problems

### P1 — Quiz VoiceOver label "퀴즈, {question}" has no test (AC#16 gap)

The spec's non-functional constraints specify:
> 퀴즈 = "퀴즈, {question}". 옵션 = "{symbol}".

`"{symbol}"` is covered by TL07-30. However there is no unit test for the quiz card's
accessibility label format `"퀴즈, {question}"`. Version 2 added TL07-26 through TL07-30
addressing every other VoiceOver label called out in feedback v1, but the quiz label was
not included. The spec says "각 항목은 unit/UI 테스트로 검증 가능해야 한다" and AC#16
explicitly requires this label. A pure-function helper `quizA11yLabel(question:) -> String`
(analogous to `progressBarA11yLabel`) makes this straightforward.

### P2 — "정답"/"오답" accessibility trait: Risk #8 left unresolved (AC#16 gap)

The spec says:
> 정답 선택 후 정답 옵션 트레잇 "정답" (빨강 오답 선택 후 그 옵션 트레잇 "오답").

Risk #8 acknowledges this but only says "정확한 API 사용법 확인 필요" — no concrete
implementation approach and no test. This is hand-waving for a named acceptance criterion.

SwiftUI does not support arbitrary custom `UIAccessibilityTraits`. The practical approach is
`.accessibilityValue("정답")` on the correct option and `.accessibilityValue("오답")` on the
incorrectly-selected option after a choice is made (and empty string while unselected). This
is fully testable as a pure-function derivation (same pattern as `choiceAppearance`).

## Required Changes

1. **Add TL07-31** in §5: `test_voiceOver_quizCard_accessibilityLabel` — pure helper
   `quizA11yLabel(question:)` → `"퀴즈, 水를 생(生)하는 오행은?"`. Add the corresponding
   helper to Step 6.

2. **Resolve Risk #8** with concrete approach in Step 6:
   - Use `.accessibilityValue("정답")` on the correct-option `ChoiceOptionView` when that
     option is highlighted, and `.accessibilityValue("오답")` on the incorrectly-selected
     option after a wrong tap; empty string otherwise.
   - Expose a pure helper `choiceA11yValue(index:selected:correct:) -> String` (returns "정답",
     "오답", or "") so it is unit-testable without UI.
   - Add **TL07-32**: `test_voiceOver_choiceAccessibilityValue` — verifies
     `choiceA11yValue(index:2, selected:2, correct:2) == "정답"`,
     `choiceA11yValue(index:0, selected:0, correct:2) == "오답"`, and
     `choiceA11yValue(index:1, selected:0, correct:2) == ""`.

## Resolved since previous iteration

- **P1 (v1)** — VoiceOver label unit tests TL07-26…TL07-30 added for NavBar title,
  NavBar trailing, progress bar, diagram placeholder, and quiz option symbol. ✅
- **P2 (v1)** — UITest push buttons split into three distinct IDs
  (`SajuNavPush_lessonLOH003`, `SajuNavPush_lessonNoNext`, `SajuNavPush_lessonUnknownId`),
  TU-LS18 updated to use `SajuNavPush_lessonUnknownId`. ✅
- **P3 (v1)** — TL07-23 clarified with runtime assertion
  `XCTAssertFalse(MockSajuLessonProvider() is any SajuLearningPathProviding)`. ✅
- **P1 (v1) TU-LS24** — Added to check `SajuLessonDiagramPlaceholder.label` contains
  "다이어그램 자리". ✅

## Still outstanding from prior iterations

_(All v1 items resolved above — nothing carried forward.)_
