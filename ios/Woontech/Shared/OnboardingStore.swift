import Foundation
import Combine

final class OnboardingStore: ObservableObject {
    enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    private let defaults: UserDefaults

    @Published private(set) var hasSeenOnboarding: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
    }

    func markSeen() {
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        hasSeenOnboarding = true
    }

    func reset() {
        defaults.removeObject(forKey: Keys.hasSeenOnboarding)
        hasSeenOnboarding = false
    }
}
