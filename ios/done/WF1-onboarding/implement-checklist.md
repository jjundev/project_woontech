# Implementation Checklist

## Requirements (from spec)
- [ ] R1: Show a splash screen immediately on launch with logo placeholder, "운테크" title, "오늘의 투자 태도를 점검하세요" subtitle, and a bottom circular spinner.
- [ ] R2: After exactly 1.5 seconds on splash, route by persisted `hasSeenOnboarding`: `false` to Onboarding 1/3, `true` to the WF2 saju input entry point.
- [ ] R3: Provide exactly three onboarding steps with the FR-O1 titles and body strings, preserving the specified Korean text and line breaks.
- [ ] R4: Each onboarding step uses the required layout: top-right "건너뛰기", central illustration placeholder/title/body, bottom page indicator, and CTA.
- [ ] R5: Page indicator shows the active step as a 16pt pill and inactive steps as 6pt circles.
- [ ] R6: CTA labels are "다음" on steps 1 and 2, and "시작하기" on step 3.
- [ ] R7: CTA advances step 1 to 2 and step 2 to 3; checked step 3 "시작하기" exits to the WF2 saju input entry point.
- [ ] R8: "건너뛰기" on any onboarding step exits to the WF2 saju input entry point.
- [ ] R9: Left/right swipes navigate between steps, with step 1 right-swipe and step 3 left-swipe ignored.
- [ ] R10: Tapping any indicator dot jumps directly to that step, and indicator state stays synchronized for CTA, swipe, and indicator navigation.
- [ ] R11: Before leaving onboarding via skip or start, persist `hasSeenOnboarding = true`.
- [ ] R12: Step 3 only shows the disclaimer checkbox text "본 앱은 학습·참고용이며 투자 권유가 아닙니다." and the footer "투자 결정은 본인 판단과 책임 하에 이루어져야 합니다".
- [ ] R13: Step 3 disclaimer checkbox defaults to unchecked; while unchecked, "시작하기" is visually disabled and cannot navigate.
- [ ] R14: Toggling the disclaimer checkbox immediately enables/disables "시작하기"; the checkbox state is not persisted across onboarding re-exposure or reinstall.
- [ ] R15: Once `hasSeenOnboarding` is true, subsequent launches always bypass onboarding after splash, even if the user exits during WF2.
- [ ] R16: The app is native iOS SwiftUI, respects safe areas, adds no delay beyond the splash timer, and keeps step animations within 300ms.
- [ ] R17: CTA, skip, indicator dots, and disclaimer checkbox have VoiceOver labels and expose enabled/disabled/selected/checked state.
- [ ] R18: Skip and indicator dots have at least 44x44pt hit targets.
- [ ] R19: User-facing strings are localized through keys, with Korean provided for the first release.
- [ ] R20: Logo and onboarding illustrations are placeholder asset-catalog entries that can be replaced later.

## Implementation steps
- [ ] S1: Scaffold `ios/project.yml` for the `Woontech`, `WoontechTests`, and `WoontechUITests` targets and a runnable scheme.
- [ ] S2: Add `ios/README.md`, `Info.plist`, `Assets.xcassets`, and `ko.lproj/Localizable.strings`.
- [ ] S3: Implement `WoontechApp` and inject a shared `OnboardingStore` into `RootView`.
- [ ] S4: Implement `RootView` with `splash`, `onboarding`, and `sajuInput` routes.
- [ ] S5: Implement `OnboardingStore` with default `false`, `markSeen()`, persistence, and test-isolated `UserDefaults` injection.
- [ ] S6: Implement `SplashView` with the required content, safe-area layout, spinner, and 1.5 second async timer.
- [ ] S7: Implement static onboarding content backed by localized keys and placeholder asset names.
- [ ] S8: Implement `OnboardingView` with a single source of truth for current step, disclaimer state, skip action, CTA action, and synchronized navigation.
- [ ] S9: Implement `OnboardingStepView` for the central illustration/title/body layout and combined accessibility label.
- [ ] S10: Implement `PageIndicatorView` with pill/circle visuals, 44x44 hit targets, selected state, and tap-to-jump behavior.
- [ ] S11: Implement `DisclaimerCheckboxView` with unchecked default, toggle behavior, checked/unchecked accessibility state, and no persistence.
- [ ] S12: Implement a reusable primary CTA style that supports visual disabled state and blocks action while disabled.
- [ ] S13: Implement `SajuInputPlaceholderView` as the WF2 entry stub with a stable `SajuInputRoot` accessibility identifier.
- [ ] S14: Add accessibility identifiers or stable labels needed by UI tests for splash, steps, CTA, skip, indicators, checkbox, and WF2 placeholder.
- [ ] S15: Add placeholder logo and illustration image sets to the asset catalog.
- [ ] S16: Ensure all user-visible text comes from `Localizable.strings` and matches the spec strings exactly where required.
- [ ] S17: Generate/open the Xcode project via XcodeGen and keep generated project files out of source unless the repository convention requires committing them.

## Tests
- [ ] T1 (unit): Verify `OnboardingStore` defaults `hasSeenOnboarding` to `false`.
- [ ] T2 (unit): Verify `markSeen()` sets `hasSeenOnboarding = true` and persists it in an isolated defaults suite.
- [ ] T3 (unit): Verify CTA enabled state is true on steps 1/2 and depends on disclaimer state on step 3.
- [ ] T4 (unit): Verify CTA label key is "다음" for steps 1/2 and "시작하기" for step 3.
- [ ] T5 (ui): On clean launch, verify splash appears immediately and onboarding step 1 appears after the 1.5 second splash delay.
- [ ] T6 (ui): Verify all three onboarding steps display the exact FR-O1 title/body strings.
- [ ] T7 (ui): Verify CTA taps move step 1 to 2 and step 2 to 3, with the active indicator updated.
- [ ] T8 (ui): Verify left swipe advances from steps 1/2 and right swipe returns from steps 2/3.
- [ ] T9 (ui): Verify right swipe on step 1 and left swipe on step 3 do not change the step.
- [ ] T10 (ui): Verify tapping indicator dots 1, 2, and 3 jumps directly to the matching step.
- [ ] T11 (ui): Verify skip from each step navigates to `SajuInputRoot` and persists `hasSeenOnboarding = true`.
- [ ] T12 (ui): Verify step 3 initially shows an unchecked disclaimer checkbox and disabled "시작하기".
- [ ] T13 (ui): Verify tapping disabled "시작하기" while unchecked causes no navigation.
- [ ] T14 (ui): Verify checking and unchecking the disclaimer toggles "시작하기" enabled state immediately.
- [ ] T15 (ui): Verify checked step 3 "시작하기" navigates to `SajuInputRoot` and persists `hasSeenOnboarding = true`.
- [ ] T16 (ui): Verify launch with `hasSeenOnboarding = true` bypasses onboarding after splash and lands on `SajuInputRoot`.
- [ ] T17 (ui/accessibility): Verify CTA, skip, indicator dots, and checkbox expose VoiceOver labels plus enabled/disabled/selected/checked state.
- [ ] T18 (ui/accessibility): Verify skip and indicator dot hit frames are at least 44x44pt.
- [ ] T19 (manual): Run the smoke path on an iOS 17 simulator: clean install, splash, onboarding navigation, disclaimer gating, WF2 landing, relaunch bypass, and VoiceOver focus/state checks.
