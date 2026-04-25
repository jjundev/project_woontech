import Foundation

final class HomeDependencies: ObservableObject {
    var userProfile: any UserProfileProviding
    var notificationCenter: any NotificationCenterProviding
    var heroInvesting: any HeroInvestingProviding
    var insights: any InsightsProviding
    var weeklyEvents: any WeeklyEventsProviding
    var investingAttitudeDetail: any InvestingAttitudeDetailProviding
    var todayDetail: any TodayDetailProviding

    init(
        userProfile: any UserProfileProviding = MockUserProfileProvider(),
        notificationCenter: any NotificationCenterProviding = MockNotificationCenterProvider(),
        heroInvesting: any HeroInvestingProviding = MockHeroInvestingProvider(),
        insights: any InsightsProviding = MockInsightsProvider(),
        weeklyEvents: any WeeklyEventsProviding = MockWeeklyEventsProvider(),
        investingAttitudeDetail: any InvestingAttitudeDetailProviding = MockInvestingAttitudeDetailProvider(),
        todayDetail: any TodayDetailProviding = MockTodayDetailProvider()
    ) {
        self.userProfile = userProfile
        self.notificationCenter = notificationCenter
        self.heroInvesting = heroInvesting
        self.insights = insights
        self.weeklyEvents = weeklyEvents
        self.investingAttitudeDetail = investingAttitudeDetail
        self.todayDetail = todayDetail
    }

    static let mock = HomeDependencies()
}
