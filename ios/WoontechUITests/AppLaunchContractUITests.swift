import XCTest

/// Verifies the app launch-argument routing contract: when a test launches the
/// app with `-openHome`, `-openReferral`, or `-sajuStartStep`, the app must
/// land on and stay on the requested route — even after the splash timer
/// fires. Regressions here surface as a routing race where the splash callback
/// overwrites the launch-arg route ~1.5s after launch.
///
/// This class is registered as a mandatory UI smoke test in the harness
/// (`always_ui_test_classes`) so it runs on every reviewer pass regardless of
/// which UI test files were changed in the worktree.
final class AppLaunchContractUITests: XCTestCase {

    /// Splash duration (1500ms) plus a 1.0s buffer to let any late routing
    /// decision settle before we re-check the route.
    private static let postSplashSettleSeconds: TimeInterval = 2.5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func waitPastSplash() {
        let exp = expectation(description: "wait past splash")
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.postSplashSettleSeconds) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.postSplashSettleSeconds + 1.0)
    }

    func test_openHome_routesToHome_andStaysAfterSplash() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboarding", "-openHome"]
        app.launch()

        let home = app.otherElements["HomeDashboardRoot"]
        XCTAssertTrue(home.waitForExistence(timeout: 3),
                      "HomeDashboardRoot should appear after launch with -openHome")

        waitPastSplash()

        XCTAssertTrue(home.exists,
                      "HomeDashboardRoot must remain after splash; splash callback overrode launch-arg route")
        XCTAssertFalse(app.otherElements["OnboardingRoot"].exists,
                       "OnboardingRoot must not appear when -openHome was supplied")
    }

    func test_openReferral_routesToReferral_andStaysAfterSplash() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboarding", "-resetSajuInput", "-openReferral"]
        app.launch()

        let referral = app.otherElements["SajuReferralRoot"]
        XCTAssertTrue(referral.waitForExistence(timeout: 3),
                      "SajuReferralRoot should appear after launch with -openReferral")

        waitPastSplash()

        XCTAssertTrue(referral.exists,
                      "SajuReferralRoot must remain after splash; splash callback overrode launch-arg route")
        XCTAssertFalse(app.otherElements["OnboardingRoot"].exists,
                       "OnboardingRoot must not appear when -openReferral was supplied")
    }

    func test_openSajuTab_routesToSajuTab_andStaysAfterSplash() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboarding", "-openSajuTab"]
        app.launch()

        let sajuRoot = app.otherElements["SajuTabRoot"]
        XCTAssertTrue(sajuRoot.waitForExistence(timeout: 3),
                      "SajuTabRoot should appear after launch with -openSajuTab")

        waitPastSplash()

        XCTAssertTrue(sajuRoot.exists,
                      "SajuTabRoot must remain after splash; splash callback overrode launch-arg route")
        XCTAssertFalse(app.otherElements["OnboardingRoot"].exists,
                       "OnboardingRoot must not appear when -openSajuTab was supplied")
    }

    func test_sajuStartStep_routesToSajuInput_andStaysAfterSplash() {
        let app = XCUIApplication()
        // -resetOnboarding makes hasSeenOnboarding=false, so without the route
        // guard the splash callback would route to .onboarding instead of
        // honoring the -sajuStartStep launch arg. -sajuStartStep 1 lands on
        // gender step (rawValue 1), whose root identifier is SajuInputRoot.
        app.launchArguments = ["-resetOnboarding", "-resetSajuInput", "-sajuStartStep", "1"]
        app.launch()

        let sajuInput = app.otherElements["SajuInputRoot"]
        XCTAssertTrue(sajuInput.waitForExistence(timeout: 3),
                      "SajuInputRoot should appear after launch with -sajuStartStep 1")

        waitPastSplash()

        XCTAssertTrue(sajuInput.exists,
                      "SajuInputRoot must remain after splash; splash callback overrode launch-arg route")
        XCTAssertFalse(app.otherElements["OnboardingRoot"].exists,
                       "OnboardingRoot must not appear when -sajuStartStep was supplied")
    }
}
