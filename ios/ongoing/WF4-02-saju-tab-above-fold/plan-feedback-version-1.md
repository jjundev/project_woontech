# Plan Feedback v1

## Problems

### P1 — Missing `accessibilityIdentifier("SajuOriginCardHeaderLabel")` in Step 3 implementation code

Step 3's layout pseudocode for `SajuOriginCardView` shows:
```swift
Text("내 사주 원국")  // 12pt muted
```
with no identifier modifier. However, Step 8's identifier table correctly lists
`"SajuOriginCardHeaderLabel"` for this element, and UI test TU-02 queries
`staticTexts["SajuOriginCardHeaderLabel"]` to verify the label text. An implementer
following Step 3's code verbatim will omit the modifier, causing TU-02 to fail.

### P2 — Mock provider data implementation not addressed

The spec explicitly states:
> "이 슬라이스는 WF4-01에서 시그니처만 선언된 `UserSajuOriginProviding`·`SajuCategoriesProviding`의
> mock 구현과 데이터 바인딩을 완성한다."

Completing the mock implementation is the primary mandate of this slice. However,
Section 3-2 marks `MockUserSajuOriginProvider` and `MockSajuCategoriesProvider` as
"수정 없음", and the affected-files table (Section 2) lists no file for mock data.
No implementation step tells the developer to verify or populate the required
default values (時庚申/日丙午/月辛卯/年庚午, specific dayMasterLine, 5 category
summaries with exact badge values). If WF4-01 left these mocks as stubs or with
empty/placeholder data, unit tests TA-02 through TA-07 and TA-15/TA-16 will fail
with no plan guidance for the developer to fix them.

## Required Changes

1. In Step 3 (`SajuOriginCardView`), add `.accessibilityIdentifier("SajuOriginCardHeaderLabel")`
   to the `Text("내 사주 원국")` line in the layout code.

2. Add a "Step 0 — Verify/implement mock provider data" before Step 1, instructing
   the developer to:
   - Open `UserSajuOriginProviding.swift` and confirm `MockUserSajuOriginProvider`
     returns the 4 correct pillars (時庚申/日丙午/月辛卯/年庚午) and the correct
     `dayMasterLine`.
   - Open `SajuCategoriesProviding.swift` and confirm `MockSajuCategoriesProvider`
     returns 5 categories with specified summaries and badges.
   - If the values are absent or placeholder, implement them in-place in the same
     files (no scope change — the mocks are already declared there).
   - Update the affected-files table accordingly (MODIFIED if changes are made).

## Resolved since previous iteration

*(Iteration 1 — no prior feedback.)*

## Still outstanding from prior iterations

*(Iteration 1 — no prior feedback.)*
