# Plan Feedback v1

## Problems

### P1 — `TenGodsDisplayedItems_{name}` identifier missing from Step 5 (blocks T41/T42)

R5 in the Risks section recommends adding `.accessibilityIdentifier("TenGodsDisplayedItems_{name}")` to the
subsidiary-line right-side Text in `TenGodsGroupRow`. However, this identifier is **not listed in Step 5** as
a required action. The implementor may skip it when writing the row component, causing UI tests T41
(`testDistribution_비겁_displayedItems`) and T42 (`testDistribution_식상_displayedItemsIsEmpty`) to fail at
runtime with "no element" errors. These tests cover AC#8, which is a hard requirement.

### P2 — AC#18 VoiceOver ordering incompletely tested (T53–T54 cover only 2 of 5 required orderings)

The spec requires full focus order: NavBar → 요약 → 5그룹(비겁→인성) → 핵심 Top3 → 부재경고 → 학습유도 →
Disclaimer. Section 6.8 tests only:
- T53: 요약 < 5그룹 첫 행
- T54: 5그룹 마지막 행 < 핵심 Top3 첫 카드

Missing orderings: **핵심 Top3 마지막 < 부재경고**, **부재경고 < 학습유도**, **학습유도 < Disclaimer**.
The latter three are the orderings most at risk of being broken by conditional-render logic (`if let`).

### P3 — Step 10 leaves `onNavigate` approach unresolved

Step 10 describes both Option A (extend `sajuRouteDestination` signature with `onNavigate` closure) and Option B
(`@EnvironmentObject` / `@Published` navigationPath) and says "권장: 옵션 A" but does not commit. The step still
includes conditional language ("또는 ... 방식 중 하나를 선택"). The implementor must infer the choice.
Option A is the clearly correct pick (minimum change surface, same pattern as other route views), and the step
should state this without ambiguity.

### P4 — AC#9/AC#10 precondition-failure tests use `XCTSkip` and do not verify failure

The spec says precondition failures "테스트로 검증". T23, T24, T25 are marked `XCTSkip (process 종료)` —
they skip rather than verify. While Swift `precondition()` terminates the process and cannot be caught by
`XCTAssertThrowsError`, there are two viable approaches:

- **Approach A (minimal)**: Keep `precondition()` in production code; add a private
  `@testable`-accessible `throws`-based validation companion (`validateGroups(_:) throws`,
  `validateTopThree(_:) throws`) that is called before the precondition. Unit tests call the throwing
  version with invalid inputs and use `XCTAssertThrowsError`. This satisfies "테스트로 검증" without
  process isolation.
- **Approach B (note-only)**: If the team accepts that precondition failures are crash-level invariants
  and cannot be unit-tested, document this explicitly in the test file with a `// Precondition failures
  terminate the process; tested via code review + positive-path coverage (T22)` comment, and do NOT
  register T23/T24/T25 as formal test cases (remove them so CI does not count them as "passing" when
  they are just skips).

Whichever approach is chosen must be stated in the plan. Approach A is recommended.

## Required changes

1. **[P1]** In Step 5, add an explicit bullet to `TenGodsGroupRow`: the subsidiary-line right-side
   Text receives `.accessibilityIdentifier("TenGodsDisplayedItems_\(group.name)")`. Remove the duplicate
   mention from R5 (or demote R5 to a resolved note).

2. **[P2]** In Section 6.8, add tests T57–T59 for the three missing VoiceOver ordering pairs:
   - T57: 핵심 Top3 마지막 카드 maxY < 부재경고 카드 minY (conditional: run only when `absentWarning` present)
   - T58: 부재경고 maxY < 학습유도 minY (conditional: run only when both present)
   - T59: 학습유도 maxY < Disclaimer minY (conditional: run only when `learnEntry` present)

3. **[P3]** In Step 10, remove the "A or B" language. State that Option A is used: add `onNavigate`
   parameter to the destination-builder call site in `SajuRouteDestinations.swift`, and `SajuTabView`
   passes `{ route in navigationPath.append(route) }`.

4. **[P4]** Choose Approach A: define `validateGroups(_:) throws` and `validateTopThree(_:) throws` as
   `internal` helpers (marked `@testable`) that mirror the precondition logic. Unit tests T23/T24/T25
   call these helpers with invalid inputs and assert throws. Production `init` or `body` still calls
   `precondition()` after the throwing helpers succeed, as a belt-and-suspenders guard.

## Resolved since previous iteration

- (None — this is iteration 1.)

## Still outstanding from prior iterations

- (None — this is iteration 1.)
