# Implement Feedback v1

## Checklist items not met

The implementation is ~5% complete. Only a partial set of backing models and a few
common UI atoms exist (and they are not registered in the Xcode project, so they
never compile into the target). Virtually every checklist row is still `[ ]`.

### Requirements

- R-C1 .. R-C5 (공통 네비게이션): No `SajuInputFlowView` container, no progress bar
  hooked into routing, no back button wiring, no CTA-label switching, no swipe
  suppression. `Woontech/Features/SajuInput/SajuInputFlowView.swift` does not exist.
- R1 .. R3 (Step 1 성별): No `Step1GenderView.swift`. `Woontech/Features/SajuInput/Steps/`
  is an empty directory.
- R4 .. R7 (Step 2 이름): No `Step2NameView.swift`.
- R8 .. R14 (Step 3 생년월일): No `Step3BirthDateView.swift`. No lunar/solar segment,
  no leap-month checkbox, no 3-column wheel picker implementation, no 1990/03/15 default
  wiring in a view.
- R15 .. R19 (Step 4 태어난 시간): No `Step4BirthTimeView.swift`. No "시간을 모르겠어요"
  checkbox/view, no wheel-disabling state.
- R20 .. R25 (Step 5 출생지): No `Step5BirthPlaceView.swift`. No search box, no
  default city list view, no 국외 경도 입력 field.
- R26 .. R31 (Step 6 진태양시): No `Step6SolarTimeView.swift`. No toggle, no
  calculated-result box, no bottom-sheet popup, no "사주 분석 시작" CTA wiring.
- R32 .. R37 (Step 7 로더): No `Step7LoaderView.swift`. No progress bar, no tip
  carousel, no 1.8s minimum display guarantee wired to a view.
- R38 .. R45 (Step 8 결과): No `Step8ResultView.swift` and none of its subviews
  (`HeroTypeCardView`, `SajuMiniChartView`, `WuxingBalanceBarView`, `BulletListView`,
  `AccuracyBadgeView`, `ShareCardView`). `Woontech/Features/SajuInput/Result/` is empty.
- R46 .. R50 (Step 8.5 회원가입): No `Step85SignUpView.swift`.
  `Woontech/Features/SajuInput/SignUp/` is empty.
- R51 .. R58 (Step 10 친구 초대): No `Step10ReferralView.swift`.
  `Woontech/Features/SajuInput/Referral/` is empty.
- R59 .. R67 (Non-functional):
  - No routing update: `RootView.swift` still has only `.splash / .onboarding / .sajuInput`
    and `.sajuInput` still renders the old `SajuInputPlaceholderView`. `.home` route
    absent.
  - No `SajuInputStore` injection in `WoontechApp.swift`, no `-resetSajuInput`,
    `-sajuStartStep`, `-preloadedProfile` launch args (contradicts NFC-6 and S21).
  - `Localizable.strings` still contains only splash/onboarding/placeholder keys.
    None of the spec's `saju.*` keys (title/hint/CTA labels for Steps 1–10, disclaimer,
    accuracy badge, etc.) are present (violates R65 / NFC-7).
  - Disclaimer sentence "본 앱은 학습·참고용이며 투자 권유가 아닙니다" is not rendered
    anywhere in a WF2 result view (violates R66 / NFC-8 / AC-28).
  - `ShareCardRenderer.swift` exists (18 lines) but has no `UIImage` output pinned to
    1080×1920 yet verified; it is also not compiled into the app target (see pbxproj
    issue below), so R67 is not verifiable.
  - VoiceOver labels / 44×44pt hit targets (R62, R63) cannot be satisfied because the
    corresponding views do not exist.

### Implementation steps

- S1: Partial. Domain/state files exist in `Woontech/Shared/` (`SajuInputModel.swift`,
  `SajuFlowModel.swift`, `SajuInputStore.swift`, `CityCatalog.swift`, `SajuResultModel.swift`,
  `SajuAnalysisEngine.swift`, `SolarTimeCalculator.swift`, `ShareCardRenderer.swift`).
  **Not added to the Xcode target** — see S23.
- S2: Partial (`SolarTimeCalculator.swift` exists at 43 LOC). Not exercised by any test,
  not part of a built target.
- S3: Partial (`SajuAnalysisEngine.swift` exists at 144 LOC). No injected clock / minimum
  duration plumbing verified; no tests.
- S4: Partial. Only SajuCheckbox / SajuSegmented / SajuStepScaffold / SajuToggleRow /
  StepProgressBarView / WheelPicker exist under `Woontech/Features/SajuInput/Shared/`.
  None of them are in the Xcode target.
- S5 .. S17: **Not started.** All corresponding view files are absent (directories
  `Steps/`, `Loader/`, `Result/`, `SignUp/`, `Referral/` are empty).
- S18: **Not done.** `RootView.swift` still routes `.sajuInput` to
  `SajuInputPlaceholderView`. No `.home` case. `SajuInputPlaceholderView` still
  carries the `SajuInputRoot` accessibility identifier — that identifier has not
  been moved to a Step 1 container (creates AC-1/AC-62 regression risk once the
  real flow lands).
- S19: **Not done.** No `saju.*` keys in `ko.lproj/Localizable.strings`.
- S20: **Not done** (cannot be — no views exist).
- S21: **Not done.** `WoontechApp.swift` has no new launch args, no `SajuInputStore`
  wiring.
- S22: **Not done.** Edge cases (name truncation, hourKnown=false dash rendering,
  stable-hash excluding name) are not realized in any view.
- S23: **Not done.** `Woontech.xcodeproj/project.pbxproj` does not reference
  `SajuInputFlowView`, `SajuInputModel`, `SajuFlowModel`, `SajuInputStore`,
  `SolarTimeCalculator`, `CityCatalog`, or `SajuAnalysisEngine`. Verified via
  grep: "No matches in pbxproj". Consequently the new Swift files are silently
  excluded from the build — that is the only reason the build currently succeeds.

### Tests

- T1 .. T33 (unit): **None written.** `WoontechTests/` still contains only
  `OnboardingFlowStateTests.swift` and `OnboardingStoreTests.swift`.
- T34 .. T62 (ui): **None written.** `WoontechUITests/` still contains only
  `OnboardingUITests.swift`.

## Build / Test failures

- **Build (as given)**: `xcodebuild -scheme Woontech -destination 'platform=iOS Simulator,name=iPhone 15' build`
  fails with:
  > xcodebuild: error: Unable to find a device matching the provided destination specifier:
  > { platform:iOS Simulator, OS:latest, name:iPhone 15 }
  The simulator pool on this machine only has iPhone 16e / 17 / 17 Pro / 17 Pro Max /
  17e / Air. The spec/plan/checklist do not require a specific simulator model, but
  the harness-provided command cannot succeed here. I re-ran with `name=iPhone 17`
  as a sanity check and the build **succeeded** — but only because none of the new
  Shared/Features/Shared source files are registered in `project.pbxproj` and are
  therefore excluded from compilation. A real PASS would need those files added to
  the target **and** the build succeeding. Neither condition holds.
- **Unit tests**: command is `echo 'SKIP: no changed unit test files in this worktree'`
  — harness-skipped. Recorded as noted; no new unit tests exist for T1–T33 to execute.
- **UI tests**: command is `echo 'SKIP: no changed ui test files in this worktree'`
  — harness-skipped. Recorded as noted; no new UI tests exist for T34–T62 to execute.

## Required changes

1. **Build the remaining feature surface.** Create every missing view listed in the
   plan's §2 "Affected Files — New — UI (Features/SajuInput)" block:
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
   `OnboardingUITests` does not regress (T62 smoke test).
3. **Inject the store.** Update `WoontechApp.swift` to own a `SajuInputStore`
   `@StateObject`, expose it via `environmentObject`, and honor
   `-resetSajuInput`, `-sajuStartStep <N>`, `-preloadedProfile <JSON>` launch args.
4. **Localization.** Add all `saju.*` keys used by Steps 1–10 (titles, hints, CTA
   labels, checkbox/toggle labels, accuracy-badge strings, disclaimer phrase,
   referral copy) to `Woontech/Resources/ko.lproj/Localizable.strings`. The disclaimer
   must contain "본 앱은 학습·참고용이며 투자 권유가 아닙니다" verbatim.
5. **Register all new files in the Xcode project.** Add every new `.swift` file
   (both the `Woontech/Shared/*.swift` domain files and everything under
   `Woontech/Features/SajuInput/**`) to `Woontech.xcodeproj/project.pbxproj`
   with the correct target membership, and add the new test files to the
   `WoontechTests` / `WoontechUITests` targets. Current pbxproj has zero
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

## Patch eligibility

Requires implementor rework.

The missing work spans ~18 new SwiftUI view files, RootView routing changes, an
app-level store injection with new launch-arg handling, full localization table
authoring, ~33 unit tests, ~29 UI tests, and a non-trivial Xcode project file
mutation. This is not a small, localized fix — it is the majority of the feature
implementation. Per the reviewer-patch rules (small, localized, no architecture
change, no API-surface change), this must go back to the implementor.

## Patch applied

Not applied; requires implementor rework.

## Verification after patch

Not run after patch; no reviewer patch was applied.

## Remaining risk

- Once the implementor adds the files, `project.pbxproj` edits must be careful —
  fileRefs, group membership, and `PBXSourcesBuildPhase` / `PBXResourcesBuildPhase`
  entries must all be present or the "build succeeds but new code isn't compiled"
  trap (currently happening) will persist invisibly.
- The supplied build destination (`name=iPhone 15`) is not available on this
  machine. Either the harness needs to provide an available model (e.g. `iPhone 17`)
  or the command should be relaxed to `generic/platform=iOS Simulator`; otherwise
  every future review iteration will fail on the build command even when the code
  is correct.
- The `SajuInputRoot` accessibility identifier currently lives on
  `SajuInputPlaceholderView`. Whoever moves it must do so atomically with the
  placeholder removal and Step 1 container introduction to avoid breaking
  `OnboardingUITests` (risk callout §9 in the plan).

## Resolved since previous iteration

None — this is iteration 1.

## Still outstanding from prior iterations

None — this is iteration 1.
