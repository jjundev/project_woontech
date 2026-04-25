# Implement Feedback v1

## Checklist items not met

- **All UI test items (T12–T27, R1–R15 mapping)**: Cannot be evaluated.
  The unit test command in this iteration aborted before any test ran due
  to a runner-side argument plumbing failure (see `Build / Test failures`),
  and the `.harness/test-results/` mirror directory does not exist in this
  worktree, so no per-test diagnostic file is available.
- **All unit test items (T1–T11)**: Cannot be evaluated this iteration —
  same root cause as above. (Prior iteration's feedback v3 reported
  T1–T11 green at that time; that result is stale because the runner
  failed before re-execution here.)

## Build / Test failures

- `python3 tools/xcode_test_runner.py build` — completed with exit 0 and
  no stdout. Treated as success.
- `python3 tools/xcode_test_runner.py test --target WoontechTests --worktree-dir . -only-testing:WoontechTests/TodayDetailViewTests`
  — **FAILED** with exit 64. Quoting the actual stderr verbatim:

  ```
  2026-04-25 17:31:27.085 xcodebuild[74442:5518346] Writing error result bundle to /var/folders/cp/whkt9h5d49d1tmfm_0zqrxy80000gn/T/ResultBundle_2026-25-04_17-31-0027.xcresult
  xcodebuild: error: invalid option '--worktree-dir'
  ```

  The runner script (`tools/xcode_test_runner.py`) is forwarding the
  `--worktree-dir .` flag — supplied verbatim by the harness in this
  iteration's prompt — directly to `xcodebuild`, which has no such
  option. xcodebuild aborts before any test executes, so no xcresult
  bundle (other than the auto-generated error result bundle in
  `/var/folders/...`, which is outside the worktree path scope) is
  produced.

- UI test command (`python3 tools/xcode_test_runner.py test --target WoontechUITests --ui --worktree-dir . -only-testing:WoontechUITests/TodayDetailUITests`)
  — not executed in this iteration. With the unit-test runner already
  failing at flag-parsing time on the same `--worktree-dir` argument,
  the UI invocation will fail identically before any test executes;
  running it would produce no additional diagnostic value.

- `.harness/test-results/last-unit-summary.txt`,
  `.harness/test-results/last-unit-failures.txt`,
  `.harness/test-results/last-ui-summary.txt`,
  `.harness/test-results/last-ui-failures.txt` — none of these exist.
  The entire `.harness/` directory is absent from the worktree
  (`ls .harness/` returns "No such file or directory"). This is the
  mirror channel the reviewer policy requires for hypothesis-free root
  cause diagnosis, and it is empty.

## Required changes

DIAGNOSTIC_INFRASTRUCTURE_MISSING: .harness/test-results/last-unit-failures.txt

## Patch eligibility

Requires implementor rework.

The harness-supplied test commands include a `--worktree-dir .` flag that
the local `tools/xcode_test_runner.py` does not parse. Because the runner
forwards unknown args to `xcodebuild`, xcodebuild errors out before any
test runs and no `.harness/test-results/last-*-{summary,failures}.txt`
diagnostic files are produced. The reviewer cannot:
1. Verify whether the unit / UI tests in this iteration actually pass or
   fail (the v3 reviewer's claim that unit tests were green is stale —
   it was made before the current `--worktree-dir` plumbing change in
   the harness).
2. Read per-test failure messages required by the no-hypothesis-fix
   policy.

This is infrastructure breakage on the harness ↔ runner boundary, not a
code defect that a localized reviewer patch can repair within the
worktree path scope. Proper resolution requires either:
- The harness emitting the previously-working test command shape
  (without `--worktree-dir`), or
- The implementor extending `tools/xcode_test_runner.py` to consume the
  `--worktree-dir` argument (and probably emit the
  `.harness/test-results/last-*-{summary,failures}.txt` mirror files
  the reviewer policy depends on).

Either path is outside the scope of a localized reviewer patch.

## Patch applied

Not applied; requires implementor rework.

## Verification after patch

Not run after patch; no reviewer patch was applied.

## Remaining risk

- **Diagnostic mirror channel is dead this iteration.** No
  `.harness/test-results/` directory exists, so even if the runner had
  produced an xcresult bundle, the policy-mandated mirror files would
  still be missing. Until the runner is taught to write those files
  (and accept `--worktree-dir`), every reviewer iteration will hit the
  same wall.
- **pbxproj target membership** for all four new `.swift` files is
  correct (verified by Grep on `Woontech.xcodeproj/project.pbxproj`):
  - `PBXFileReference` entries at lines 209–212 for
    `TodayDetailProviding.swift`, `TodayDetailView.swift`,
    `TodayDetailViewTests.swift`, `TodayDetailUITests.swift`.
  - `PBXBuildFile … in Sources` declarations at lines 96–99 and
    Sources-phase entries at line 647 (WoontechTests),
    719–720 (Woontech main), 736 (WoontechUITests).
  - No silent BUILD-SUCCEEDED-but-not-compiled false positive.
- **Code-side state at HEAD** appears intact from a static-read
  perspective — `TodayDetailProviding.swift` exposes the spec'd
  protocol/models/mock with the wireframe defaults
  (庚午 / counts {木1,火3,土1,金3,水0} / weakElement=.water /
  편관 / [申·巳 +12 positive, 卯·酉 −18 negative]); `TodayDetailView.swift`
  composes `SajuOriginCard`, `WuxingDistributionRow`, `SipseongCard`,
  `HapchungCard`, `HapchungRowView`, `MottoCard`, `TabooCard`,
  `DisclaimerView` in the spec'd order with all promised
  `accessibilityIdentifier`s (including the v3-reviewer's recommended
  `.accessibilityElement(children: .ignore)` on `WuxingCell_*`). No
  static read flagged a new regression vs. the v3 snapshot. But this
  is *static* review only — runtime correctness cannot be verified
  this iteration.

## Resolved since previous iteration

(None visibly resolved — no test execution occurred this iteration to
verify v3's outstanding UI failures.)

## Still outstanding from prior iterations

Carried forward verbatim from `implement-feedback-version-3.md`:

- **C1 from v3 (root-cause investigation of UI failures by reading the
  xcresult bundle)**: Still outstanding. v3 reviewer hit a PreToolUse
  hook restriction blocking `xcrun xcresulttool` against `/tmp/...`
  bundles; this iteration's reviewer cannot even reach that step
  because the runner now aborts on `--worktree-dir`.
- **C2 from v3 (HapchungSection Group-wrap + WuxingCell
  `.accessibilityElement(children: .ignore)`)**: Already applied at
  `TodayDetailView.swift:162–164` (WuxingCell) and `:252–278`
  (HapchungSection Group + `.contain`). Verification pending UI test
  evidence.
- **C3 from v3 (verify `HapchungSection` identifier registers under
  `children: .contain`)**: Still outstanding — no runtime verification
  this iteration.
- **C4 from v3 (confirm header push pattern under
  `.toolbar(.hidden, for: .navigationBar)` parent)**: Still
  outstanding — verify-only item, implementation mirrors
  `InvestingAttitudeDetailView` line-for-line.
- **C5 from v3 (simulator/LLDB launch-noise mitigation)**: Still
  outstanding — environmental, not a code bug.
- **C2 from v1 (broader root-cause investigation beyond
  HapchungRowView)**: Still outstanding — supplanted by v2/v3 C1; same
  diagnostic step.
- **C3 from v1 (verify `HapchungSection` queryability)**: Still
  outstanding (same as v3 C3 above).
- **C4 from v1 (confirm `WuxingCell_*` label coalesces correctly)**:
  Code-side fix in place at `TodayDetailView.swift:162–164`; runtime
  verification still pending.
