# Implementation Checklist — WF3-03 홈 below-the-fold

## Requirements (from spec)

- [ ] R1: HomeDashboardView content is a single vertical ScrollView containing above-fold (WF3-02) and below-fold sections in continuous scroll
- [ ] R2: Section 7 (이번 주 흐름) header with title, subtitle "다가올 절기·대운 이벤트", and "캘린더 보기 ›" button
- [ ] R3: TimeGroup dividers render in fixed order: "이번 주" → "이번 달" → "3개월 이내"
- [ ] R4: Empty timeGroup groups hide both divider and card area
- [ ] R5: Event cards display icon (emoji) + bold title + optional "중요" badge + D-day badge (top-right) + oneLiner + date text + gray investContext box
- [ ] R6: Negative impact cards show red border + left 3pt accent bar + red D-day badge
- [ ] R7: Positive impact cards with badge="중요" show "중요" pill; others hide badge
- [ ] R8: Event card tap appends HomeRoute.event(event) to navigation path
- [ ] R9: Section 8 (공유 훅) card with 💌 icon + title + description + "카드 미리보기" & "공유하기" buttons
- [ ] R10: Section 9 (PRO 티저) card with 🔒 icon + title + feature bullet list + "7일 무료 체험 →" button
- [ ] R11: Feature bullets count matches provider array length; 0 length hides bullet area
- [ ] R12: Disclaimer text "본 앱은 학습·참고용이며 투자 권유가 아닙니다…" at ScrollView bottom
- [ ] R13: Bottom padding = tabBar height (49pt) + 16pt
- [ ] R14: WeeklyEvent model in Woontech/Shared/Models/ with all fields: id, type, icon, title, hanja?, dday, ddayDate, impact, oneLiner, investContext, badge?, timeGroup
- [ ] R15: EventType enum: daewoon, jeolgi, hapchung, special
- [ ] R16: Impact enum: positive, neutral, negative
- [ ] R17: TimeGroup enum: thisWeek ("이번 주"), thisMonth ("이번 달"), within3Months ("3개월 이내")
- [ ] R18: WeeklyEventsProviding protocol with func events() -> [WeeklyEvent] and func proFeatures() -> [String]
- [ ] R19: MockWeeklyEventsProvider returns 4 wireframe events (V6_EVENTS)
- [ ] R20: Dynamic Type Large support: text wrapping in event cards

## Implementation Steps

- [ ] S1: Create Woontech/Shared/Models/WeeklyEvent.swift with struct, enums (EventType, Impact, TimeGroup), Codable+Hashable+Identifiable
- [ ] S2: Update HomeRoute.swift to import WeeklyEvent from Shared/Models
- [ ] S3: Extend Woontech/Features/Home/Providers/WeeklyEventsProviding.swift with func events() and func proFeatures()
- [ ] S4: Implement MockWeeklyEventsProvider with 4 hardcoded events and 3 PRO features
- [ ] S5: Create Woontech/Features/Home/DisclaimerView.swift with WF2 disclaimer text and correct padding
- [ ] S6: Create Woontech/Features/Home/Views/EventCardView.swift with icon, title, badge, D-day, date, investContext box
- [ ] S6a: Implement conditional styling for negative impact (red border + 3pt accent bar + red D-day)
- [ ] S6b: Implement conditional "중요" badge (only impact=positive && badge="중요")
- [ ] S6c: Connect card tap to closure that appends HomeRoute.event(event)
- [ ] S7: Create Woontech/Features/Home/WeeklyEventsSection.swift with header, timeGroup dividers, event filtering
- [ ] S7a: Implement timeGroup order filtering ("이번 주" → "이번 달" → "3개월 이내")
- [ ] S7b: Hide empty timeGroup dividers and card areas
- [ ] S7c: Connect "캘린더 보기" button to onCalendarTap callback
- [ ] S8: Create Woontech/Features/Home/ShareHookCard.swift with 💌 icon, title, description, two buttons
- [ ] S8a: Connect "카드 미리보기" to onSharePreviewTap callback
- [ ] S8b: Connect "공유하기" to onShareTap callback
- [ ] S9: Create Woontech/Features/Home/ProTeaserCard.swift with 🔒 icon, title, bullet list, trial button
- [ ] S9a: Populate bullets from provider proFeatures() array
- [ ] S9b: Hide bullet area if proFeatures() returns empty array
- [ ] S9c: Connect "7일 무료 체험 →" to onProTrialTap callback
- [ ] S10: Extend HomeDashboardView.swift ScrollView VStack with all 6 sections in order (Hero → Insights → Weekly → Share → PRO → Disclaimer)
- [ ] S10a: Add @State counters for spy testing (calendarTapCount, sharePreviewTapCount, shareTapCount, proTrialTapCount)
- [ ] S10b: Connect all callbacks to increment respective counters
- [ ] S10c: Expose counters via opacity=0 Text with accessibility identifiers for test access
- [ ] S11: Add accessibility identifiers to all views for testing (e.g., "WeeklyEventsSection", "EventCard_\(event.id)", "ShareHookCard", "ProTeaserCard")
- [ ] S12: Update HomeDependencies.swift to inject WeeklyEventsProviding

## Tests

### Unit Tests (WoontechTests/Home/HomeDashboardTests.swift)

- [ ] T1 (unit): WeeklyEvent initialization with default values
- [ ] T2 (unit): WeeklyEvent Hashable: same id = equal
- [ ] T3 (unit): WeeklyEvent Identifiable compliance
- [ ] T4 (unit): EventType enum cases decodable from String rawValue
- [ ] T5 (unit): Impact enum negative case identified
- [ ] T6 (unit): TimeGroup rawValue "이번 주" correct
- [ ] T7 (unit): MockWeeklyEventsProvider returns 4 events
- [ ] T8 (unit): MockWeeklyEventsProvider event 0 type=daewoon, title="대운 전환"
- [ ] T9 (unit): MockWeeklyEventsProvider event 1 timeGroup=thisWeek
- [ ] T10 (unit): MockWeeklyEventsProvider event 2 impact=negative
- [ ] T11 (unit): MockWeeklyEventsProvider event 3 timeGroup=thisMonth
- [ ] T12 (unit): MockWeeklyEventsProvider proFeatures() returns 3 items
- [ ] T13 (unit): MockWeeklyEventsProvider proFeatures()[0] == "6개월 흐름 리포트"
- [ ] T14 (unit): Filter events by timeGroup=thisWeek returns 2 events
- [ ] T15 (unit): Filter events by timeGroup=thisMonth returns 1 event
- [ ] T16 (unit): Filter events by timeGroup=within3Months returns 1 event
- [ ] T17 (unit): Filter empty array returns 0 events
- [ ] T18 (unit): Negative impact event has red border color
- [ ] T19 (unit): Negative impact event has 3pt left accent bar
- [ ] T20 (unit): Negative impact event has red D-day badge
- [ ] T21 (unit): Positive + badge="중요" shows badge
- [ ] T22 (unit): Positive + badge=nil hides badge
- [ ] T23 (unit): Neutral impact has normal styling (no red)
- [ ] T24 (unit): HomeRoute.event(event) is Hashable
- [ ] T25 (unit): HomeRoute equality based on event id

### UI Tests (WoontechUITests/Home/HomeDashboardUITests.swift)

- [ ] T26 (ui, AC-1): Single ScrollView contains all sections Hero → Insights → Weekly → Share → PRO → Disclaimer; all reachable via scroll
- [ ] T27 (ui, AC-2): TimeGroup dividers appear in order "이번 주" → "이번 달" → "3개월 이내"
- [ ] T28 (ui, AC-3): Mock with only thisMonth events hides "이번 주" and "3개월 이내" dividers; shows only "이번 달"
- [ ] T29 (ui, AC-4): Negative impact event (월지충) shows red border + left accent bar + red D-day
- [ ] T30 (ui, AC-5): Positive + badge="중요" event (대운 전환) shows "중요" badge; neutral (곡우) and negative (월지충) do not
- [ ] T31 (ui, AC-6): Tap event card (대운 전환) appends HomeRoute.event to navigationPath with correct event id
- [ ] T32 (ui, AC-6): Tap different event card (곡우) appends with correct event id
- [ ] T33 (ui, AC-7): Tap "카드 미리보기" button increments sharePreviewTapCount to 1
- [ ] T34 (ui, AC-7): Tap "공유하기" button increments shareTapCount to 1
- [ ] T35 (ui, AC-8): PRO teaser shows 3 feature bullets (default mock)
- [ ] T36 (ui, AC-8): Mock with empty proFeatures() array hides bullet area
- [ ] T37 (ui, AC-9): Tap "7일 무료 체험 →" button increments proTrialTapCount to 1
- [ ] T38 (ui, AC-10): Tap "캘린더 보기 ›" button increments calendarTapCount to 1
- [ ] T39 (ui, AC-11): Scroll to bottom of ScrollView reveals DisclaimerView above TabBar
- [ ] T40 (ui, AC-12): Mock with empty events array hides all dividers/cards; section header remains (or hidden per spec decision)
- [ ] T41 (ui, AC-13): At Dynamic Type XL (Accessibility Large), investContext text wraps without truncation

---

**Version:** 1  
**Date:** 2026-04-25  
**Plan Version Reference:** implement-plan.md v1
