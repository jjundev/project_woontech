import XCTest
@testable import Woontech

final class OnboardingStoreTests: XCTestCase {

    private var suiteName: String!
    private var suite: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "OnboardingStoreTests-\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)
        suite.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: suiteName)
        suite = nil
        suiteName = nil
        super.tearDown()
    }

    func test_default_hasSeenOnboarding_isFalse() {
        let store = OnboardingStore(defaults: suite)
        XCTAssertFalse(store.hasSeenOnboarding)
    }

    func test_markSeen_setsFlagTrue_andPersists() {
        let store = OnboardingStore(defaults: suite)
        store.markSeen()

        XCTAssertTrue(store.hasSeenOnboarding)
        XCTAssertTrue(suite.bool(forKey: OnboardingStore.Keys.hasSeenOnboarding))

        let rehydrated = OnboardingStore(defaults: suite)
        XCTAssertTrue(rehydrated.hasSeenOnboarding)
    }

    func test_reset_clearsFlag() {
        let store = OnboardingStore(defaults: suite)
        store.markSeen()
        store.reset()

        XCTAssertFalse(store.hasSeenOnboarding)
        XCTAssertFalse(suite.bool(forKey: OnboardingStore.Keys.hasSeenOnboarding))
    }
}
