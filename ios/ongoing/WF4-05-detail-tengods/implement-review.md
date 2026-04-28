# Implementation Review
## WF4-05 — 십성 분석 상세 (Iteration 1)

---

## Checklist status (all ✓)

### Requirements
- ✓ R1 (AC#1): `SajuNavPush_tenGods` hidden button exists in `SajuTabView`; `SajuRouteDestinations.swift` maps `.tenGods` → `SajuTenGodsDetailView`.
- ✓ R2 (AC#2): NavBar title `"십성 분석"` with `.navigationBarTitleDisplayMode(.inline)` and `.toolbar(.visible, for: .navigationBar)`. Back button is standard NavigationStack behavior.
- ✓ R3 (AC#3): `TenGodsSummaryCard` binds `provider.summaryHeadline` → `Text(headline)` and `provider.summaryBody` → `Text(bodyText)`. Identifiers `TenGodsSummaryHeadline` / `TenGodsSummaryBody` on leaf `Text` views.
- ✓ R4 (AC#4): `sortedTenGodGroups(_:)` canonically sorts to `[비겁, 식상, 재성, 관성, 인성]` using name-matching compactMap.
- ✓ R5 (AC#5): `if group.isCore { Text("핵심")... }` renders badge with `DesignTokens.coreBadgeBg` background and `.accessibilityIdentifier("TenGodsCoreBadge_\(group.name)")`.
- ✓ R6 (AC#6): `isAbsent` → "부재 ⚠" in `DesignTokens.absentRed`; bar fill uses `DesignTokens.line2` (muted/absent tone).
- ✓ R7 (AC#7): `tenGodsFillRatio(total:)` = `min(CGFloat(total) / 3.0, 1.0)`. Verified by T15–T18.
- ✓ R8 (AC#8): `displayedItems(items:counts:)` joins items where `count > 0` with `" · "`; returns `"—"` when all zero. Verified by T19–T21.
- ✓ R9 (AC#9): `validateGroups(_:) throws`, `validateGroupLengths(_:) throws`, plus `precondition` double-guard in `sortedTenGodGroups`. Verified by T23–T24.
- ✓ R10 (AC#10): `TenGodsCoreSection` precondition-validates `topThree.count == 3` via `validateTopThree`. First card uses `DesignTokens.gray` background and `DesignTokens.line2` border (others `.bg` / `line3`). Verified by T25.
- ✓ R11 (AC#11): `TenGodsCoreCard` binds `name`, `han`, `count`, `meaning`, `investImplication`. Mock defaults: 정재×2, 비견×1, 정인×1. Verified by T10.
- ✓ R12 (AC#12): `TenGodsAbsentWarningCard` has `DesignTokens.absentRed` 1pt stroke; copy `Text` has `DesignTokens.absentRedLight` background and identifier `TenGodsAbsentWarningCopy`.
- ✓ R13 (AC#13): `if let warning = provider.absentWarning` conditional render. Verified by T27.
- ✓ R14 (AC#14): `TenGodsLearnEntryCard` tap calls `onNavigate(.lesson(id: entry.lessonId))`. `SajuTabView` passes `{ r in navigationPath.append(r) }`.
- ✓ R15 (AC#15): `if let entry = provider.learnEntry` conditional render. Verified by T29.
- ✓ R16 (AC#16): `DisclaimerView()` is the last item in the `VStack` inside the `ScrollView`.
- ✓ R17 (AC#17): `SajuTenGodsDetailProviding` is a standalone protocol; `MockSajuTenGodsDetailProvider` is unrelated to `MockSajuCategoriesProvider` / `MockSajuElementsDetailProvider`. Verified by T1–T2, T30.
- ✓ R18 (AC#18): VoiceOver accessibility labels match spec: group rows include "핵심, " / "부재 경고, " prefix; core cards label is "{name} {han}, {count}회, {meaning}. 투자 함의: {investImplication}"; absent warning is "주의, 부재 십성, {groupTitle}. {copy}"; learn card is "레슨 진입, {title}, {durationLabel}, {levelLabel}".
- ✓ R19 (AC#19): `.fixedSize(horizontal: false, vertical: true)` applied to `TenGodsInvestImplication` text and `TenGodsAbsentWarningCopy` text, allowing vertical wrap at XL Dynamic Type.

### Implementation Steps
- ✓ S1: `DesignTokens.coreBadgeBg`, `.absentRed`, `.absentRedLight` added.
- ✓ S2: `TenGodGroup`, `CoreTenGod`, `AbsentWarning`, `LearnEntry` structs + `SajuTenGodsDetailProviding` protocol (6 properties, `summaryLine` removed) + `MockSajuTenGodsDetailProvider` full re-write.
- ✓ S3: `sortedTenGodGroups`, `validateGroups`, `validateGroupLengths`, `validateTopThree`, `TenGodsValidationError` all in `SajuTenGodsDetailView.swift`.
- ✓ S4: `TenGodsSummaryCard` with correct identifiers and NavBar title.
- ✓ S5: `TenGodsGroupRow` + `TenGodsDistributionCard` with all specified identifiers including `TenGodsDisplayedItems_{name}` and `TenGodsCoreBadge_{name}`.
- ✓ S6: `TenGodsCoreCard` + `TenGodsCoreSection` with `TenGodsCoreCard_{index}` and `TenGodsInvestImplication_{index}`.
- ✓ S7: `TenGodsAbsentWarningCard` with `TenGodsAbsentWarningCopy` identifier on copy box `Text`.
- ✓ S8: `TenGodsLearnEntryCard` (Button) with `onNavigate` callback; `SajuTenGodsDetailView` has `onNavigate: (SajuRoute) -> Void` parameter.
- ✓ S9: Full `ScrollView > VStack(spacing: 10)` layout in correct order with `padding(.horizontal, 16)` + `padding(.vertical, 16)` + `DesignTokens.bg` background.
- ✓ S10 (Option A): `sajuRouteDestination(for:deps:onNavigate:)` updated with `onNavigate` parameter; `SajuTabView` passes `{ r in navigationPath.append(r) }`.
- ✓ S11: `SajuTenGodsDetailViewTests.swift` — 30 tests covering Groups A–H.
- ✓ S12: `SajuTenGodsDetailUITests.swift` — T31–T59; launch args `-sajuTenGodsNoAbsentWarning` / `-sajuTenGodsNoLearnEntry` handled in `WoontechApp.swift`.

### Project file membership
- ✓ `SajuTenGodsDetailView.swift`: `PBXFileReference` (A0010806) + `PBXBuildFile` (B0010803) in Woontech Sources.
- ✓ `SajuTenGodsDetailViewTests.swift`: `PBXFileReference` (A0010807) + `PBXBuildFile` (B0010804) in WoontechTests Sources.
- ✓ `SajuTenGodsDetailUITests.swift`: `PBXFileReference` (A0010808) + `PBXBuildFile` (B0010805) in WoontechUITests Sources.

### Accessibility contract
- `SajuTenGodsDetailView` root: `Color.clear` leaf-marker pattern (1×1 overlay, `.accessibilityIdentifier("SajuTenGodsDetailView")`). ✓
- All container cards (`TenGodsSummaryCard`, `TenGodsDistributionCard`, `TenGodsCoreSection`, `TenGodsAbsentWarningCard`) use `.accessibilityElement(children: .contain)` + `.accessibilityIdentifier(...)`. ✓
- `TenGodsGroupRow` uses `.accessibilityElement(children: .contain)` + `.accessibilityLabel(...)` + `.accessibilityIdentifier(...)`. Child texts `TenGodsDisplayedItems_{name}` and `TenGodsCoreBadge_{name}` remain accessible under `.contain`. ✓
- `TenGodsCoreCard` uses `.accessibilityElement(children: .contain)` + `.accessibilityLabel(...)` + `.accessibilityIdentifier(...)`. Child `TenGodsInvestImplication_{index}` is a `staticText` (XCTest `app.staticTexts["TenGodsInvestImplication_0"]`). ✓
- `TenGodsLearnEntryCard` is a `Button` — queried as `app.buttons["TenGodsLearnEntryCard"]`. ✓
- No `TabView` child received a direct `.accessibilityIdentifier(...)` — no identifier-shadowing risk. ✓

---

## Build / Test results

**Build:** Passed (exit 0, no errors).

**Unit tests:**
```
Total: 32, Passed: 32, Failed: 0, Skipped: 0
result: Passed
```
(From `.harness/test-results/last-unit-summary.txt`, bundle: Test-Woontech-unit-20260428-123855-5345-1777347535886773000.xcresult)

Suites run:
- `WoontechTests/SajuTenGodsDetailViewTests` — 30 tests (Groups A–H, T1–T30): all passed.
- `WoontechTests/SajuTabDependenciesTests` — 2 tests: all passed.

**UI tests:** Not run in this reviewer phase. The harness runs them in a dedicated verification gate after IMPLEMENT_PASS. `last-ui-summary.txt` is absent as expected for iteration 1.

---

## Notes

1. `let _ = { try? validateTopThree(...); precondition(...) }()` in `TenGodsCoreSection.body` is the established double-defense pattern for `@ViewBuilder` contexts and compiles correctly.
2. `MockSajuTenGodsDetailProvider.defaultGroups` / `defaultTopThree` / `defaultAbsentWarning` / `defaultLearnEntry` are exposed as `static let` — correctly referenced by `StubTenGodsDetailProvider` in the test file.
3. Launch-arg handling (`-sajuTenGodsNoAbsentWarning`, `-sajuTenGodsNoLearnEntry`) is implemented in `WoontechApp.swift` and injects the appropriate `MockSajuTenGodsDetailProvider` variant into `SajuTabDependencies`.
4. `summaryLine` has been fully removed from `SajuTenGodsDetailProviding` and `MockSajuTenGodsDetailProvider`; no stale references found in the codebase.
