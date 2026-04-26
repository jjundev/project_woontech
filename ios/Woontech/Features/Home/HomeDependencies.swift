import Foundation

final class HomeDependencies: ObservableObject {
    var userProfile: any UserProfileProviding
    var notificationCenter: any NotificationCenterProviding
    var heroInvesting: any HeroInvestingProviding
    var insights: any InsightsProviding
    var weeklyEvents: any WeeklyEventsProviding
    var investingAttitudeDetail: any InvestingAttitudeDetailProviding
    var todayDetail: any TodayDetailProviding
    var eventDetail: any EventDetailProviding

    init(
        userProfile: any UserProfileProviding = MockUserProfileProvider(),
        notificationCenter: any NotificationCenterProviding = MockNotificationCenterProvider(),
        heroInvesting: any HeroInvestingProviding = MockHeroInvestingProvider(),
        insights: any InsightsProviding = MockInsightsProvider(),
        weeklyEvents: any WeeklyEventsProviding = MockWeeklyEventsProvider(),
        investingAttitudeDetail: any InvestingAttitudeDetailProviding = MockInvestingAttitudeDetailProvider(),
        todayDetail: any TodayDetailProviding = MockTodayDetailProvider(),
        eventDetail: (any EventDetailProviding)? = nil
    ) {
        self.userProfile = userProfile
        self.notificationCenter = notificationCenter
        self.heroInvesting = heroInvesting
        self.insights = insights
        self.weeklyEvents = weeklyEvents
        self.investingAttitudeDetail = investingAttitudeDetail
        self.todayDetail = todayDetail
        self.eventDetail = eventDetail ?? HomeDependencies.buildEventDetailProvider()
    }

    static let mock = HomeDependencies()

    // MARK: - Launch-arg–aware event detail provider factory

    private static func buildEventDetailProvider() -> any EventDetailProviding {
        let args = ProcessInfo.processInfo.arguments
        let base = MockEventDetailProvider()

        var meaning = base.meaning
        var sajuRelationFormula = base.sajuRelationFormula
        let sajuRelationNote = base.sajuRelationNote
        var investPerspectives = base.investPerspectives
        var learnCTAText = base.learnCTAText

        if let idx = args.firstIndex(of: "-mockCustomMeaning"), idx + 1 < args.count {
            meaning = args[idx + 1]
        }
        if let idx = args.firstIndex(of: "-mockCustomLearnCTA"), idx + 1 < args.count {
            learnCTAText = args[idx + 1]
        }
        if let idx = args.firstIndex(of: "-mockCustomSajuFormula"), idx + 1 < args.count {
            sajuRelationFormula = args[idx + 1]
        }
        if args.contains("-mockEmptyInvestPerspectives") {
            investPerspectives = []
        }

        return MockEventDetailProvider(
            meaning: meaning,
            sajuRelationFormula: sajuRelationFormula,
            sajuRelationNote: sajuRelationNote,
            investPerspectives: investPerspectives,
            learnCTAText: learnCTAText
        )
    }
}
