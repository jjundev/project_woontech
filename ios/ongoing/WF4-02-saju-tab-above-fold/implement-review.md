# Implementation Review — WF4-02 사주 탭 Above-the-Fold

## Checklist status (all ✓)

### Requirements (spec AC 1–18)
- ✓ R1 (AC1): `SajuTabView` uses `SajuTabContentView` as root; Block A then Block B rendered in order.
- ✓ R2 (AC2): `displayOrder: [.hour, .day, .month, .year]` hardcoded in `SajuOriginCardView`.
- ✓ R3 (AC3): `MockUserSajuOriginProvider.defaultPillars` = 時庚申/日丙午/月辛卯/年庚午 — confirmed in `UserSajuOriginProviding.swift`.
- ✓ R4 (AC4): `isDayMaster ? DesignTokens.dayMasterHighlight : DesignTokens.bg` in `SajuPillarCellView`.
- ✓ R5 (AC5): `Text(provider.dayMasterLine)` with identifier `SajuDayMasterLine`.
- ✓ R6 (AC6): `precondition(provider.pillars.count == 4, ...)` in `SajuOriginCardView.body`.
- ✓ R7 (AC7): 5-slot fixed `displayOrder` in `SajuCategoriesSection`; nil lookup → "데이터 없음" placeholder card.
- ✓ R8 (AC8): `if let badge = summary.badge { ... }` conditional badge rendering; nil badge → no badge UI.
- ✓ R9–R13 (AC9–13): `route(for:)` maps `.elements`→`.elements`, `.tenGods`→`.tenGods`, `.daewoon`→`.daewoonPlaceholder`, `.hapchung`→`.hapchungPlaceholder`, `.yongsin`→`.yongsinPlaceholder`.
- ✓ R14 (AC14): "근거 보기" `Text` inside the category `Button` — single hit-test, no separate gesture needed.
- ✓ R15 (AC15): `onViewAll: { }` no-op; `.accessibilityHint("준비중")` on "전체 보기 ›" button.
- ✓ R16 (AC16): `.fixedSize(horizontal: false, vertical: true)` on category summary text.
- ✓ R17 (AC17): `.accessibilityAddTraits(isDayMaster ? [.isHeader] : [])` in `SajuPillarCellView`.
- ✓ R18 (AC18): `.frame(maxWidth: .infinity, minHeight: 44)` + `.contentShape(Rectangle())` on each category card.

### Implementation Steps (S0–S8)
- ✓ S0: Mock data verified — 4 pillars + dayMasterLine + 5 category slots with correct badge values.
- ✓ S1: `DesignTokens.dayMasterHighlight` (#D6D6D6) and `DesignTokens.dayMasterLineBg` (#F2F2F2) added.
- ✓ S2: `SajuPillarCellView` — `.accessibilityElement(children: .ignore)` + unified label + `.isHeader` trait.
- ✓ S3: `SajuOriginCardView` — precondition, pillarMap, identifiers (`SajuOriginCard`, `SajuOriginCardHeaderLabel`, `SajuOriginCardViewAllButton`, `SajuDayMasterLine`).
- ✓ S4: `SajuCategoryCardView` — Button wraps full card; badge conditional; `.contentShape(Rectangle())`; placeholder for nil.
- ✓ S5: `SajuCategoriesSection` — `displayOrder` + `route(for:)` + `SajuDetailSectionHeader` identifier.
- ✓ S6: `SajuTabContentView` — ScrollView with `.accessibilityElement(children: .contain)` + `SajuTabContent` identifier.
- ✓ S7: `SajuTabView` updated to use `SajuTabContentView`; WF4-01 T17 placeholder test has `throw XCTSkip(...)`.
- ✓ S8: All accessibility identifiers confirmed match the plan table.

### Unit Tests (T1–T19)
All 19 tests in `SajuAboveFoldTests` pass.

### pbxproj Target Membership
All 7 new `.swift` files confirmed in `Woontech.xcodeproj/project.pbxproj`:
- `SajuPillarCellView.swift` — PBXFileReference A0010700 + PBXBuildFile B0010700 ✓
- `SajuOriginCardView.swift` — PBXFileReference A0010701 + PBXBuildFile B0010701 ✓
- `SajuCategoryCardView.swift` — PBXFileReference A0010702 + PBXBuildFile B0010702 ✓
- `SajuCategoriesSection.swift` — PBXFileReference A0010703 + PBXBuildFile B0010703 ✓
- `SajuTabContentView.swift` — PBXFileReference A0010704 + PBXBuildFile B0010704 ✓
- `SajuAboveFoldTests.swift` — PBXFileReference A0010705 + PBXBuildFile B0010705 ✓
- `SajuAboveFoldUITests.swift` — PBXFileReference A0010706 + PBXBuildFile B0010706 ✓

### Accessibility Contract Audit
`SajuTabView.swift` was modified (NavigationStack root replaced), triggering a topology audit.

**Views reachable through the NavigationStack:**

| View | Identifier | `.accessibilityElement` | Status |
|---|---|---|---|
| `SajuTabContentView` (ScrollView) | `SajuTabContent` | `.contain` | ✓ |
| `SajuOriginCardView` (VStack) | `SajuOriginCard` | `.contain` | ✓ |
| `SajuPillarCellView` (VStack) | `SajuPillarCell_{pos}` | `.ignore` (leaf) | ✓ |
| `SajuCategoryCardView` (Button) | `SajuCategoryCard_{kind}` | Button node (interactive) | ✓ |
| `SajuPlaceholderDestinationView` (VStack) | `SajuPlaceholderDestination_{key}` | `.contain` | ✓ (WF4-01, unchanged) |

No identifier is attached directly to a `TabView` child. No container carrying an identifier is missing `.contain`. The `SajuPillarCellView` correctly uses `.ignore` (it is a leaf element with a unified accessibility label, not a container). All query types in `SajuAboveFoldUITests` match their SwiftUI element types (`otherElements` for VStack leaves, `staticTexts` for Text, `buttons` for Button, `scrollViews` for ScrollView).

## Build / Test results

**Build**: Succeeded (exit 0, no output).

**Unit tests** (`WoontechTests/SajuAboveFoldTests`, 19 tests):
```
Total: 19, Passed: 19, Failed: 0, Skipped: 0
result: "Passed"
```
Quoted from `.harness/test-results/last-unit-summary.txt`:
`"passedTests" : 19, "failedTests" : 0, "result" : "Passed", "totalTestCount" : 19`

**UI tests**: Not run in this phase; executed by the harness in the dedicated `ui_verify` gate.

## Notes

- WF4-01 T17 (`test_sajuContent_placeholderVisible`) is correctly `XCTSkip`'d in `SajuTabFoundationUITests.swift` with message `"WF4-02: SajuTabContentPlaceholderView replaced by SajuTabContentView"`.
- `SajuCategorySummary` already had a `title: String` property from WF4-01, so no extension was needed.
- `SajuCategoriesSection.route(for:)` and `displayOrder` are non-private, enabling direct unit-test access without SwiftUI rendering.
- `MockUserSajuOriginProvider` accepts a `pillars: []` injection (TA-08) to document the precondition contract without triggering fatalError in the test runner.
