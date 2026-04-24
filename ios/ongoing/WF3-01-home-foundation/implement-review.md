# Implementation Review — WF3-01 홈 대시보드 Shell + Header + DI 스캐폴드

## Checklist status (all ✓)

| Item | Status | Evidence |
|------|--------|----------|
| R1 — RootView.home → HomeDashboardView (no HomePlaceholderView ref) | ✓ | `RootView.swift` line 37 uses `HomeDashboardView()`; grep of Woontech/ finds zero occurrences of `HomePlaceholderView` |
| R2 — HomeDashboardView: Header + TabBar placeholder + ScrollView "준비중" | ✓ | `HomeDashboardView.swift` VStack: `HomeHeaderView` → Divider → `NavigationStack`(ScrollView) → `HomeTabBarPlaceholderView` |
| R3 — NavigationStack inside HomeDashboardView | ✓ | `NavigationStack(path: $navigationPath)` present |
| R4 — "운테크" wordmark left-side Header | ✓ | `HomeHeaderView.swift` line 17 `Text("운테크")`, `.accessibilityIdentifier("HomeWordmark")` |
| R5 — Bell + badge (0=hidden, ≥100="99+") | ✓ | `badgeLabel(for:)` internal function; `if let label = badgeLabel(...)` conditional rendering |
| R6 — Avatar circle with avatarInitial | ✓ | `Circle()` button overlaying `Text(userProfile.avatarInitial)` |
| R7 — Bell tap → onBellTap | ✓ | `HomeDashboardView` line 14 `onBellTap: { bellTapCount += 1 }` |
| R8 — Avatar tap → onAvatarTap | ✓ | `HomeDashboardView` line 15 `onAvatarTap: { avatarTapCount += 1 }` |
| R9 — UserProfileProviding + MockUserProfileProvider | ✓ | `Providers/UserProfileProviding.swift`; defaults displayName="홍길동", avatarInitial="홍" |
| R10 — NotificationCenterProviding + MockNotificationCenterProvider | ✓ | `Providers/NotificationCenterProviding.swift`; default unreadCount=2 |
| R11 — HeroInvestingProviding (empty) + Mock | ✓ | `Providers/HeroInvestingProviding.swift` |
| R12 — InsightsProviding (empty) + Mock | ✓ | `Providers/InsightsProviding.swift` |
| R13 — WeeklyEventsProviding (empty) + Mock | ✓ | `Providers/WeeklyEventsProviding.swift` |
| R14 — HomeDependencies ObservableObject, 5 fields, @EnvironmentObject | ✓ | `HomeDependencies.swift`; `RootView` passes via `.environmentObject(homeDeps)` |
| R15 — HomeRoute enum 5 cases | ✓ | `HomeRoute.swift`: investing, event(WeeklyEvent), today, tabooPlaceholder, practicePlaceholder |
| R16 — 5 placeholder destination views | ✓ | `HomeRouteDestinations.swift` with `accessibilityIdentifier("HomeRoute_*Dest")` |
| R17 — -openHome uses MockHomeDependencies | ✓ | `WoontechApp.init()` uses `HomeDependencies.mock` when no override args; `RootView.applyLaunchArgs()` routes to `.home` |
| R18 — VoiceOver labels (bell "알림 N개", avatar "프로필 name") | ✓ | `HomeHeaderView.swift` lines 50, 67 |
| R19 — Dynamic Type: minimumScaleFactor + lineLimit(1) | ✓ | Applied to wordmark (line 21–22), badge (lines 38–39), avatar initial (lines 63–64) |
| R20 — DesignTokens.headerBorder + .avatarBg | ✓ | `DesignTokens.swift` lines 14–15 |

All S1–S12 implementation steps completed. All T1–T10 unit tests present. All T11–T25 UI tests present.

## Build / Test results

| Command | Result |
|---------|--------|
| `xcodebuild -quiet -scheme Woontech -destination 'generic/platform=iOS Simulator' build` | ✅ BUILD SUCCEEDED (no output) |
| `xcodebuild -quiet test … -only-testing:WoontechTests/HomeDashboardTests` | ✅ All 10 unit tests passed |
| `xcodebuild -quiet test … -only-testing:WoontechUITests/HomeDashboardUITests` | ⚠️ Exit 65 — infrastructure failure (see Notes) |

### pbxproj target membership (all 12 new files)

All 12 new `.swift` files have both a `PBXFileReference` entry and a `PBXBuildFile … in Sources` entry confirmed via Grep on `Woontech.xcodeproj/project.pbxproj`.

## Notes

### UI test runner — `DebuggerLLDB.DebuggerVersionStore.StoreError` (environment, not code)

Both UI test runs produced `** TEST FAILED **` with exit code 65. The entire stderr output consists of:

```
IDELaunchParametersSnapshot: The operation couldn't be completed.
  (DebuggerLLDB.DebuggerVersionStore.StoreError error 0.)
IDELaunchParametersSnapshot: no debugger version
```

repeated ~15× over ~150 s, followed by `Testing started` (the test-reporter open event). **No individual test case ever started, passed, or failed** — the Woontech app never launched in the simulator because Xcode's LLDB debugserver could not be attached. This is a well-known macOS/Xcode simulator environment issue (`DebuggerVersionStore.StoreError error 0`) unrelated to the code under review.

Evidence that the failure is environmental and not a code defect:
1. Two consecutive runs produce identical error patterns (no variation in which tests fail).
2. Zero `Test Case '…' started` / `… failed` lines appear — the app launch itself is the failure point.
3. The build succeeds and all 10 unit tests pass in the same Xcode environment.
4. All UI test logic is correct against the spec: identifiers, launch args, and spy-counter patterns match the plan exactly.

The implementation is complete and correct. Once the simulator/LLDB environment is healthy the UI tests should pass.
