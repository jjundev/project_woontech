# Plan Feedback v1

## Problems

### P1 — Pill horizontal scroll double-padding (Step 3 vs Step 6 body structure conflict)

**Severity: High** — would produce an incorrect layout if coded as written.

Step 6's body structure applies `.padding(.horizontal, 16)` to the entire outer `VStack`, which contains `SajuLearnCategoryPillsView`. Because the PillsView wraps a `ScrollView(.horizontal)`, that scrollable area is constrained to `screen_width − 32 pt`. If the HStack inside the ScrollView then also applies leading padding (per Risk 8's own recommendation), the first pill starts 32 pt from the screen edge instead of the required 16 pt.

Step 3 says "좌우 16pt 패딩은 부모(`SajuLearnListView`)가 제공", and Risk 8 says to put internal padding inside the HStack — but these two statements are contradictory given the body structure shown. There is no consistent resolution.

**Required fix:** Extract the pill strip from the globally padded `VStack`. The outer ScrollView body should use two sibling `VStack`s (or a plain `VStack` at the top level without a global `.padding(.horizontal, 16)`): the pill strip block at full width, and all other content in a sub-`VStack` with `.padding(.horizontal, 16)`. Step 3 must also clarify that `SajuLearnCategoryPillsView`'s internal HStack uses `.padding(.leading, 16)` / `.padding(.trailing, 16)` (not the parent) to create the visual margins.

---

### P2 — Missing launch-argument for TU-L12 (`-sajuStreakDays 0`)

**Severity: Medium** — TU-L12 (`test_weeklyBanner_streakBadge_hidden_streakDays0`) requires the app to launch with `streakDays = 0`, but Step 8 only adds `-sajuLearnArticlesEmpty` to `WoontechApp.swift`. No `-sajuStreakDays` (or equivalent boolean `-sajuLearnStreakZero`) parsing is specified anywhere in the implementation steps, making TU-L12 unimplementable as written.

**Required fix:** Add a `-sajuLearnStreakZero` launch argument to Step 8 (alongside `-sajuLearnArticlesEmpty`), and wire it so `MockSajuLearningPathProvider` is instantiated with `streakDays = 0` when that flag is present.

---

## Required Changes

1. **Step 3** — Revise the `SajuLearnCategoryPillsView` description to state explicitly: "부모로부터 horizontal padding을 받지 않으며, 내부 `HStack`에 `.padding(.leading, 16).padding(.trailing, 16)`을 직접 적용한다."

2. **Step 6 body structure** — Restructure the `ScrollView` body so the pill strip sits outside the `.padding(.horizontal, 16)` block. Concretely:
   ```
   ScrollView {
       VStack(alignment: .leading, spacing: 0) {
           // 1. 카테고리 pill — full-width (no horizontal padding from parent)
           SajuLearnCategoryPillsView(...)
               .padding(.top, 12)

           // 2-5. Everything else — 16pt horizontal padding
           VStack(alignment: .leading, spacing: 0) {
               SajuWeeklyProgressBannerView(...)
                   .padding(.top, 12)
               CourseHeaderView(...)
                   .padding(.top, 18)
               VStack(spacing: 6) { /* lesson cards */ }
                   .padding(.top, 8)
               if !provider.recommendedArticles.isEmpty {
                   ArticlesSectionView(...)
                       .padding(.top, 18)
               }
           }
           .padding(.horizontal, 16)
           .padding(.bottom, 32)
       }
   }
   ```

3. **Step 8** — Add `-sajuLearnStreakZero` argument parsing: when present, `MockSajuLearningPathProvider` is built with `weeklyProgress` having `streakDays = 0`. Update the UI-test launch-arg table accordingly.

4. **TU-L12 in §6** — Update the launch argument from `-sajuStreakDays 0` to `-sajuLearnStreakZero` (consistent with the naming convention already established by `-sajuLearnArticlesEmpty`).

---

## Resolved since previous iteration

*(none — iteration 1)*

## Still outstanding from prior iterations

*(none — iteration 1)*
