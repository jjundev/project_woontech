# Implementation Checklist — WF3-04 투자 태도 상세

## Requirements (from spec)

- [ ] R1: `InvestingAttitudeDetailView` is a new view navigable from Hero card tap
- [ ] R2: NavBar displays "투자 태도" title with back button
- [ ] R3: Score display shows 0–100 value (clamped)
- [ ] R4: Attitude name and one-liner displayed from provider
- [ ] R5: Breakdown array rendered as cards with name/value bar/description
- [ ] R6: Empty breakdown array hides entire section
- [ ] R7: Recommendations rendered as bullets; empty array hides section
- [ ] R8: Disclaimer footer present at scroll bottom
- [ ] R9: `InvestingAttitudeDetailProviding` is separate protocol from `HeroInvestingProviding`
- [ ] R10: Mock provider can be swapped; all bindings reflect injected data
- [ ] R11: VoiceOver focus order and accessibility labels configured
- [ ] R12: Dynamic Type Large/XL: description and recommendations wrap without truncation

## Implementation Steps

### Data Model & Protocol (Step 1)
- [ ] S1.1: Create directory `Woontech/Features/Home/Detail/`
- [ ] S1.2: Create directory `Woontech/Features/Home/Detail/Investing/`
- [ ] S1.3: Define `ScoreBreakdownItem` struct with `name`, `value`, `description` fields
- [ ] S1.4: Define `InvestingAttitudeDetailProviding` protocol with 5 properties
- [ ] S1.5: Implement `MockInvestingAttitudeDetailProvider` with spec defaults
- [ ] S1.6: Add custom init to mock allowing parameterized overrides

### Main View (Step 2)
- [ ] S2.1: Create `InvestingAttitudeDetailView.swift`
- [ ] S2.2: Implement `clampAttitudeScore(_ score: Int) -> Int` function
- [ ] S2.3: Build main view structure with NavigationStack toolbar + ScrollView
- [ ] S2.4: Wire @StateObject or @Environment for provider injection
- [ ] S2.5: Plan sub-view composition (ScoreCircle, AttitudeHeader, Breakdown, Recommendations, Disclaimer)

### Score Circle View (Step 3)
- [ ] S3.1: Create `ScoreCircleView` sub-view
- [ ] S3.2: Display clamped score in large bold font (~56pt)
- [ ] S3.3: Display "/100" beside or below score
- [ ] S3.4: Center horizontally with appropriate padding
- [ ] S3.5: Add accessibility label "{score}점"

### Attitude Header View (Step 4)
- [ ] S4.1: Create `AttitudeHeaderView` sub-view
- [ ] S4.2: Display `attitudeName` in bold (headline or size 16)
- [ ] S4.3: Display `oneLiner` in caption style below
- [ ] S4.4: Use leading alignment
- [ ] S4.5: Add accessibility identifiers

### Breakdown Section (Step 5)
- [ ] S5.1: Create `BreakdownSectionView` sub-view with conditional rendering (`if breakdown.count > 0`)
- [ ] S5.2: Add "점수 구성" header (size 14, weight .semibold)
- [ ] S5.3: Create `ScoreBreakdownCardView` for each item
- [ ] S5.4: Render item name (bold, size 14) in card
- [ ] S5.5: Render value as "{n}점" (clamped 0–100)
- [ ] S5.6: Render horizontal progress bar (width proportional to value/100)
- [ ] S5.7: Render description text with multi-line wrapping support for Dynamic Type XL
- [ ] S5.8: Space cards 8–12pt apart
- [ ] S5.9: Add bordered container (DesignTokens.line3 stroke)
- [ ] S5.10: Add accessibility labels: "item.name, item.value점, item.description"

### Recommendations Section (Step 6)
- [ ] S6.1: Create `RecommendationsSectionView` sub-view with conditional rendering (`if recommendations.count > 0`)
- [ ] S6.2: Add "추천 액션" header (size 14, weight .semibold)
- [ ] S6.3: Render each recommendation as bullet (circle, muted color)
- [ ] S6.4: Support multi-line text wrapping for Dynamic Type XL
- [ ] S6.5: Add bordered container matching breakdown cards
- [ ] S6.6: Add accessibility identifiers for each bullet

### Disclaimer Section
- [ ] S7.1: Integrate or create `DisclaimerView` component
- [ ] S7.2: Position at scroll bottom with proper padding
- [ ] S7.3: Ensure visibility on compact widths (e.g., iPhone SE)

### Dependency Injection (Steps 7–8)
- [ ] S8.1: Add `investingAttitudeDetail: any InvestingAttitudeDetailProviding` property to `HomeDependencies`
- [ ] S8.2: Add init parameter with default: `MockInvestingAttitudeDetailProvider()`
- [ ] S8.3: Update `HomeRouteDestinations.swift` navigationDestination modifier
- [ ] S8.4: Replace `InvestingPlaceholderView` with `InvestingAttitudeDetailView`
- [ ] S8.5: Inject provider from `homeDeps` (via @EnvironmentObject in closure)

### Accessibility & Spacing (Step 9–10)
- [ ] S9.1: Add accessibility identifier "InvestingAttitudeDetailView" to view root
- [ ] S9.2: Add accessibility identifiers for all sub-views (NavBar, Score, Attitude, Breakdown items, Recommendations, Disclaimer)
- [ ] S9.3: Test VoiceOver focus order: NavBar → Score → Name → OneLiner → Breakdown items → Recommendations → Disclaimer
- [ ] S10.1: Set ScrollView padding (.horizontal: 16, .vertical: 0)
- [ ] S10.2: Set inter-section spacing 20–24pt
- [ ] S10.3: Test Dynamic Type scales (body, caption, etc.)

## Unit Tests

### Score Clamping
- [ ] T1: `testClampAttitudeScore_negativeValueClampedToZero()` — score=-10 displays 0
- [ ] T2: `testClampAttitudeScore_largeValueClampedTo100()` — score=120 displays 100
- [ ] T3: `testClampAttitudeScore_validRangePassthrough()` — score=72 displays 72

### Provider Data Binding
- [ ] T4: `testAttitudeNameBindsFromProvider()` — exact attitudeName displayed
- [ ] T5: `testOneLinerBindsFromProvider()` — exact oneLiner displayed
- [ ] T6: `testScoreBindsFromProvider()` — clamped score matches view

### Breakdown Visibility
- [ ] T7: `testBreakdownSection_rendersWhenNonEmpty()` — 3 items → 3 cards
- [ ] T8: `testBreakdownSection_hiddenWhenEmpty()` — empty array → section hidden
- [ ] T9: `testBreakdownCardCount_matchesArrayLength()` — 5 items → 5 cards

### Breakdown Content
- [ ] T10: `testBreakdownCard_displaysNameValueDescription()` — name, value, description visible
- [ ] T11: `testBreakdownBar_widthProportionalToValue()` — value=50 → ~50% width, value=100 → full width
- [ ] T12: `testBreakdownValue_clampedTo0_100()` — value=-5 displays 0, value=150 displays 100

### Recommendations Visibility
- [ ] T13: `testRecommendationsSection_rendersWhenNonEmpty()` — 3 items → 3 bullets
- [ ] T14: `testRecommendationsSection_hiddenWhenEmpty()` — empty array → section hidden
- [ ] T15: `testRecommendationBulletCount_matchesArrayLength()` — 4 items → 4 bullets

### Recommendations Content
- [ ] T16: `testRecommendationText_displaysFromArray()` — each string rendered as-is

### Disclaimer
- [ ] T17: `testDisclaimerView_alwaysRendered()` — disclaimer text present

### Accessibility
- [ ] T18: `testAccessibilityLabel_score()` — label is "{score}점"
- [ ] T19: `testAccessibilityLabel_breakdownItem()` — label is "item.name, item.value점, item.description"
- [ ] T20: `testAccessibilityIdentifiers_assigned()` — all identifiers present

### Mock Provider
- [ ] T21: `testMockProviderDefaults_score72()` — default score is 72
- [ ] T22: `testMockProviderDefaults_attitudeName()` — default name is "신중한 탐험가"
- [ ] T23: `testMockProviderDefaults_oneLiner()` — default one-liner matches spec
- [ ] T24: `testMockProviderDefaults_breakdown3Items()` — 3 breakdown items
- [ ] T25: `testMockProviderDefaults_recommendations3Items()` — 3 recommendations
- [ ] T26: `testMockProvider_customInitValues()` — custom init overrides work

## UI Tests

### Navigation (AC-1, AC-2)
- [ ] T27 (UI): `testHeroCardTap_pushesInvestingAttitudeDetail()` — Hero card tap → view pushed
- [ ] T28 (UI): `testBackButton_popsToHome()` — back button → returns to HomeDashboardView
- [ ] T29 (UI): `testNavBarTitle_displaying투자태도()` — NavBar shows "투자 태도"

### Score Display (AC-3)
- [ ] T30 (UI): `testScoreDisplay_unclampedScore72()` — displays 72/100
- [ ] T31 (UI): `testScoreDisplay_negativeScoreClamped()` — score=-10 shows 0/100
- [ ] T32 (UI): `testScoreDisplay_largeScoreClamped()` — score=120 shows 100/100

### Attitude Name & OneLiner (AC-4)
- [ ] T33 (UI): `testAttitudeNameDisplay()` — name visible
- [ ] T34 (UI): `testOneLinerDisplay()` — one-liner visible
- [ ] T35 (UI): `testAttitudeNameAndOneLiner_multipleLines()` — wrapping on narrow screens

### Breakdown Section (AC-5, AC-6)
- [ ] T36 (UI): `testBreakdownCards_renderForEachItem()` — 3 items → 3 cards visible
- [ ] T37 (UI): `testBreakdownCard_displaysNameValueBar()` — name, value, bar visible per card
- [ ] T38 (UI): `testBreakdownCard_description_wrapsAtDynamicTypeXL()` — no truncation at XL
- [ ] T39 (UI): `testBreakdownSection_hiddenWhenEmpty()` — no cards/header when empty
- [ ] T40 (UI): `testBreakdownBar_fillProportional()` — bar width matches value ratio

### Recommendations Section (AC-7)
- [ ] T41 (UI): `testRecommendationBullets_renderForEachItem()` — N items → N bullets
- [ ] T42 (UI): `testRecommendationText_wrapsAtDynamicTypeXL()` — readable at XL size
- [ ] T43 (UI): `testRecommendationsSection_hiddenWhenEmpty()` — hidden when empty

### Disclaimer (AC-8)
- [ ] T44 (UI): `testDisclaimerAtBottom()` — visible at scroll bottom
- [ ] T45 (UI): `testDisclaimerText_readableOnSmallerScreens()` — visible on iPhone SE / compact

### Provider Isolation (AC-9, AC-10)
- [ ] T46 (UI): `testInvestingAttitudeDetail_usesOwnProvider()` — uses InvestingAttitudeDetailProviding only
- [ ] T47 (UI): `testMockProviderSwap_allBindingsReflect()` — custom mock → all fields reflect

### Accessibility (AC-11)
- [ ] T48 (UI): `testVoiceOverFocusOrder()` — Title → Score → Name → OneLiner → Breakdown → Recommendations → Disclaimer
- [ ] T49 (UI): `testScoreAccessibilityLabel()` — labeled as "{score}점"
- [ ] T50 (UI): `testBreakdownItemAccessibilityLabel()` — labeled as "{name}, {value}점, {description}"

### Dynamic Type (AC-12)
- [ ] T51 (UI): `testDynamicType_XL_noTruncation()` — all text wraps, no truncation

---

## Sign-off Checklist

Before marking implementation complete:

- [ ] All acceptance criteria (R1–R12) implemented
- [ ] All unit tests pass (T1–T26)
- [ ] All UI tests pass (T27–T51)
- [ ] Code reviewed for provider isolation (AC-9)
- [ ] VoiceOver tested on device/simulator
- [ ] Dynamic Type XL tested on simulator (Settings → Accessibility → Display & Text Size)
- [ ] Disclaimer text finalized and integrated
- [ ] "원형 지수" presentation approved by stakeholder (text-based vs. circular ring)
- [ ] Progress bar color determined and applied (DesignTokens token or custom)
- [ ] No compiler warnings
