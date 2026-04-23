import SwiftUI

@main
struct WoontechApp: App {
    @StateObject private var store: OnboardingStore

    init() {
        let overrideSeen = ProcessInfo.processInfo.arguments.contains("-hasSeenOnboarding")
            && (ProcessInfo.processInfo.arguments.firstIndex(of: "-hasSeenOnboarding").flatMap { idx -> String? in
                let next = idx + 1
                return next < ProcessInfo.processInfo.arguments.count
                    ? ProcessInfo.processInfo.arguments[next]
                    : nil
            } == "YES")

        let resetSeen = ProcessInfo.processInfo.arguments.contains("-resetOnboarding")

        if resetSeen {
            UserDefaults.standard.removeObject(forKey: OnboardingStore.Keys.hasSeenOnboarding)
        }
        if overrideSeen {
            UserDefaults.standard.set(true, forKey: OnboardingStore.Keys.hasSeenOnboarding)
        }

        _store = StateObject(wrappedValue: OnboardingStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
