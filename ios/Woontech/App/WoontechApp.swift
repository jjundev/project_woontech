import SwiftUI

@main
struct WoontechApp: App {
    @StateObject private var store: OnboardingStore
    @StateObject private var sajuStore: SajuInputStore
    @StateObject private var homeDeps: HomeDependencies

    init() {
        let args = ProcessInfo.processInfo.arguments

        let overrideSeen = args.contains("-hasSeenOnboarding")
            && (args.firstIndex(of: "-hasSeenOnboarding").flatMap { idx -> String? in
                let next = idx + 1
                return next < args.count ? args[next] : nil
            } == "YES")

        let resetSeen = args.contains("-resetOnboarding")

        if resetSeen {
            UserDefaults.standard.removeObject(forKey: OnboardingStore.Keys.hasSeenOnboarding)
        }
        if overrideSeen {
            UserDefaults.standard.set(true, forKey: OnboardingStore.Keys.hasSeenOnboarding)
        }

        if args.contains("-resetSajuInput") {
            UserDefaults.standard.removeObject(forKey: SajuInputStore.Keys.userProfile)
        }

        let preloadedProfile: SajuInputModel? = {
            guard let idx = args.firstIndex(of: "-preloadedProfile"),
                  idx + 1 < args.count,
                  let data = args[idx + 1].data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(SajuInputModel.self, from: data)
        }()

        // Parse home mock launch args for UI tests
        let mockUnreadCount: Int? = {
            guard let idx = args.firstIndex(of: "-mockHomeUnreadCount"),
                  idx + 1 < args.count,
                  let count = Int(args[idx + 1]) else { return nil }
            return count
        }()

        let mockAvatarInitial: String? = {
            guard let idx = args.firstIndex(of: "-mockHomeAvatarInitial"),
                  idx + 1 < args.count else { return nil }
            return args[idx + 1]
        }()

        // Parse Hero mock launch args for UI tests
        let mockHeroScore: Int? = {
            guard let idx = args.firstIndex(of: "-mockHeroScore"),
                  idx + 1 < args.count,
                  let score = Int(args[idx + 1]) else { return nil }
            return score
        }()

        let mockHeroDisplayName: String? = {
            guard let idx = args.firstIndex(of: "-mockHeroDisplayName"),
                  idx + 1 < args.count else { return nil }
            return args[idx + 1]
        }()

        let mockHeroDate: Date? = {
            guard let idx = args.firstIndex(of: "-mockHeroDate"),
                  idx + 1 < args.count else { return nil }
            // Accept ISO-8601 date-only strings like "2026-01-01"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: args[idx + 1])
        }()

        _store = StateObject(wrappedValue: OnboardingStore())
        _sajuStore = StateObject(wrappedValue: SajuInputStore(preload: preloadedProfile))

        // Parse Today detail mock launch args for UI tests
        let todayHapchungEmpty = args.contains("-mockTodayHapchungEmpty")
        let todayMottoTabooOn = args.contains("-mockTodayMottoTabooOn")

        // Build HomeDependencies, applying any mock overrides from launch args
        let resolvedDeps: HomeDependencies
        let hasAnyMockArg = mockUnreadCount != nil || mockAvatarInitial != nil
            || mockHeroScore != nil || mockHeroDisplayName != nil || mockHeroDate != nil
            || todayHapchungEmpty || todayMottoTabooOn
        if hasAnyMockArg {
            let userProfile: any UserProfileProviding = {
                let name = mockHeroDisplayName ?? "홍길동"
                if let initial = mockAvatarInitial {
                    return MockUserProfileProvider(displayName: name, avatarInitial: initial)
                }
                return MockUserProfileProvider(displayName: name, avatarInitial: String(name.prefix(1)))
            }()
            let notificationCenter: any NotificationCenterProviding = {
                if let count = mockUnreadCount {
                    return MockNotificationCenterProvider(unreadCount: count)
                }
                return MockNotificationCenterProvider()
            }()
            let heroInvesting: any HeroInvestingProviding = {
                MockHeroInvestingProvider(
                    score: mockHeroScore ?? 72,
                    oneLiner: "공격보다 관찰이 내 성향에 맞아요",
                    displayDate: mockHeroDate ?? {
                        var comps = DateComponents()
                        comps.year = 2026; comps.month = 4; comps.day = 23
                        return Calendar.current.date(from: comps) ?? Date()
                    }()
                )
            }()
            let todayDetail: any TodayDetailProviding = {
                if todayHapchungEmpty && todayMottoTabooOn {
                    return MockTodayDetailProvider(
                        hapchungEvents: [],
                        dailyMotto: "오늘의 한마디 예시",
                        dailyTaboo: "금기 예시"
                    )
                }
                if todayHapchungEmpty {
                    return MockTodayDetailProvider(hapchungEvents: [])
                }
                if todayMottoTabooOn {
                    return MockTodayDetailProvider(
                        dailyMotto: "오늘의 한마디 예시",
                        dailyTaboo: "금기 예시"
                    )
                }
                return MockTodayDetailProvider()
            }()
            resolvedDeps = HomeDependencies(
                userProfile: userProfile,
                notificationCenter: notificationCenter,
                heroInvesting: heroInvesting,
                todayDetail: todayDetail
            )
        } else {
            resolvedDeps = HomeDependencies.mock
        }
        _homeDeps = StateObject(wrappedValue: resolvedDeps)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(sajuStore)
                .environmentObject(homeDeps)
                .onAppear {
                    applySajuStartStep()
                    applySignedInFlag()
                }
        }
    }

    private func applySajuStartStep() {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-sajuStartStep"),
              idx + 1 < args.count,
              let step = Int(args[idx + 1]),
              let target = SajuStep(rawValue: step) else { return }
        sajuStore.flow.currentStep = target
        // If jumping to result/referral, ensure there is a result to render.
        if target == .result || target == .referral {
            sajuStore.runAnalysis()
        }
    }

    private func applySignedInFlag() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-signedIn") {
            sajuStore.setSignedInForTesting(true)
        }
        if args.contains("-notSignedIn") {
            sajuStore.setSignedInForTesting(false)
        }
    }
}
