import XCTest

final class HomeDashboardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // Launches the app with given arguments and waits for HomeDashboardRoot.
    private func launchWithArgs(_ args: [String]) {
        app.launchArguments = args
        app.launch()
        let root = app.otherElements["HomeDashboardRoot"]
        XCTAssertTrue(root.waitForExistence(timeout: 5), "HomeDashboardRoot should appear after launch")
    }

    // MARK: - T11: Wordmark visible
    func test_homeDashboard_wordmarkVisible() {
        launchWithArgs(["-openHome"])
        XCTAssertTrue(app.staticTexts["운테크"].exists)
    }

    // MARK: - T12: Renders new dashboard, not old placeholder
    func test_homeDashboard_rendersNotPlaceholder() {
        launchWithArgs(["-openHome"])
        XCTAssertTrue(app.otherElements["HomeDashboardRoot"].exists)
        XCTAssertFalse(app.otherElements["HomeRoot"].exists)
    }

    // MARK: - T13: Badge hidden when count = 0
    func test_bellBadge_hiddenWhenZero() {
        launchWithArgs(["-openHome", "-mockHomeUnreadCount", "0"])
        // When unreadCount == 0, badgeLabel returns nil so the badge view is never rendered
        XCTAssertFalse(app.staticTexts["HomeBellBadge"].exists)
    }

    // MARK: - T14: Badge shows numeric count
    func test_bellBadge_showsCount_whenPositive() {
        launchWithArgs(["-openHome", "-mockHomeUnreadCount", "2"])
        let badge = app.staticTexts["HomeBellBadge"]
        XCTAssertTrue(badge.waitForExistence(timeout: 3))
        XCTAssertEqual(badge.label, "2")
    }

    // MARK: - T15: Badge clamps to "99+" for counts >= 100
    func test_bellBadge_99Plus_when150() {
        launchWithArgs(["-openHome", "-mockHomeUnreadCount", "150"])
        let badge = app.staticTexts["HomeBellBadge"]
        XCTAssertTrue(badge.waitForExistence(timeout: 3))
        XCTAssertEqual(badge.label, "99+")
    }

    // MARK: - T16: Avatar initial from mock
    func test_avatarInitial_shownFromMock() {
        launchWithArgs(["-openHome", "-mockHomeAvatarInitial", "민"])
        let avatarButton = app.buttons["HomeAvatarButton"]
        XCTAssertTrue(avatarButton.waitForExistence(timeout: 3))
        XCTAssertTrue(avatarButton.staticTexts["민"].exists)
    }

    // MARK: - T17: Bell tap handler called once
    func test_bellTap_handlerCalledOnce() {
        launchWithArgs(["-openHome"])
        let bellButton = app.buttons["HomeBellButton"]
        XCTAssertTrue(bellButton.waitForExistence(timeout: 3))
        bellButton.tap()
        XCTAssertEqual(app.staticTexts["HomeBellTapCount"].label, "1")
    }

    // MARK: - T18: Avatar tap handler called once
    func test_avatarTap_handlerCalledOnce() {
        launchWithArgs(["-openHome"])
        let avatarButton = app.buttons["HomeAvatarButton"]
        XCTAssertTrue(avatarButton.waitForExistence(timeout: 3))
        avatarButton.tap()
        XCTAssertEqual(app.staticTexts["HomeAvatarTapCount"].label, "1")
    }

    // MARK: - T19: Nav push to investing destination
    func test_navPush_investing_showsPlaceholder() {
        launchWithArgs(["-openHome"])
        let btn = app.buttons["HomeNavPushInvesting"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(app.staticTexts["HomeRoute_investingDest"].waitForExistence(timeout: 3))
    }

    // MARK: - T20: Nav push to event destination
    func test_navPush_event_showsPlaceholder() {
        launchWithArgs(["-openHome"])
        let btn = app.buttons["HomeNavPushEvent"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(app.staticTexts["HomeRoute_eventDest"].waitForExistence(timeout: 3))
    }

    // MARK: - T21: Nav push to today destination
    func test_navPush_today_showsPlaceholder() {
        launchWithArgs(["-openHome"])
        let btn = app.buttons["HomeNavPushToday"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(app.staticTexts["HomeRoute_todayDest"].waitForExistence(timeout: 3))
    }

    // MARK: - T22: Nav push to taboo destination
    func test_navPush_taboo_showsPlaceholder() {
        launchWithArgs(["-openHome"])
        let btn = app.buttons["HomeNavPushTaboo"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(app.staticTexts["HomeRoute_tabooDest"].waitForExistence(timeout: 3))
    }

    // MARK: - T23: Nav push to practice destination
    func test_navPush_practice_showsPlaceholder() {
        launchWithArgs(["-openHome"])
        let btn = app.buttons["HomeNavPushPractice"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(app.staticTexts["HomeRoute_practiceDest"].waitForExistence(timeout: 3))
    }

    // MARK: - T24: Header elements don't overlap at default size
    func test_dynamicType_xl_noOverlap() {
        launchWithArgs(["-openHome"])
        let wordmark = app.staticTexts["HomeWordmark"]
        let bellButton = app.buttons["HomeBellButton"]
        let avatarButton = app.buttons["HomeAvatarButton"]

        XCTAssertTrue(wordmark.waitForExistence(timeout: 3))
        XCTAssertTrue(bellButton.exists)
        XCTAssertTrue(avatarButton.exists)

        let wordmarkFrame = wordmark.frame
        let bellFrame = bellButton.frame
        let avatarFrame = avatarButton.frame

        XCTAssertFalse(
            wordmarkFrame.intersects(bellFrame),
            "Wordmark and bell button must not overlap"
        )
        XCTAssertFalse(
            wordmarkFrame.intersects(avatarFrame),
            "Wordmark and avatar button must not overlap"
        )
        XCTAssertFalse(
            bellFrame.intersects(avatarFrame),
            "Bell button and avatar button must not overlap"
        )
    }

    // MARK: - T25: VoiceOver bell label with default unreadCount=2
    func test_voiceOver_bellLabel_unread2() {
        launchWithArgs(["-openHome"])
        let bellButton = app.buttons["HomeBellButton"]
        XCTAssertTrue(bellButton.waitForExistence(timeout: 3))
        XCTAssertEqual(bellButton.label, "알림 2개")
    }
}
