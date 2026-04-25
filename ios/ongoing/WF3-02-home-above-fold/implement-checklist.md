# Implementation Checklist — WF3-02 홈 Above-the-Fold (Hero + Insights)

---

## Requirements (from spec)

- [ ] R1: Hero card rendered directly below Header; Insights rendered directly below Hero (AC-1)
- [ ] R2: Date label displays `HeroInvestingProviding.displayDate` in `YYYY.MM.DD 요일` format using `ko_KR` locale (e.g. "2026.04.23 목요일") (AC-2)
- [ ] R3: Greeting text shows `"{displayName}님, 오늘의 투자 태도예요"` sourced from `UserProfileProviding.displayName` (AC-3)
- [ ] R4: Score clamped to 0–100 range — score=120 displays as 100, score=-5 displays as 0 (AC-4)
- [ ] R5: One-liner text displays `HeroInvestingProviding.oneLiner` value (AC-5)
- [ ] R6: Tapping the Hero card appends `HomeRoute.investing` to `HomeDashboardView`'s NavigationStack path (AC-6)
- [ ] R7: Insights section always renders exactly 3 cards in fixed order [금기(0), 일진(1), 실천(2)], regardless of provider data order (AC-7)
- [ ] R8: Each Insight card slot binds the corresponding `InsightsProviding` slot data — `badgeLabel`, `badgeColor`, `icon`, `title`, `desc`, `bottomLabel` (AC-8)
- [ ] R9: Tapping the 금기 card appends `HomeRoute.tabooPlaceholder` to path (AC-9)
- [ ] R10: Tapping the 일진 card appends `HomeRoute.today` to path (AC-10)
- [ ] R11: Tapping the 실천 card appends `HomeRoute.practicePlaceholder` to path (AC-11)
- [ ] R12: At Dynamic Type XL (Accessibility-Large), Hero score and one-liner wrap without truncation (AC-12)
- [ ] R13: Horizontal scroll allows reaching the 3rd card (실천); "오늘의 실천" label is visible after swipe (AC-13)
- [ ] R14: If provider returns fewer than 3 cards, missing slots render as empty gray placeholder cards (no crash); AC-14 "empty placeholder" behavior is adopted and fixed (AC-14)
- [ ] R15: VoiceOver — score HStack has `accessibilityLabel` "N점"; each Insight card `Button` has `accessibilityLabel` "{badgeLabel}, {title}"
- [ ] R16: Hero card entire surface is a single hit-test target — child views do not intercept taps
- [ ] R17: Insight cards have fixed width 160 pt, 8 pt spacing between cards, 16 pt horizontal padding in `ScrollView`
- [ ] R18: `MockHeroInvestingProvider` defaults: `score=72`, `oneLiner="공격보다 관찰이 내 성향에 맞아요"`, `displayDate=2026-04-23`
- [ ] R19: `MockInsightsProvider` provides 3 fixed cards matching wire-frame mock data (badgeLabel/icon/title/desc/bottomLabel per slot)

---

## Implementation Steps

- [ ] S1: Extend `HeroInvestingProviding` protocol with `score: Int`, `oneLiner: String`, `displayDate: Date`; complete `MockHeroInvestingProvider` with spec-defined default values (`Woontech/Features/Home/Providers/HeroInvestingProviding.swift`)
- [ ] S2: Add `import SwiftUI` to `InsightsProviding.swift`; define `InsightCard` struct (badgeLabel, badgeColor, icon, title, desc, bottomLabel); extend `InsightsProviding` with `cards: [InsightCard]`; complete `MockInsightsProvider` with 3 fixed wire-frame cards (`Woontech/Features/Home/Providers/InsightsProviding.swift`)
- [ ] S3: Add `tabooColor` (red), `todayColor` (gray), `practiceColor` (green) static properties to `DesignTokens.swift`; annotate as aliases of existing 오행 colors where values are identical
- [ ] S4: Create `Woontech/Features/Home/HeroInvestingCardView.swift` with:
  - Date `Text` with `.accessibilityIdentifier("HomeHeroDate")` using module-level cached `DateFormatter` (format `"yyyy.MM.dd EEEE"`, locale `ko_KR`)
  - Greeting `Text` with `.accessibilityIdentifier("HomeHeroGreeting")`
  - Card body wrapped in `Button(action: onTap)` with `.buttonStyle(.plain)` and `.contentShape(Rectangle())` for single-target hit-test, identified as `"HomeHeroCard"`
  - "투자 관점" badge pill inside card
  - Score `Text("\(clampedScore)")` with `.accessibilityIdentifier("HomeHeroScore")` and HStack `.accessibilityLabel("\(clampedScore)점")`
  - One-liner `Text` with `.accessibilityIdentifier("HomeHeroOneLiner")` and `.fixedSize(horizontal: false, vertical: true)`
  - "상세 보기 ›" trailing indicator
  - `clampedScore` computed as `min(max(0, provider.score), 100)` marked `internal` for unit testing
- [ ] S5: Create `Woontech/Features/Home/InsightCardView.swift` with:
  - `InsightCardView`: badge pill, large icon, bold title, multiline desc (`.fixedSize`), bottom caption, all in `Button` with `.buttonStyle(.plain)` + `.contentShape(Rectangle())` + `.accessibilityLabel("\(card.badgeLabel), \(card.title)")`; fixed `frame(width: 160)`
  - `InsightPlaceholderCard` (private): gray `RoundedRectangle` with `.accessibilityIdentifier("InsightCard_empty_{index}")`
  - `InsightsScrollView`: section label "오늘의 인사이트" (`"HomeInsightsSectionLabel"`), `ScrollView(.horizontal)` with `HStack(spacing: 8)` and `.padding(.horizontal, 16)`, hardcoded slots 0/1/2 using `[safe:]` subscript, routing closures `onTabooTap`/`onTodayTap`/`onPracticeTap`
- [ ] S6: Add `Collection` safe-subscript extension — `subscript(safe index: Index) -> Element?` — either in `Woontech/Shared/CollectionExtensions.swift` (preferred for reuse) or as `private extension Array` inside `InsightCardView.swift`; register file in Xcode project if new file is added
- [ ] S7: In `HomeDashboardView.swift`, replace `Text("준비중").accessibilityIdentifier("HomeDashboardContentPlaceholder")` with `VStack(spacing: 0) { HeroInvestingCardView(...) + InsightsScrollView(...) }.accessibilityIdentifier("HomeDashboardContent")`; wire `navigationPath.append(...)` closures for all 4 routes
- [ ] S8: Add launch-arg parsing in `WoontechApp.swift` for `-mockHeroScore` (Int), `-mockHeroDisplayName` (String), `-mockHeroDate` (ISO-8601 `yyyy-MM-dd`); inject overridden values into `MockHeroInvestingProvider` / `MockUserProfileProvider` when present
- [ ] S9: Verify `HomeDashboardContentPlaceholder` identifier is not referenced in any existing UI test before removing it (grep confirmed safe per plan Risk 7)

---

## Tests

### Unit Tests (`WoontechTests/Home/HomeDashboardTests.swift`)

- [ ] T1 (unit): `test_heroDate_jan1_2026_isThursday` — `DateFormatter(format:"yyyy.MM.dd EEEE", locale:ko_KR)` applied to 2026-01-01 returns `"2026.01.01 목요일"` (AC-2)
- [ ] T2 (unit): `test_heroDate_apr23_2026_isThursday` — same formatter applied to 2026-04-23 returns `"2026.04.23 목요일"` (AC-2)
- [ ] T3 (unit): `test_heroScore_clamp_120_to_100` — `clampedScore(120)` == 100 (AC-4)
- [ ] T4 (unit): `test_heroScore_clamp_negative_to_0` — `clampedScore(-5)` == 0 (AC-4)
- [ ] T5 (unit): `test_heroScore_inRange_unchanged` — `clampedScore(72)` == 72 (AC-4)
- [ ] T6 (unit): `test_mockHeroInvesting_defaults` — `MockHeroInvestingProvider()` has `score == 72` and `oneLiner == "공격보다 관찰이 내 성향에 맞아요"` (AC-5)
- [ ] T7 (unit): `test_insightsCard_count_3` — `MockInsightsProvider().cards.count == 3` (AC-7)
- [ ] T8 (unit): `test_insightsCard_slot0_isTaboo` — `cards[0].badgeLabel == "금기"` (AC-7/8)
- [ ] T9 (unit): `test_insightsCard_slot1_isToday` — `cards[1].badgeLabel == "일진"` (AC-7/8)
- [ ] T10 (unit): `test_insightsCard_slot2_isPractice` — `cards[2].badgeLabel == "실천"` (AC-7/8)
- [ ] T11 (unit): `test_insights_safeSubscript_outOfBounds` — `[InsightCard]()[safe: 0] == nil` (AC-14)
- [ ] T12 (unit): `test_insights_2cardProvider_slot2_isNil` — 2-card array `[safe: 2] == nil`; confirms view logic routes to placeholder, no crash (AC-14)

### UI Tests (`WoontechUITests/Home/HomeDashboardUITests.swift`)

- [ ] T13 (ui): T26 — Launch with `-mockHeroDate 2026-01-01`; `staticTexts["HomeHeroDate"].label == "2026.01.01 목요일"` (AC-2)
- [ ] T14 (ui): T27 — Launch with `-mockHeroDisplayName 민수`; `staticTexts["HomeHeroGreeting"].label == "민수님, 오늘의 투자 태도예요"` (AC-3)
- [ ] T15 (ui): T28 — Tap `otherElements["HomeHeroCard"]`; expect destination identified by `"HomeRoute_investingDest"` to appear (AC-6)
- [ ] T16 (ui): T29 — Tap `otherElements["HomeInsightsCard_0"]`; expect `"HomeRoute_tabooDest"` destination (AC-9)
- [ ] T17 (ui): T30 — Tap `otherElements["HomeInsightsCard_1"]`; expect `"HomeRoute_todayDest"` destination (AC-10)
- [ ] T18 (ui): T31 — Tap `otherElements["HomeInsightsCard_2"]`; expect `"HomeRoute_practiceDest"` destination (AC-11)
- [ ] T19 (ui): T32 — Set `UIContentSizeCategoryOverride` to `UICTContentSizeCategoryAccessibilityL`; verify `staticTexts["HomeHeroScore"]` and element matching `"HomeHeroOneLiner"` both exist with `frame.height > 0` (AC-12)
- [ ] T20 (ui): T33 — First card `"HomeInsightsCard_0"` exists; swipe left on `scrollViews.firstMatch`; verify `"HomeInsightsCard_2"` and `staticTexts["오늘의 실천"]` exist (AC-13)
