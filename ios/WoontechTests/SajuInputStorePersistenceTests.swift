import XCTest
@testable import Woontech

@MainActor
final class SajuInputStorePersistenceTests: XCTestCase {

    private func makeInMemoryDefaults() -> UserDefaults {
        let suite = "saju.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    // T28 — NFC-6
    func test_store_persist_writesUserProfileJSON() {
        let defaults = makeInMemoryDefaults()
        let store = SajuInputStore(defaults: defaults)
        store.input.name = "민주"
        store.input.gender = .male
        store.persist()

        let data = defaults.data(forKey: SajuInputStore.Keys.userProfile)
        XCTAssertNotNil(data, "userProfile must be written to UserDefaults")
        let decoded = try? JSONDecoder().decode(SajuInputModel.self, from: data!)
        XCTAssertEqual(decoded?.name, "민주")
        XCTAssertEqual(decoded?.gender, .male)
    }

    // T29 — NFC-6
    func test_store_load_restoresProfile() {
        let defaults = makeInMemoryDefaults()
        var seed = SajuInputModel.default
        seed.name = "지우"
        seed.gender = .female
        let data = try! JSONEncoder().encode(seed)
        defaults.set(data, forKey: SajuInputStore.Keys.userProfile)

        let store = SajuInputStore(defaults: defaults)
        XCTAssertEqual(store.input.name, "지우")
        XCTAssertEqual(store.input.gender, .female)
    }

    // T30 — FR-10.2
    func test_referral_inviteCode_isFiveAlnumChars_stable() {
        let defaults = makeInMemoryDefaults()
        let store = SajuInputStore(defaults: defaults)
        store.input.name = "민주"
        store.input.birthDate = BirthDate(year: 1990, month: 3, day: 15, kind: .solar)
        let code = store.inviteCode
        XCTAssertEqual(code.count, 5)
        let alnum = CharacterSet.alphanumerics
        for scalar in code.unicodeScalars {
            XCTAssertTrue(alnum.contains(scalar), "Invite code must be alphanumeric: \(code)")
        }
        // Stable across calls.
        XCTAssertEqual(code, store.inviteCode)
    }

    // T31 — FR-10.8, AC-25
    func test_referral_inviteURL_format() {
        let defaults = makeInMemoryDefaults()
        let store = SajuInputStore(defaults: defaults)
        store.input.name = "민주"
        let url = store.inviteURL
        XCTAssertTrue(url.hasPrefix("https://woontech.app/invite/"))
        XCTAssertTrue(url.hasSuffix(store.inviteCode))
    }

    func test_store_copyInviteLink_storesURLAndShowsToast() {
        let defaults = makeInMemoryDefaults()
        let store = SajuInputStore(defaults: defaults)
        store.copyInviteLink()
        XCTAssertEqual(store.lastCopiedInviteURL, store.inviteURL)
        XCTAssertTrue(store.showToast)
        XCTAssertEqual(store.toastMessage, "복사되었어요")
    }

    func test_store_resetForTests_clearsProfile() {
        let defaults = makeInMemoryDefaults()
        let store = SajuInputStore(defaults: defaults)
        store.input.name = "민주"
        store.persist()
        store.resetForTests()
        XCTAssertEqual(store.input.name, "")
        XCTAssertNil(defaults.data(forKey: SajuInputStore.Keys.userProfile))
    }
}
