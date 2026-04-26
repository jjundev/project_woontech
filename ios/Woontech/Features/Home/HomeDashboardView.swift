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

    private var showsUITestNavigationTriggers: Bool {
        ProcessInfo.processInfo.arguments.contains("-openHome")
    }

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
                    case .event(let event):
                        EventDetailView(
                            event: event,
                            provider: homeDeps.eventDetail,
                            onShareTap: {},
                            onBellReminderTap: {},
                            onAddToCalendarTap: {},
                            onLearnTap: {}
                        )
                    case .today:
                        TodayDetailView(provider: homeDeps.todayDetail)
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
            if showsUITestNavigationTriggers {
                VStack(spacing: 0) {
                    uiTestNavigationButton("HomeNavPushInvesting") {
                        navigationPath.append(.investing)
                    }

                    uiTestNavigationButton("HomeNavPushEvent") {
                        navigationPath.append(.event(MockWeeklyEventsProvider().events()[0]))
                    }

                    uiTestNavigationButton("HomeNavPushToday") {
                        navigationPath.append(.today)
                    }

                    uiTestNavigationButton("HomeNavPushTaboo") {
                        navigationPath.append(.tabooPlaceholder)
                    }

                    uiTestNavigationButton("HomeNavPushPractice") {
                        navigationPath.append(.practicePlaceholder)
                    }
                }
            }
        }
    }

    private func uiTestNavigationButton(
        _ identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Color.black.opacity(0.001)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(identifier)
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
