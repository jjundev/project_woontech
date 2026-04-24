# Plan Feedback v1

## Problems

### P1 (Critical) — AC-6/AC-7: Test-spy verification is missing, only crash-free check planned

The spec explicitly requires:
> AC-6: 벨 탭 시 `onBellTap` 핸들러가 **1회** 호출된다 **(테스트 스파이로 검증)**.  
> AC-7: 아바타 탭 시 `onAvatarTap` 핸들러가 **1회** 호출된다.

The current plan's UI tests for these ACs only assert "탭 후 크래시 없음 + `HomeDashboardRoot` 여전히 존재". This does **not** satisfy the one-invocation count requirement.

Because `onBellTap` / `onAvatarTap` are `() -> Void` closures passed into `HomeHeaderView`, and the project does not list ViewInspector as a dependency (making pure SwiftUI unit-level button-tap tests impractical without it), the recommended fix is an **accessibility-based spy counter pattern** in `HomeDashboardView`:

- Add `@State private var bellTapCount = 0` and `@State private var avatarTapCount = 0`.
- Wire `onBellTap: { bellTapCount += 1 }` and `onAvatarTap: { avatarTapCount += 1 }`.
- Expose spy values via hidden (`.opacity(0)`) but accessibility-accessible `Text` elements with identifiers `"HomeBellTapCount"` and `"HomeAvatarTapCount"`.
- UI tests tap the button then assert the spy label equals `"1"`.

This is an in-plan, no-external-dependency approach that genuinely verifies one invocation.

### P2 (Minor) — `HomeTabBarPlaceholderView` referenced in Step 7 but absent from file list

Step 7's layout code references `HomeTabBarPlaceholderView()` with `.accessibilityIdentifier("HomeTabBarPlaceholder")`, but this type does not appear in the "New Files" table or anywhere else in the plan. The implementor has no guidance on where to define it.

Fix: declare it as a `private struct HomeTabBarPlaceholderView: View` at the bottom of `HomeDashboardView.swift` (a 49 pt tall clear `Rectangle`), and note this in Step 7.

## Required Changes

1. **Step 7** — add two `@State` spy counters, wire them into `onBellTap`/`onAvatarTap`, add hidden `Text` spy-value views with `"HomeBellTapCount"` and `"HomeAvatarTapCount"` accessibility identifiers.
2. **Step 7** — add an inline `private struct HomeTabBarPlaceholderView: View` definition note (or add a row to the new-files table pointing to `HomeDashboardView.swift`).
3. **Section 6 UI Test Plan** — replace `test_bellTap_handlerCalled` and `test_avatarTap_handlerCalled` verification with: tap button → assert `staticTexts["HomeBellTapCount"].label == "1"` (resp. `"HomeAvatarTapCount"`).
4. **Remove** the misleading footnote at the bottom of Section 6 that says spy verification is deferred; replace with a note explaining the accessibility-counter approach used.

## Resolved since previous iteration

_(Iteration 1 — no prior iterations.)_

## Still outstanding from prior iterations

_(Iteration 1 — nothing carried forward.)_
