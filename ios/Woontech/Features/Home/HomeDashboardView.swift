import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var homeDeps: HomeDependencies
    @State private var navigationPath: [HomeRoute] = []
    @State private var bellTapCount = 0
    @State private var avatarTapCount = 0
    @State private var calendarTapCount = 0
    @State private var sharePreviewTapCount = 0
    @State private var shareTapCount = 0
    @State private var proTrialTapCount = 0

    var body: some View {
        VStack(spacing: 0) {
            HomeHeaderView(
                userProfile: homeDeps.userProfile,
                notificationCenter: homeDeps.notificationCenter,
                onBellTap: { bellTapCount += 1 },
                onAvatarTap: { avatarTapCount += 1 }
            )

            Rectangle()
                .fill(DesignTokens.headerBorder)
                .frame(height: 1)

            NavigationStack(path: $navigationPath) {
                ScrollView {
                    VStack(spacing: 0) {
                        HeroInvestingCardView(
                            provider: homeDeps.heroInvesting,
                            userProfile: homeDeps.userProfile,
                            onTap: { navigationPath.append(.investing) }
                        )

                        InsightsScrollView(
                            provider: homeDeps.insights,
                            onTabooTap: { navigationPath.append(.tabooPlaceholder) },
                            onTodayTap: { navigationPath.append(.today) },
                            onPracticeTap: { navigationPath.append(.practicePlaceholder) }
                        )

                        WeeklyEventsSection(
                            provider: homeDeps.weeklyEvents,
                            onCalendarTap: { calendarTapCount += 1 },
                            onEventTap: { event in navigationPath.append(.event(event)) }
                        )

                        ShareHookCard(
                            onSharePreviewTap: { sharePreviewTapCount += 1 },
                            onShareTap: { shareTapCount += 1 }
                        )

                        ProTeaserCard(
                            provider: homeDeps.weeklyEvents,
                            onProTrialTap: { proTrialTapCount += 1 }
                        )

                        DisclaimerView()
                            .padding(.top, 12)
                            .padding(.bottom, 65)
                    }
                    .accessibilityIdentifier("HomeDashboardContent")
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .investing:
                        InvestingAttitudeDetailView(provider: homeDeps.investingAttitudeDetail)
                    case .event:
                        EventPlaceholderView()
                    case .today:
                        TodayPlaceholderView()
                    case .tabooPlaceholder:
                        TabooPlaceholderView()
                    case .practicePlaceholder:
                        PracticePlaceholderView()
                    }
                }
            }

            HomeTabBarPlaceholderView()
                .accessibilityIdentifier("HomeTabBarPlaceholder")
        }
        .accessibilityIdentifier("HomeDashboardRoot")
        // Spy counters: opacity 0 so invisible, but readable by XCUITest via accessibilityIdentifier
        .overlay(alignment: .topLeading) {
            VStack(spacing: 0) {
                Text("\(bellTapCount)")
                    .accessibilityIdentifier("HomeBellTapCount")
                Text("\(avatarTapCount)")
                    .accessibilityIdentifier("HomeAvatarTapCount")
                Text("\(calendarTapCount)")
                    .accessibilityIdentifier("HomeCalendarTapCount")
                Text("\(sharePreviewTapCount)")
                    .accessibilityIdentifier("HomeSharePreviewTapCount")
                Text("\(shareTapCount)")
                    .accessibilityIdentifier("HomeShareTapCount")
                Text("\(proTrialTapCount)")
                    .accessibilityIdentifier("HomeProTrialTapCount")
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
        // Hidden push trigger buttons for UI tests (AC-10)
        .overlay(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                Button {
                    navigationPath.append(.investing)
                } label: {
                    Rectangle().fill(Color.clear).frame(width: 1, height: 1)
                }
                .accessibilityIdentifier("HomeNavPushInvesting")
                .opacity(0)

                Button {
                    navigationPath.append(.event(MockWeeklyEventsProvider().events()[0]))
                } label: {
                    Rectangle().fill(Color.clear).frame(width: 1, height: 1)
                }
                .accessibilityIdentifier("HomeNavPushEvent")
                .opacity(0)

                Button {
                    navigationPath.append(.today)
                } label: {
                    Rectangle().fill(Color.clear).frame(width: 1, height: 1)
                }
                .accessibilityIdentifier("HomeNavPushToday")
                .opacity(0)

                Button {
                    navigationPath.append(.tabooPlaceholder)
                } label: {
                    Rectangle().fill(Color.clear).frame(width: 1, height: 1)
                }
                .accessibilityIdentifier("HomeNavPushTaboo")
                .opacity(0)

                Button {
                    navigationPath.append(.practicePlaceholder)
                } label: {
                    Rectangle().fill(Color.clear).frame(width: 1, height: 1)
                }
                .accessibilityIdentifier("HomeNavPushPractice")
                .opacity(0)
            }
        }
    }
}

// MARK: - Private sub-views

private struct HomeTabBarPlaceholderView: View {
    var body: some View {
        Rectangle()
            .fill(Color(.systemBackground))
            .frame(height: 49)
            .overlay(alignment: .top) { Divider() }
    }
}
