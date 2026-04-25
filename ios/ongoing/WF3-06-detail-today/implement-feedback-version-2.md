# Implement Feedback v2

## Checklist items not met

- **R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R14, R15 / T12–T27 (all 17 UI tests)**:
  The UI test target still fails as a whole. After running
  `python3 tools/xcode_test_runner.py test --target WoontechUITests --ui -only-testing:WoontechUITests/TodayDetailUITests`
  twice in this iteration, both attempts terminate with
  `** TEST FAILED **` and exit code 65 after 200+ seconds of repeated
  `DebuggerLLDB.DebuggerVersionStore.StoreError` retries. The runner's automatic
  environment-failure repair (DebuggerLLDB / "no debugger version") is
  triggering across every retry, but per-test pass/fail messages are not
  visible in the runner stdout (the harness truncates the middle of the log
  and the xcresult bundle lives at `/tmp/woontech-derived-data/...`, which is
  blocked by the worktree absolute-path hook for the reviewer).

  The unit suite (`TodayDetailViewTests`, T1–T11) and the build are both
  green — confirmed in this iteration — so the failures are again specific to
  the UI / accessibility / navigation layer of `TodayDetailView`, exactly as
  in v1.

- **R13 (T7 / U7)**: Passing as-is via unit tests.

## Build / Test failures

- `python3 tools/xcode_test_runner.py build` — succeeded (no error output).
- `python3 tools/xcode_test_runner.py test --target WoontechTests -only-testing:WoontechTests/TodayDetailViewTests` — succeeded
  ("Testing started completed", clean termination, no failures).
- `python3 tools/xcode_test_runner.py test --target WoontechUITests --ui -only-testing:WoontechUITests/TodayDetailUITests` — **FAILED**
  - Exit code 65, `** TEST FAILED **`.
  - Two consecutive attempts at ~215 sec each; both ended with the same
    failure mode after the runner's environment-repair retried.
  - Per-test failure messages are not retrievable from inside the worktree;
    they live in `/tmp/woontech-derived-data/ui/Logs/Test/Test-Woontech-*.xcresult`,
    which the reviewer's bash hook denies (paths must be inside the worktree).
  - Mid-log slice contains a Swift diagnostic underline pointing at
    `Step85SignUpView.swift:14` (`Button(action: { store.back() })`). That
    file is unrelated to this task; whether this is a pre-existing
    deprecation warning or a contributing factor cannot be determined from
    the truncated buffer alone. Build succeeds, so it is at most a warning.

## Required changes

### C1 — Reproduce the UI suite locally and read the xcresult bundle

Iteration 1 already identified `HapchungRowView`'s
`.accessibilityElement(children: .ignore)` as a definite cause for at least
T21 / T22 / T26 (children `HapchungRow_*_Score`,
`HapchungRow_*_NegativeStyle` got collapsed into the parent). That patch
was applied — the current file uses `.accessibilityElement(children: .contain)`
(see `TodayDetailView.swift:333`) — so that specific sub-failure should now
clear. However, the suite still fails wholesale, so other root causes that v1
flagged as C2 ("almost certainly not limited to C1") remain unresolved.

Required:

- Run `python3 tools/xcode_test_runner.py test --target WoontechUITests --ui -only-testing:WoontechUITests/TodayDetailUITests`
  locally (outside the harness), then open
  `/tmp/woontech-derived-data/ui/Logs/Test/Test-Woontech-*.xcresult` in Xcode
  or via `xcrun xcresulttool get --legacy --path …` and capture the
  per-test failure message + screenshot for each currently-red test. Do not
  rely on iteration-2 reviewer output — it is truncated and missing the
  per-test bodies.
- Triage each failure into one of the following expected categories and fix
  at the source:
  1. Navigation push not actually landing on `TodayDetailView` (check if
     `HomeNavPushToday`/`HomeInsightsCard_1` taps surface
     `TodayDetailTitle` after the parent's
     `.toolbar(.hidden, for: .navigationBar)` interaction with the custom
     header).
  2. Accessibility identifier not registering on a container view (e.g.
     `WuxingCell_*` is currently set on a `VStack` whose three children are
     separate static texts; the `.accessibilityLabel` should coalesce them
     but, if the platform exposes them as `.staticText` rather than
     `.other`, T15 will fail. Verify with `po app.debugDescription` on the
     paused test).
  3. SwiftUI runtime trap inside `SajuMiniChartView` when
     `strongElements`/`supplementElements`/`investmentTags` are computed
     from a brand-new caller (the existing call sites use real
     analysis-pipeline data; the WF3-06 caller passes
     `strongElements = counts ≥ 3` and a literal `"원칙형 · 관리형"` tag —
     valid but new shape).
  4. `HapchungSection` identifier not registering on the `HapchungCard`
     wrapper when wrapped only by `if !isEmpty {…}` inside a `VStack`.
     T20 (`testHapchungCardHiddenWhenEmpty`) needs the *negative* of the
     identifier — if the identifier never registers in the positive case
     either, T20 is a false positive but T19 (`testHapchungRowsRenderInOrder`)
     still has to read the rows under the section.

### C2 — Confirm `WuxingCell_*` exposes its label as a single accessibility element

`WuxingDistributionRow` (lines 143–162) attaches
`.accessibilityIdentifier("WuxingCell_\(element.rawValue)")` and
`.accessibilityLabel("\(element.label) \(element.hanja) \(count)")` to the
inner `VStack`. There is no `.accessibilityElement(children: ...)` modifier,
so SwiftUI may either (a) coalesce the three child `Text` views via the
explicit `accessibilityLabel` (good — T15 passes), or (b) keep the children
addressable as `.staticText` and lose the parent identifier. The C1 fix on
`HapchungRowView` chose explicit `.contain` precisely to avoid this
ambiguity. Apply the same pattern here:

```swift
.accessibilityElement(children: .ignore)
.accessibilityIdentifier("WuxingCell_\(element.rawValue)")
.accessibilityLabel("\(element.label) \(element.hanja) \(count)")
```

(Children are pure decorative `Text` in this case — `.ignore` is fine and
avoids any chance of T15 querying `.staticText` paths instead of
`.otherElements`.)

### C3 — Confirm `HapchungSection` is queryable

`HapchungCard` (lines 239–268) attaches
`.accessibilityIdentifier("HapchungSection")` to the struct after
`.accessibilityElement(children: .contain)`. That is the correct pattern,
but please verify `app.otherElements["HapchungSection"]` resolves in
Inspector / `po app.debugDescription` after C1's
`children: .contain` fix on the row, since SwiftUI's behavior when nested
`children: .contain` containers stack can produce surprises.

### C4 — Confirm header push pattern works under
`.toolbar(.hidden, for: .navigationBar)` parent

`InvestingAttitudeDetailView` is the precedent and its UI tests pass — the
`TodayDetailView` header structure mirrors it line-for-line — so this is
unlikely to be the cause. Mark this as the *last* thing to investigate, but
keep it on the list so the implementor confirms with the xcresult that
push + back actually work on the simulator.

### C5 — Address the simulator/LLDB launch noise (likely environmental)

Both attempts log
`IDELaunchParametersSnapshot: The operation couldn't be completed.
(DebuggerLLDB.DebuggerVersionStore.StoreError error 0.)` repeatedly for
~16 retries before declaring the run complete. The runner has built-in
environment repair that re-runs once; the second attempt also fails. This
is most likely a stale simulator state or a missing LLDB cache rather than
a code bug, but it slows iteration to ~3.5 minutes per UI run. Recommended
mitigation by the implementor:

- `xcrun simctl shutdown all && xcrun simctl erase all` before the next
  local run, or
- Delete `/tmp/woontech-derived-data` completely and rebuild from scratch.

This is *not* the cause of `** TEST FAILED **` (it would manifest as exit
code 70 or a Bundle-load error, not as test failures), but it makes
diagnosing the real failures slow.

## Patch eligibility

Requires implementor rework.

C2 alone is patch-eligible — adding an explicit
`.accessibilityElement(children: .ignore)` on `WuxingDistributionRow`'s
inner `VStack` is one short, localized edit. But applying *only* C2 in
isolation would, at best, fix one test (T15) while leaving the rest of the
suite red, which exactly mirrors v1's situation: the reviewer is shipping
an incremental dent without per-test failure visibility, the next
iteration still has to do the real diagnosis.

Per the reviewer-patch policy, the *meaningful* fix requires reading the
xcresult bundle to triage all 16 still-red tests, which is outside the
reviewer worktree path scope (the bundle lives at
`/tmp/woontech-derived-data/...` and the `Bash` hook denies absolute paths
outside the worktree). That is implementor work, not reviewer work.

## Patch applied

Not applied; requires implementor rework.

## Verification after patch

Not run after patch; no reviewer patch was applied.

## Remaining risk

- The actual per-test failure messages remain unread by the reviewer in
  iterations 1 and 2. Until the implementor surfaces them, the fix list
  above (C2, C3, C4) is hypothesis-only and may miss the dominant cause
  (e.g. a SwiftUI runtime crash on `TodayDetailView` push that takes the
  whole screen down before any identifier matters).
- pbxproj target membership for all four new `.swift` files
  (`TodayDetailProviding.swift`, `TodayDetailView.swift`,
  `TodayDetailViewTests.swift`, `TodayDetailUITests.swift`) is correct — both
  `PBXFileReference` (lines 209–212) and `PBXBuildFile … in Sources`
  (lines 96–99 / 647 / 719–720 / 736) entries exist for every file. No
  silent BUILD-SUCCEEDED-but-not-compiled false positive.
- `WoontechApp.swift` correctly parses `-mockTodayHapchungEmpty` and
  `-mockTodayMottoTabooOn` and constructs the right `MockTodayDetailProvider`
  permutations (lines 81–132). T20 / T24 should pass once the broader
  navigation/accessibility issue is fixed.

## Resolved since previous iteration

- **C1 (HapchungRowView accessibility):** Fixed.
  `TodayDetailView.swift:333` now uses
  `.accessibilityElement(children: .contain)` instead of `children: .ignore`,
  and the explanatory comment on lines 331–332 documents the choice. This
  unblocks at minimum the queries against
  `HapchungRow_<n>_Score` (T22, T26) and
  `HapchungRow_<n>_NegativeStyle` (T21). Whether those tests now actually
  pass depends on the broader push/render path, which has not been
  verified end-to-end.

## Still outstanding from prior iterations

- **C2 from v1 (root-cause investigation of the remaining UI failures):**
  Still outstanding. v1 explicitly said this requires running the suite
  locally and reading per-test failure messages from the xcresult bundle,
  and that has not happened. The current iteration's commit (which only
  patches C1) does not include any evidence of having opened the xcresult
  or having identified individual root causes.
- **C3 from v1 (verify `HapchungSection` identifier registers):** Still
  outstanding — implementation is unchanged on this point and no
  verification is documented.
- **C4 from v1 (confirm `WuxingCell_*` label format):** Still outstanding —
  see C2 above; without runtime verification the `.accessibilityLabel`
  coalescing is unconfirmed, and the missing
  `.accessibilityElement(children: .ignore)` is a real concern (see this
  iteration's C2).
