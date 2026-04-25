# Implement Feedback v2

## Checklist items not met

The worktree state is effectively **unchanged from iteration 1** — the implementor
did not commit any new work on `feature/WF2-saju-input`. The branch still shows
only the bootstrap commit (`2c855c8 Bootstrap task workspace for WF2-saju-input`).
The same partial set of backing domain/shared types and common UI atoms exists as
untracked files on disk, and they are **still not registered in
`Woontech.xcodeproj/project.pbxproj`**, so they continue to silently drop out of
the build target. Virtually every checklist row remains `[ ]`.

### Requirements

- R-C1 .. R-C5 (공통 네비게이션): No `SajuInputFlowView.swift`. No progress bar
  hooked into routing, no back-button wiring, no CTA-label switching, no swipe
  suppression.
- R1 .. R3 (Step 1 성별): No `Step1GenderView.swift`.
  `Woontech/Features/SajuInput/Steps/` is still empty.
- R4 .. R7 (Step 2 이름): No `Step2NameView.swift`.
- R8 .. R14 (Step 3 생년월일): No `Step3BirthDateView.swift` (lunar/solar segment,
  leap-month checkbox, 3-column wheel, 1990/03/15 defaults all absent).
- R15 .. R19 (Step 4 태어난 시간): No `Step4BirthTimeView.swift`. No
  "시간을 모르겠어요" view, no wheel-disabling state.
- R20 .. R25 (Step 5 출생지): No `Step5BirthPlaceView.swift`. No search box,
  no default city list view, no 국외 경도 입력 field.
- R26 .. R31 (Step 6 진태양시): No `Step6SolarTimeView.swift`. No toggle, no
  calculated-result box, no bottom-sheet popup, no "사주 분석 시작" CTA wiring.
- R32 .. R37 (Step 7 로더): No `Step7LoaderView.swift`. No progress bar, no
  tip carousel, no 1.8s minimum-display guarantee wired to a view.
- R38 .. R45 (Step 8 결과): No `Step8ResultView.swift` or any of its subviews
  (`HeroTypeCardView`, `SajuMiniChartView`, `WuxingBalanceBarView`,
  `BulletListView`, `AccuracyBadgeView`, `ShareCardView`).
  `Woontech/Features/SajuInput/Result/` is still empty.
- R46 .. R50 (Step 8.5 회원가입): No `Step85SignUpView.swift`.
  `Woontech/Features/SajuInput/SignUp/` is still empty.
- R51 .. R58 (Step 10 친구 초대): No `Step10ReferralView.swift`.
  `Woontech/Features/SajuInput/Referral/` is still empty.
- R59 .. R67 (Non-functional):
  - No routing update: `Woontech/App/RootView.swift` still enumerates only
    `.splash / .onboarding / .sajuInput`, still routes `.sajuInput` to
    `SajuInputPlaceholderView`, and does not have a `.home` route.
  - No `SajuInputStore` injection in `Woontech/App/WoontechApp.swift`. The
    launch args `-resetSajuInput`, `-sajuStartStep <N>`, `-preloadedProfile <JSON>`
    are not handled (contradicts NFC-6 and S21).
  - `Woontech/Resources/ko.lproj/Localizable.strings` still contains only the
    splash/onboarding/placeholder keys. None of the spec's `saju.*` keys
    (titles/hints/CTA labels for Steps 1–10, disclaimer, accuracy badge, etc.)
    are present (violates R65 / NFC-7).
  - Disclaimer sentence "본 앱은 학습·참고용이며 투자 권유가 아닙니다" is not
    rendered in any WF2 result view (violates R66 / NFC-8 / AC-28).
  - `Woontech/Shared/ShareCardRenderer.swift` exists (18 LOC) but has no
    verifiable 1080×1920 `UIImage` output, and the file is not compiled into the
    app target (pbxproj has zero references), so R67 cannot be satisfied.
  - VoiceOver labels / 44×44pt hit targets (R62, R63) cannot hold because the
    views they would live on do not exist.

### Implementation steps

- S1: Partial (unchanged from v1). Domain/state files exist as untracked files
  in `Woontech/Shared/` (`SajuInputModel.swift`, `SajuFlowModel.swift`,
  `SajuInputStore.swift`, `CityCatalog.swift`, `SajuResultModel.swift`,
  `SajuAnalysisEngine.swift`, `SolarTimeCalculator.swift`, `ShareCardRenderer.swift`).
  Still not added to the Xcode target (see S23).
- S2: Partial (unchanged). `SolarTimeCalculator.swift` exists at 43 LOC. No tests,
  not part of a built target.
- S3: Partial (unchanged). `SajuAnalysisEngine.swift` exists at 144 LOC. No
  injected clock/minimum-duration plumbing verified; no tests.
- S4: Partial (unchanged). Only `SajuCheckbox / SajuSegmented / SajuStepScaffold /
  SajuToggleRow / StepProgressBarView / WheelPicker` exist under
  `Woontech/Features/SajuInput/Shared/`. None are in the Xcode target.
- S5 .. S17: **Not started.** All corresponding view files are still absent
  (`Steps/`, `Loader/`, `Result/`, `SignUp/`, `Referral/` are empty directories).
- S18: **Not done.** `RootView.swift` still routes `.sajuInput` to
  `SajuInputPlaceholderView`; no `.home` case; `SajuInputRoot` accessibility
  identifier still lives on the placeholder (creates AC-1 / T62 regression risk
  as soon as the real flow lands).
- S19: **Not done.** Zero `saju.*` keys added to `ko.lproj/Localizable.strings`.
- S20: **Not done** (cannot be — no views exist).
- S21: **Not done.** `WoontechApp.swift` has no new launch args and no
  `SajuInputStore` wiring.
- S22: **Not done.** Edge cases (10-char name truncation, `hourKnown=false` dash
  rendering, stable-hash excluding name) are not realized in any view.
- S23: **Not done.** `Woontech.xcodeproj/project.pbxproj` still has **zero**
  references to `SajuInputFlowView`, `SajuInputModel`, `SajuFlowModel`,
  `SajuInputStore`, `SolarTimeCalculator`, `CityCatalog`, `SajuAnalysisEngine`,
  `SajuResultModel`, or `ShareCardRenderer` (verified by grep:
  `grep -c "…" Woontech.xcodeproj/project.pbxproj` → `0`). The new Swift files
  continue to be silently excluded from compilation — that is still the only
  reason the build currently succeeds.

### Tests

- T1 .. T33 (unit): **None written.** `WoontechTests/` still contains only
  `OnboardingFlowStateTests.swift` and `OnboardingStoreTests.swift` (unchanged
  since iteration 1).
- T34 .. T62 (ui): **None written.** `WoontechUITests/` still contains only
  `OnboardingUITests.swift` (unchanged since iteration 1).

## Build / Test failures

- **Build (as given)**: `xcodebuild -scheme Woontech -destination
  'platform=iOS Simulator,name=iPhone 15' build` fails with:
  > xcodebuild: error: Unable to find a device matching the provided destination
  > specifier: { platform:iOS Simulator, OS:latest, name:iPhone 15 }
  Same as iteration 1 — this machine's simulator pool only contains iPhone 16e /
  17 / 17 Pro / 17 Pro Max / 17e / Air. Re-running with `name=iPhone 17` as a
  sanity check produced `** BUILD SUCCEEDED **`, but only because none of the
  new `Woontech/Shared/*.swift` or `Woontech/Features/SajuInput/**` source
  files are registered in `project.pbxproj` and are therefore excluded from
  compilation. A real PASS requires those files registered **and** the build
  succeeding against a supported destination. Neither condition holds.
- **Unit tests**: command is `echo 'SKIP: no changed unit test files in this
  worktree'` — harness-skipped. Recorded; no new unit tests exist for T1–T33.
- **UI tests**: command is `echo 'SKIP: no changed ui test files in this
  worktree'` — harness-skipped. Recorded; no new UI tests exist for T34–T62.

## Required changes

Same scope as iteration 1 — none of these have been addressed:

1. **Build the remaining feature surface.** Create every missing view listed in
   the plan's §2 "Affected Files — New — UI (Features/SajuInput)" block:
   - `SajuInputFlowView.swift` (root container with progress bar, back button, CTA).
   - `Steps/Step1GenderView.swift` through `Steps/Step6SolarTimeView.swift`.
   - `Steps/Step7LoaderView.swift` (minimum-1.8s gate, tip carousel, progress).
   - `Result/Step8ResultView.swift` + `HeroTypeCardView`, `SajuMiniChartView`,
     `WuxingBalanceBarView`, `BulletListView`, `AccuracyBadgeView`, `ShareCardView`.
   - `SignUp/Step85SignUpView.swift`.
   - `Referral/Step10ReferralView.swift`.
   - `Features/Home/HomePlaceholderView.swift` (WF3 landing for "나중에 하기").
2. **Wire routing.** Update `RootView.swift` to add `.home` and route `.sajuInput`
   to `SajuInputFlowView`. Remove (or repurpose) `SajuInputPlaceholderView` and
   move its `SajuInputRoot` accessibility identifier to the Step 1 container so
   `OnboardingUITests` (and new T62) does not regress.
3. **Inject the store.** Update `WoontechApp.swift` to own a `SajuInputStore`
   `@StateObject`, expose it via `environmentObject`, and honor
   `-resetSajuInput`, `-sajuStartStep <N>`, `-preloadedProfile <JSON>` launch args.
4. **Localization.** Add all `saju.*` keys used by Steps 1–10 (titles, hints,
   CTA labels, checkbox/toggle labels, accuracy-badge strings, disclaimer
   phrase, referral copy) to `Woontech/Resources/ko.lproj/Localizable.strings`.
   The disclaimer must contain "본 앱은 학습·참고용이며 투자 권유가 아닙니다"
   verbatim.
5. **Register all new files in the Xcode project.** Add every new `.swift` file
   (both the `Woontech/Shared/*.swift` domain files and everything under
   `Woontech/Features/SajuInput/**`) to `Woontech.xcodeproj/project.pbxproj`
   with the correct target membership, and add the new test files to the
   `WoontechTests` / `WoontechUITests` targets. Current pbxproj still has zero
   references to the new files, so they silently drop out of the build.
6. **Write the unit tests (T1–T33).** Create the test files listed in plan §5
   (`SajuInputModelTests.swift`, `SajuFlowModelTests.swift`,
   `SolarTimeCalculatorTests.swift`, `SajuAnalysisEngineTests.swift`,
   `CityCatalogTests.swift`, `SajuInputStorePersistenceTests.swift`,
   `SajuResultAccuracyTests.swift`) and implement each numbered test case.
7. **Write the UI tests (T34–T62).** Create the UI test files listed in plan §6
   (`SajuInputUITests.swift`, `SajuResultUITests.swift`, `SajuSignUpUITests.swift`,
   `SajuReferralUITests.swift`, `SajuAccessibilityUITests.swift`) and implement
   each numbered case. Include the onboarding→SajuInputRoot smoke test (T62).
8. **Accessibility.** Once views exist, add VoiceOver labels/traits and ensure
   back-button, toggle, checkbox, and "수정" button hit targets are ≥44×44pt.
9. **Persistence.** Call `store.persist()` once on Step 8 render and add the
   corresponding unit test (T28/T29) validating the `userProfile` JSON round-trip.
10. **Commit the work.** Iteration 2 did not produce any commits on
    `feature/WF2-saju-input`. Once the work above is done, commit it on the
    feature branch so the next reviewer can evaluate it.

## Patch eligibility

Requires implementor rework.

The missing work still spans ~18 new SwiftUI view files, RootView routing
changes, an app-level store injection with new launch-arg handling, full
localization-table authoring, ~33 unit tests, ~29 UI tests, and a non-trivial
Xcode project file mutation. This is not a small, localized fix — it is the
majority of the feature implementation. Per the reviewer-patch rules (small,
localized, no architecture change, no API-surface change), this must go back
to the implementor.

## Patch applied

Not applied; requires implementor rework.

## Verification after patch

Not run after patch; no reviewer patch was applied.

## Remaining risk

- No work has landed between iterations 1 and 2. If the next iteration also
  produces no commits, the pipeline is stalled and someone should investigate
  why the implementor is not progressing the task (missing input, tool failure,
  or an orchestration issue).
- Once the implementor adds the files, `project.pbxproj` edits must be careful:
  fileRefs, group membership, and `PBXSourcesBuildPhase` /
  `PBXResourcesBuildPhase` entries must all be present or the "build succeeds
  but new code isn't compiled" trap (currently happening) will persist
  invisibly.
- The supplied build destination (`name=iPhone 15`) is still not available on
  this machine. Either the harness needs to provide an available model (e.g.
  `iPhone 17`) or the command should be relaxed to
  `generic/platform=iOS Simulator`; otherwise every review iteration will fail
  on the build command even when the code is correct.
- The `SajuInputRoot` accessibility identifier still lives on
  `SajuInputPlaceholderView`. Whoever moves it must do so atomically with the
  placeholder removal and Step 1 container introduction to avoid breaking
  `OnboardingUITests` (risk callout §9 in the plan).

## Resolved since previous iteration

None. Iteration 2 produced no new commits on `feature/WF2-saju-input` and no
new code on disk; the working tree is byte-identical to iteration 1 aside from
the harness-managed `ongoing/WF2-saju-input/state.json`.

## Still outstanding from prior iterations

All items from `implement-feedback-version-1.md` carry forward unchanged:

- Build every missing view in `Woontech/Features/SajuInput/**` per plan §2
  (`SajuInputFlowView`, `Steps/Step1GenderView` … `Steps/Step7LoaderView`,
  `Result/Step8ResultView` and its subviews, `SignUp/Step85SignUpView`,
  `Referral/Step10ReferralView`, `Features/Home/HomePlaceholderView`).
- Update `Woontech/App/RootView.swift` to add `.home` and route `.sajuInput`
  to `SajuInputFlowView`; remove/repurpose `SajuInputPlaceholderView` and
  move `SajuInputRoot` accessibility identifier to the Step 1 container
  atomically (OnboardingUITests regression protection, T62 smoke test).
- Update `Woontech/App/WoontechApp.swift` to `@StateObject` and inject a
  `SajuInputStore` via `environmentObject`, and honor `-resetSajuInput`,
  `-sajuStartStep <N>`, `-preloadedProfile <JSON>` launch args.
- Populate all `saju.*` keys (Steps 1–10 titles/hints/CTA labels, checkbox/
  toggle labels, accuracy-badge strings, referral copy) in
  `Woontech/Resources/ko.lproj/Localizable.strings`, including the verbatim
  disclaimer "본 앱은 학습·참고용이며 투자 권유가 아닙니다".
- Register every new `.swift` file (both `Woontech/Shared/*.swift` domain files
  and everything under `Woontech/Features/SajuInput/**`) in
  `Woontech.xcodeproj/project.pbxproj` with correct target membership, and
  register new test files in the `WoontechTests` / `WoontechUITests` targets.
- Write the unit tests T1–T33 in the files named by plan §5.
- Write the UI tests T34–T62 in the files named by plan §6, including the
  `test_onboardingComplete_landsOnSajuInputRoot` smoke test.
- Add VoiceOver labels/traits and ≥44×44pt hit targets on back button, toggle,
  checkbox, and "수정" button (NFC-4, NFC-5, AC-26, AC-27).
- Call `store.persist()` on Step 8 render and validate round-trip in
  unit tests T28/T29 (NFC-6).
- Make the harness build command resolvable on this machine (either update the
  destination to an available simulator or use `generic/platform=iOS Simulator`)
  so future reviews can actually execute the provided build command.
