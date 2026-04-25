# WF3-04 투자 태도 상세 — Implementation Plan v1

## Goal

Implement the `InvestingAttitudeDetailView` screen (pushed from Hero card tap) that displays a user's investment attitude score (0–100) with breakdowns and recommendations. The view uses an independent `InvestingAttitudeDetailProviding` protocol (completely separate from `HeroInvestingProviding`) to fetch all data.

## Affected Files

### New Files
- `Woontech/Features/Home/Detail/Investing/InvestingAttitudeDetailProviding.swift`
  - Protocol `InvestingAttitudeDetailProviding` with properties: `score`, `attitudeName`, `oneLiner`, `breakdown`, `recommendations`
  - Data model `ScoreBreakdownItem` with fields: `name`, `value`, `description`
  - `MockInvestingAttitudeDetailProvider` with default values

- `Woontech/Features/Home/Detail/Investing/InvestingAttitudeDetailView.swift`
  - Main detail screen with ScrollView layout
  - Sub-views: score circle, attitude header, breakdown section, recommendations section, disclaimer

### Modified Files
- `Woontech/Features/Home/HomeDependencies.swift`
  - Add property `investingAttitudeDetail: any InvestingAttitudeDetailProviding`
  - Add parameter to `init()` with default mock

- `Woontech/Features/Home/HomeRouteDestinations.swift`
  - Replace `InvestingPlaceholderView` with actual `InvestingAttitudeDetailView` in the `.investing` case
  - Inject `HomeDependencies` or provider directly

## Data Model / State Changes

### New Data Model: `ScoreBreakdownItem`
```
struct ScoreBreakdownItem {
    let name: String        // e.g., "위험 선호", "분석 의존"
    let value: Int          // 0~100; clamped in view
    let description: String // e.g., "신중한 투자 접근 선호"
}
```

### New Protocol: `InvestingAttitudeDetailProviding`
```
protocol InvestingAttitudeDetailProviding {
    var score: Int { get }                           // 0~100; clamped to range by view
    var attitudeName: String { get }                 // e.g., "신중한 탐험가"
    var oneLiner: String { get }                     // e.g., "공격보다 관찰이 내 성향에 맞아요"
    var breakdown: [ScoreBreakdownItem] { get }      // Array of breakdown items
    var recommendations: [String] { get }            // Array of recommendation strings
}
```

### State Management
- No local @State needed in `InvestingAttitudeDetailView` — all data comes from injected provider
- NavigationStack in `HomeDashboardView` handles path management (auto-pop via back button)

## Implementation Steps

### Step 1: Create data models and protocol
1. Create file `Woontech/Features/Home/Detail/` (new directory)
2. Create file `Woontech/Features/Home/Detail/Investing/` (new directory)
3. Define `ScoreBreakdownItem` struct in `InvestingAttitudeDetailProviding.swift`
4. Define `InvestingAttitudeDetailProviding` protocol
5. Implement `MockInvestingAttitudeDetailProvider` with spec defaults:
   - score = 72
   - attitudeName = "신중한 탐험가"
   - oneLiner = "공격보다 관찰이 내 성향에 맞아요"
   - breakdown = 3 items (e.g., 위험 선호, 분석 의존, 감정 통제)
   - recommendations = 3 items
6. Add custom init to mock allowing parameterized overrides

### Step 2: Create InvestingAttitudeDetailView
1. Create file `Woontech/Features/Home/Detail/Investing/InvestingAttitudeDetailView.swift`
2. Add helper function `clampAttitudeScore(_ score: Int) -> Int` (modeled after `clampHeroScore`)
3. Implement main structure with:
   - NavigationStack toolbar title "투자 태도" + auto back button
   - ScrollView with VStack
   - Sub-views:
     - `ScoreCircleView` (large centered circle with score + "/100")
     - `AttitudeHeaderView` (bold name + caption one-liner)
     - `BreakdownSectionView` (conditionally shows if breakdown.count > 0)
     - `RecommendationsSectionView` (conditionally shows if recommendations.count > 0)
     - `DisclaimerView` (reused)

### Step 3: Implement ScoreCircleView sub-view
1. Display clamped score in large bold font (size ~56, weight .bold)
2. Display "/100" in smaller font beside it (size ~20, weight .regular)
3. Center horizontally, use appropriate padding/spacing
4. Add accessibility label "{score}점"
5. Use 2 lines (score on top, optional secondary info on second line if space)

### Step 4: Implement AttitudeHeaderView sub-view
1. Display `attitudeName` in bold (font .headline or size 16, weight .semibold)
2. Display `oneLiner` in caption style below (font .caption or size 13)
3. Use leading alignment
4. Add accessibility identifiers

### Step 5: Implement BreakdownSectionView sub-view
1. Conditional: only render if `breakdown.count > 0`
2. Header: "점수 구성" (size 14, weight .semibold)
3. For each item in breakdown:
   - Create `ScoreBreakdownCardView` sub-view:
     - Render `name` (bold, size 14)
     - Render `value` (e.g., "72점" with clamped value 0-100)
     - Render horizontal progress bar (0.0 to 1.0, colored using a primary/accent color)
     - Render `description` below bar (caption style, multi-line, wrapping for Dynamic Type XL)
   - Add spacing between cards (8-12pt)
4. Wrap in bordered card container (DesignTokens.line3 stroke)

### Step 6: Implement RecommendationsSectionView sub-view
1. Conditional: only render if `recommendations.count > 0`
2. Header: "추천 액션" (size 14, weight .semibold)
3. Render recommendations as bullet list:
   - Use similar pattern to `BulletListView` (bullet circle + text)
   - 6pt circle bullets in muted color
   - Text in body style (size 13)
   - Multi-line wrapping support
4. Wrap in bordered card container

### Step 7: Update HomeDependencies
1. Add property: `investingAttitudeDetail: any InvestingAttitudeDetailProviding`
2. Add init parameter with default: `investingAttitudeDetail: any InvestingAttitudeDetailProviding = MockInvestingAttitudeDetailProvider()`
3. Store in property

### Step 8: Update HomeRouteDestinations
1. In `navigationDestination(for: HomeRoute.self)`, replace:
   ```swift
   case .investing:
       InvestingPlaceholderView()
   ```
   With:
   ```swift
   case .investing:
       InvestingAttitudeDetailView(provider: homeDeps.investingAttitudeDetail)
   ```
   (Requires injecting `homeDeps` into the view closure)

### Step 9: Add accessibility identifiers (throughout implementation)
- View root: "InvestingAttitudeDetailView"
- NavBar title: "InvestingAttitudeDetailTitle"
- Score circle: "AttitudeScore"
- Attitude name: "AttitudeNameText"
- One-liner: "AttitudeOneliner"
- Breakdown section: "BreakdownSection"
- Each breakdown item: "BreakdownItem_\(index)"
- Breakdown item name: "BreakdownItemName_\(index)"
- Breakdown item value bar: "BreakdownItemBar_\(index)"
- Breakdown item description: "BreakdownItemDescription_\(index)"
- Recommendations section: "RecommendationsSection"
- Recommendations list: "RecommendationsList"
- Each recommendation: "Recommendation_\(index)"

### Step 10: Finalize view layout and spacing
1. Set ScrollView padding (.horizontal: 16, .vertical: 0)
2. Set inter-section spacing (20-24pt)
3. Ensure disclaimer appears at bottom with proper padding
4. Test Dynamic Type scales (body, caption, etc. scale appropriately)

## Unit Test Plan

### Test File: `WoontechTests/Home/InvestingAttitudeDetailViewTests.swift`

#### Score Clamping Tests
- `testClampAttitudeScore_negativeValueClampedToZero()`: score=-10 → displays 0
- `testClampAttitudeScore_largeValueClampedTo100()`: score=120 → displays 100
- `testClampAttitudeScore_validRangePassthrough()`: score=72 → displays 72

#### Provider Data Binding Tests
- `testAttitudeNameBindsFromProvider()`: View displays exact `provider.attitudeName`
- `testOneLinerBindsFromProvider()`: View displays exact `provider.oneLiner`
- `testScoreBindsFromProvider()`: Clamped score matches view

#### Breakdown Visibility Tests
- `testBreakdownSection_rendersWhenNonEmpty()`: 3 items → 3 cards rendered
- `testBreakdownSection_hiddenWhenEmpty()`: empty array → section (header + content) not rendered
- `testBreakdownCardCount_matchesArrayLength()`: 5 items → 5 cards

#### Breakdown Content Tests
- `testBreakdownCard_displaysNameValueDescription()`: Item name, value (clamped 0-100), description all visible
- `testBreakdownBar_widthProportionalToValue()`: value=50 → bar ~50% width; value=100 → full width
- `testBreakdownValue_clampedTo0_100()`: value=-5 → displays 0; value=150 → displays 100

#### Recommendations Visibility Tests
- `testRecommendationsSection_rendersWhenNonEmpty()`: 3 items → 3 bullets rendered
- `testRecommendationsSection_hiddenWhenEmpty()`: empty array → entire section hidden
- `testRecommendationBulletCount_matchesArrayLength()`: 4 items → 4 bullets

#### Recommendations Content Tests
- `testRecommendationText_displaysFromArray()`: Each recommendation string rendered as-is

#### Disclaimer Tests
- `testDisclaimerView_alwaysRendered()`: Disclaimer text present in all cases

#### Accessibility Tests
- `testAccessibilityLabel_score()`: Score element has label "{score}점"
- `testAccessibilityLabel_breakdownItem()`: "item.name, item.value점, item.description"
- `testVoiceOverFocusOrder()`: NavBar → Score → Name → OneLiner → Breakdown → Recommendations → Disclaimer

#### Mock Provider Tests
- `testMockProviderDefaults_score72()`: Default score is 72
- `testMockProviderDefaults_attitudeName_신중한탐험가()`: Correct default name
- `testMockProviderDefaults_breakdown3Items()`: Default breakdown has 3 items
- `testMockProviderDefaults_recommendations3Items()`: Default recommendations has 3 items
- `testMockProvider_customInitValues()`: Custom init overrides applied correctly

## UI Test Plan

### Test File: `WoontechUITests/Home/InvestingAttitudeDetailUITests.swift`

#### Navigation Tests (AC-1, AC-2)
- `testHeroCardTap_pushesInvestingAttitudeDetail()`: Tap Hero card → view pushed
- `testBackButton_popsToHome()`: Tap back button → returns to HomeDashboardView
- `testNavBarTitle_显示"투자태도"()`: NavBar shows "투자 태도"

#### Score Display Tests (AC-3)
- `testScoreDisplay_unclampedScore72()`: Displays 72/100
- `testScoreDisplay_negativeScoreClamped()`: score=-10 → shows 0/100
- `testScoreDisplay_largeScoreClamped()`: score=120 → shows 100/100

#### Attitude Name & OneLiner Tests (AC-4)
- `testAttitudeNameDisplay()`: Name text visible
- `testOneLinerDisplay()`: One-liner text visible
- `testAttitudeNameAndOneLiner_multipleLines()`: Text wraps on narrow screens

#### Breakdown Section Tests (AC-5, AC-6)
- `testBreakdownCards_renderForEachItem()`: 3 items → 3 cards visible
- `testBreakdownCard_displaysNameValueBar()`: Name, value, bar all visible per card
- `testBreakdownCard_description_wrapsAtDynamicTypeXL()`: Description text wraps, no truncation at Dynamic Type XL
- `testBreakdownSection_hiddenWhenEmpty()`: No cards/header when empty
- `testBreakdownBar_fillProportional()`: Bar width matches value ratio

#### Recommendations Section Tests (AC-7)
- `testRecommendationBullets_renderForEachItem()`: N items → N bullets
- `testRecommendationText_wrapsAtDynamicTypeXL()`: Text wraps, readable at XL size
- `testRecommendationsSection_hiddenWhenEmpty()`: No bullets/header when empty

#### Disclaimer Tests (AC-8)
- `testDisclaimerAtBottom()`: Disclaimer visible at scroll bottom
- `testDisclaimerText_readableOnSmallerScreens()`: Text visible on iPhone SE / compact widths

#### Provider Isolation Tests (AC-9, AC-10)
- `testInvestingAttitudeDetail_usesOwnProvider()`: View bound to `InvestingAttitudeDetailProviding`, not `HeroInvestingProviding`
- `testMockProviderSwap_allBindingsReflect()`: Inject custom mock → all fields reflect custom values

#### Accessibility Tests (AC-11)
- `testVoiceOverFocusOrder()`: Voice-over traverses in order: Title → Score → Name → OneLiner → Breakdown → Recommendations → Disclaimer
- `testScoreAccessibilityLabel()`: Labeled as "{score}점"
- `testBreakdownItemAccessibilityLabel()`: Labeled as "{name}, {value}점, {description}"

#### Dynamic Type Tests (AC-12)
- `testDynamicType_XL_noTruncation()`: Description, recommendations, oneLiner all wrap; no text cut off

## Risks / Open Questions

### Risks

1. **Circular Score Display vs. Text Display**
   - Spec requires "큰 원형 지수(숫자 + `/100`)" but current codebase uses text-based score (see `HeroInvestingCardView`)
   - **Risk**: Circular progress indicator would require custom shape/canvas rendering
   - **Mitigation**: Implement as large bold text display (similar to Hero card), not an actual circle widget
   - **Verify with stakeholder**: Confirm if "원형" means conceptual (large score) or literal (circular progress ring)

2. **Breakdown Card Progress Bar Color**
   - Spec does not specify the color of the progress bar
   - Current codebase uses 오행 colors (wood, fire, earth, metal, water) for various indicators
   - **Mitigation**: Use a neutral accent color or primary color (suggest DesignTokens.ink or a new token)
   - **Action**: Decide bar color in code review

3. **Provider Injection in HomeRouteDestinations**
   - `HomeRouteDestinations` is currently a modifier in `HomeDashboardView`
   - To inject `InvestingAttitudeDetailProviding`, we need access to `homeDeps`
   - **Mitigation**: Pass `homeDeps` via @EnvironmentObject or create a wrapper parameter
   - **Current pattern**: `homeDeps` is already @EnvironmentObject in `HomeDashboardView`

4. **Empty State Handling**
   - Spec says sections hide if arrays are empty, but doesn't specify if entire view handles empty provider gracefully
   - **Mitigation**: All properties have sensible defaults in mock; production provider must also ensure non-nil arrays
   - **Test**: Verify graceful rendering with empty breakdown + empty recommendations

5. **Disclaimer Footer Padding**
   - Spec says "최하단에 렌더된다" (at bottom) but doesn't clarify bottom padding/safe area
   - **Mitigation**: Reuse existing `DisclaimerView` with standard padding; test on notched devices
   - **Verify**: Confirm padding in bottom-safe-area scenarios (e.g., iPhone with Dynamic Island)

### Open Questions

1. **Circular Score Visualization**
   - Should the score display be a literal circular progress indicator (Canvas + Circle + trim), or is large text "원형" intended?
   - **Assumption**: Text-based (72/100) matching Hero card style; update if literal circular ring required

2. **Breakdown Bar Color**
   - Which color should the breakdown progress bar use?
   - **Assumption**: Use a primary accent color; finalize in code review

3. **Score Breakdown Item Icons/Indicators**
   - Should breakdown cards have left-side indicator dots/icons (like 오행 colors)?
   - **Assumption**: No; spec only mentions name, value bar, description

4. **Dynamic Type Adjustment for Score Circle**
   - At Dynamic Type XL, should the score font (size ~56) scale further, or remain fixed?
   - **Assumption**: Use `.font(.system(size: 56, weight: .bold))` (fixed size); scalable font not needed

5. **Scroll Behavior at Minimum Content**
   - If breakdown + recommendations are empty, is ScrollView still needed?
   - **Assumption**: Yes, for consistent navigation bar behavior and future extensibility

6. **Reusable Bullet List Component**
   - Should we create a new generic bullet list view or adapt `BulletListView`?
   - **Assumption**: Adapt/reuse `BulletListView` pattern inline for consistency

---

**Next Steps for Implementor**
1. Clarify "원형 지수" intent (literal circle vs. large text)
2. Confirm progress bar color with design
3. Create data model and protocol
4. Implement main view with sub-views
5. Update dependencies and routing
6. Write and run unit + UI tests
7. Verify accessibility and Dynamic Type
