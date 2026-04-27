import XCTest

/// UI tests for WF4-01 사주 탭 foundation.
///
/// These tests verify the SajuTabView container, NavigationStack route placeholders,
/// the main tab bar wiring (`MainTabContainerView`), and basic accessibility hooks.
final class SajuTabFoundationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launchSajuTab(extraArgs: [String] = []) {
        app.launchArguments = ["-resetOnboarding", "-openSajuTab"] + extraArgs
        app.launch()
        XCTAssertTrue(
            app.otherElements["SajuTabRoot"].waitForExistence(timeout: 5),
            "SajuTabRoot should exist after launch with -openSajuTab"
        )
    }

    private func sajuTabBarButton() -> XCUIElement {
        // System tab bar exposes tab items via accessibilityLabel; we set
        // "사주 탭" on the saju tab item.
        return app.tabBars.buttons["사주 탭"]
    }

    // T13
    func test_launch_openSajuTab_landsOnSajuTab() {
        launchSajuTab()
        XCTAssertTrue(app.otherElements["SajuTabRoot"].exists)
        // Header title should be visible (only rendered for Saju tab).
        XCTAssertTrue(app.staticTexts["SajuTabHeaderTitle"].waitForExistence(timeout: 3))
    }

    // T14
    func test_tabBar_index2_tap_showsSajuTabView() {
        // Boot with -openHome instead so initial selection is 0.
        app.launchArguments = ["-resetOnboarding", "-openHome"]
        app.launch()
        XCTAssertTrue(
            app.otherElements["HomeDashboardRoot"].waitForExistence(timeout: 5),
            "HomeDashboardRoot should exist initially"
        )

        let sajuTab = sajuTabBarButton()
        XCTAssertTrue(sajuTab.waitForExistence(timeout: 3),
                      "사주 탭 tab bar button must exist")
        sajuTab.tap()

        XCTAssertTrue(
            app.otherElements["SajuTabRoot"].waitForExistence(timeout: 3),
            "SajuTabRoot must be visible after tapping 사주 탭"
        )
    }

    // T15
    func test_sajuHeader_titleVisible() {
        launchSajuTab()
        let title = app.staticTexts["SajuTabHeaderTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertEqual(title.label, "사주")
    }

    // T16
    func test_sajuHeader_menuButtonVisible() {
        launchSajuTab()
        let menu = app.buttons["SajuTabHeaderMenuButton"]
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
    }

    // T17
    func test_sajuContent_placeholderVisible() {
        launchSajuTab()
        let placeholderText = app.staticTexts["SajuTabContentPlaceholderText"]
        XCTAssertTrue(placeholderText.waitForExistence(timeout: 3))
        XCTAssertEqual(placeholderText.label, "준비중")
    }

    private func tapPushAndAssertDestination(
        button identifier: String,
        destinationKey: String
    ) {
        launchSajuTab()
        let btn = app.buttons[identifier]
        XCTAssertTrue(btn.waitForExistence(timeout: 3),
                      "Trigger button \(identifier) must exist")
        btn.tap()

        let destinationId = "SajuPlaceholderDestination_\(destinationKey)"
        XCTAssertTrue(
            app.otherElements[destinationId].waitForExistence(timeout: 3),
            "Destination \(destinationId) should appear after pushing \(identifier)"
        )
    }

    // T18
    func test_sajuRoute_pushElements_showsPlaceholder() {
        tapPushAndAssertDestination(button: "SajuNavPush_elements", destinationKey: "elements")
    }

    // T19
    func test_sajuRoute_pushTenGods_showsPlaceholder() {
        tapPushAndAssertDestination(button: "SajuNavPush_tenGods", destinationKey: "tenGods")
    }

    // T20
    func test_sajuRoute_pushLearn_showsPlaceholder() {
        tapPushAndAssertDestination(button: "SajuNavPush_learn", destinationKey: "learn")
    }

    // T21
    func test_sajuRoute_pushDaewoon_showsPlaceholder() {
        tapPushAndAssertDestination(button: "SajuNavPush_daewoon", destinationKey: "daewoon")
    }

    // T22
    func test_sajuRoute_pushHapchung_showsPlaceholder() {
        tapPushAndAssertDestination(button: "SajuNavPush_hapchung", destinationKey: "hapchung")
    }

    // T23
    func test_sajuRoute_pushYongsin_showsPlaceholder() {
        tapPushAndAssertDestination(button: "SajuNavPush_yongsin", destinationKey: "yongsin")
    }

    // T24
    func test_sajuRoute_pushLesson_showsIdentifier_L001() {
        launchSajuTab()
        let btn = app.buttons["SajuNavPush_lessonL001"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()

        let lessonDest = app.otherElements["SajuPlaceholderDestination_lesson"]
        XCTAssertTrue(lessonDest.waitForExistence(timeout: 3))

        let idLabel = app.staticTexts["SajuPlaceholderDestination_lesson_Identifier"]
        XCTAssertTrue(idLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(idLabel.label, "L-001")
    }

    // T25
    func test_tabSwitch_preservesSajuPath() {
        // Boot with -openHome so home tab is initial; both tabs render hidden
        // push triggers (because args contain -openHome).
        app.launchArguments = ["-resetOnboarding", "-openHome"]
        app.launch()
        XCTAssertTrue(app.otherElements["HomeDashboardRoot"].waitForExistence(timeout: 5))

        // Switch to saju tab.
        sajuTabBarButton().tap()
        XCTAssertTrue(app.otherElements["SajuTabRoot"].waitForExistence(timeout: 3))

        // Push elements destination.
        let pushBtn = app.buttons["SajuNavPush_elements"]
        XCTAssertTrue(pushBtn.waitForExistence(timeout: 3))
        pushBtn.tap()
        XCTAssertTrue(
            app.otherElements["SajuPlaceholderDestination_elements"].waitForExistence(timeout: 3)
        )

        // Switch to home tab.
        let homeTab = app.tabBars.buttons["홈"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 3))
        homeTab.tap()
        XCTAssertTrue(app.otherElements["HomeDashboardRoot"].waitForExistence(timeout: 3))

        // Switch back to saju tab — pushed destination should still be on top.
        sajuTabBarButton().tap()
        XCTAssertTrue(
            app.otherElements["SajuPlaceholderDestination_elements"].waitForExistence(timeout: 3),
            "Saju navigation path should be preserved across tab switches"
        )
    }

    // T26
    func test_voiceOver_sajuTabBar_label_사주탭() {
        launchSajuTab()
        let sajuTab = sajuTabBarButton()
        XCTAssertTrue(sajuTab.waitForExistence(timeout: 3))
        XCTAssertEqual(sajuTab.label, "사주 탭")
    }

    // T27
    func test_voiceOver_sajuHeader_titleLabel_사주() {
        launchSajuTab()
        let title = app.staticTexts["SajuTabHeaderTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertEqual(title.label, "사주")
    }

    // T28
    func test_dynamicType_xl_headerNoTruncation() {
        app.launchEnvironment["UIContentSizeCategoryOverride"] = "UICTContentSizeCategoryXL"
        launchSajuTab()
        let title = app.staticTexts["SajuTabHeaderTitle"]
        let menu = app.buttons["SajuTabHeaderMenuButton"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(title.frame.height, 0)
        XCTAssertGreaterThan(menu.frame.height, 0)
        XCTAssertFalse(title.frame.intersects(menu.frame),
                       "Saju header title and menu button must not overlap at XL")
    }

    // T29
    func test_homeAndSajuStacks_isolated() {
        app.launchArguments = ["-resetOnboarding", "-openHome"]
        app.launch()
        XCTAssertTrue(app.otherElements["HomeDashboardRoot"].waitForExistence(timeout: 5))

        // Saju tab → push elements
        sajuTabBarButton().tap()
        XCTAssertTrue(app.otherElements["SajuTabRoot"].waitForExistence(timeout: 3))
        app.buttons["SajuNavPush_elements"].tap()
        XCTAssertTrue(
            app.otherElements["SajuPlaceholderDestination_elements"].waitForExistence(timeout: 3)
        )

        // Home tab → push investing
        let homeTab = app.tabBars.buttons["홈"]
        homeTab.tap()
        XCTAssertTrue(app.otherElements["HomeDashboardRoot"].waitForExistence(timeout: 3))
        app.buttons["HomeNavPushInvesting"].tap()
        XCTAssertTrue(app.staticTexts["HomeRoute_investingDest"].waitForExistence(timeout: 3))

        // Saju placeholder must NOT be present in home tab tree.
        XCTAssertFalse(
            app.otherElements["SajuPlaceholderDestination_elements"].exists,
            "Saju placeholder must not leak into home tab"
        )

        // Switch back to saju and confirm its stack is intact.
        sajuTabBarButton().tap()
        XCTAssertTrue(
            app.otherElements["SajuPlaceholderDestination_elements"].waitForExistence(timeout: 3),
            "Saju stack should remain at the elements destination"
        )
        XCTAssertFalse(
            app.staticTexts["HomeRoute_investingDest"].exists,
            "Home destination must not leak into saju tab"
        )
    }
}
