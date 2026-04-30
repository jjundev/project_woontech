# Plan Feedback v1

## Problems

### P1 — AC#16 VoiceOver coverage insufficient
The spec states "각 항목은 unit/UI 테스트로 검증 가능해야 한다" for all acceptance criteria.
AC#16 specifies a full VoiceOver focus order AND exact accessibility label formats for every
element (NavBar title = "{number}강, {title}", trailing = "현재 {currentIndex}강, 총
{totalCount}강", progress bar = "진행률 {percent}%", diagram = "다이어그램 자리, {label}",
quiz option = "{symbol}", CTA, etc.).  
The plan provides only **TU-LS23** (progress bar label). All other VoiceOver labels have no
automated coverage. Risk #6 acknowledges focus-order traversal is hard to automate, but
individual label-string tests are straightforward as pure-function unit tests (similar to how
TL07-24/TL07-25 test navbar string formats). These gaps mean AC#16 is untested.

### P2 — `SajuNavPush_lessonNoNext` serves two incompatible purposes
Step 9 defines one button `SajuNavPush_lessonNoNext` for both the "known lesson with
`nextLessonId == nil`" scenario and the "unknown id → fallback 준비중" scenario. However:
- TU-LS16/17 already test the no-next case via `-sajuLessonNoNextId` launch arg (separate path).
- TU-LS18 taps `SajuNavPush_lessonNoNext` and expects a "준비중" NavBar title — which only
  appears for unknown-id fallback, **not** for a valid no-next lesson.
These are different lessons with different titles. One button cannot produce both. A second
button `SajuNavPush_lessonUnknownId` (pushes e.g. `"__unknown__"`) is needed for TU-LS18.

### P3 — TL07-23 AC#15 compile-time check underspecified
TL07-23 says "타입 체크 어서션" but provides no concrete assertion. A unit test method
cannot cause a compile error at runtime. The test must use a runtime protocol conformance
check — e.g., `XCTAssertFalse(MockSajuLessonProvider() is any SajuLearningPathProviding)` —
or, if the goal is a negative-compilation guard, provide a `// WF4-07 guard: the line below
must NOT compile` comment with the failing code commented out. Either is acceptable; the plan
needs to specify which.

## Required Changes

1. **Add VoiceOver label unit tests (TL07-26…TL07-30)** in §5:
   - TL07-26: NavBar title accessibility label `"{number}강, {title}"` string
   - TL07-27: NavBar trailing accessibility label `"현재 {currentIndex}강, 총 {totalCount}강"` string
   - TL07-28: `progressBarAccessibilityLabel(current:total:)` pure helper → `"진행률 43%"` for 3/7
   - TL07-29: Diagram placeholder accessibility label `"다이어그램 자리, {diagramPlaceholderLabel}"`
   - TL07-30: Quiz option symbol used as accessibility label (single symbol string test)

2. **Add TU-LS24** in §6: XCUITest query confirms `SajuLessonProgressBar.label` contains
   "진행률" (already TU-LS23 does this — but extend to also check `SajuLessonDiagramPlaceholder`
   label contains "다이어그램 자리"). Alternatively merge into TU-LS23. Focus-order traversal
   remains a manual/VoiceOver test per Risk #6 — document it clearly as such.

3. **Split the UITest push button** in Step 9:
   - `SajuNavPush_lessonLOH003` — unchanged (known lesson, `nextLessonId = "L-OH-004"`)
   - `SajuNavPush_lessonNoNext` — pushes a **known** lesson whose `nextLessonId = nil`
     (e.g. `id: "L-OH-LAST"` backed by MockProvider returning a valid last lesson)
   - `SajuNavPush_lessonUnknownId` — pushes `id: "__unknown__"` → triggers fallback
   Update TU-LS18 to use `SajuNavPush_lessonUnknownId`.

4. **Clarify TL07-23** to specify the runtime assertion:
   `XCTAssertFalse(MockSajuLessonProvider() is any SajuLearningPathProviding)` (or equivalent).

## Resolved since previous iteration
_(Iteration 1 — no prior feedback)_

## Still outstanding from prior iterations
_(Iteration 1 — nothing carried forward)_
