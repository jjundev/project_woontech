# Plan Feedback v1

## Problems

### P1 — VoiceOver ordering not addressed (non-functional constraint)

The spec explicitly requires:
> VoiceOver 순서: NavBar → 타이틀 카드 → 의미 → 사주 관계 → 투자 관점 → 액션 버튼 3개 → disclaimer.

The plan mentions `accessibilityIdentifier` throughout for UI-test hooks but never addresses VoiceOver ordering:
- No mention of `.accessibilityElement(children: .contain)` for section-container grouping.
- No confirmation that the custom HStack NavBar (outside the ScrollView) is traversed *before* ScrollView content in VoiceOver — while SwiftUI's natural top-to-bottom layout order usually satisfies this, the plan must explicitly state the strategy (rely on layout order, or add explicit `.accessibilitySortPriority()` / grouping modifiers).
- No test verifies traversal order or that sections are correctly grouped.

### P2 — AC-13 view-binding test gap

AC-13: "사용자 정의 값을 주입하면 **모든 섹션**이 해당 값으로 바인딩된다 (단위 테스트)"

The unit tests U1–U10 test `MockEventDetailProvider.content(for:)` return values only. They verify the *provider* layer, not that `EventDetailView` actually renders the injected content. The existing UI tests verify only the default mock values are displayed. UI10 tests empty-array → section hidden, but there is no test that:
- Injects a custom non-empty `meaning` string into the view and asserts `EventDetailMeaningText` shows it.
- Injects a custom `sajuRelationFormula` and asserts `EventDetailSajuFormula` shows it.
- Injects a custom `learnCTAText` and asserts `EventDetailLearnButton` label matches it.

Without these, a bug that hardcodes section text instead of binding to the provider would pass all tests.

## Required changes

1. **Add VoiceOver accessibility guidance** to the implementation steps:
   - State that the overall VStack layout (NavBar HStack above ScrollView) naturally satisfies the required VoiceOver order; document this explicitly.
   - Add `.accessibilityElement(children: .contain)` to the three section containers (`EventDetailMeaningSection`, `EventDetailSajuSection`, `EventDetailInvestSection`) and the action-buttons container so VoiceOver groups each section as a logical unit.
   - Add a UI test (UI20) that enables VoiceOver and verifies `EventDetailTitleCard` is reachable before `EventDetailMeaningSection`, and `DisclaimerText` is last.

2. **Add view-binding UI test UI20** (and companion UI21 if needed) using custom launch arguments (consistent with existing `-mockEmptyInvestPerspectives` pattern in UI10):
   - Launch app with a custom meaning string (e.g., `-mockCustomMeaning "커스텀의미텍스트"`) and a custom learnCTAText (e.g., `-mockCustomLearnCTA "커스텀CTA텍스트"`).
   - Navigate to `EventDetailView`.
   - Assert `EventDetailMeaningText` label contains the custom meaning string.
   - Assert `EventDetailLearnButton` label equals the custom learnCTAText string.
   - This proves end-to-end binding: provider injection → view render.

## Resolved since previous iteration

*(Iteration 1 — no prior iterations)*

## Still outstanding from prior iterations

*(Iteration 1 — no prior iterations)*
