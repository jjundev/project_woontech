import XCTest
@testable import Woontech

final class OnboardingFlowStateTests: XCTestCase {

    func test_defaults() {
        let flow = OnboardingFlowModel()
        XCTAssertEqual(flow.step, 1)
        XCTAssertFalse(flow.disclaimerChecked)
        XCTAssertTrue(flow.isCTAEnabled)
        XCTAssertEqual(flow.ctaLabelKey, "onboarding.cta.next")
    }

    func test_ctaEnabled_stepsOneAndTwo_alwaysTrue() {
        var flow = OnboardingFlowModel()
        flow.jump(to: 1)
        XCTAssertTrue(flow.isCTAEnabled)

        flow.jump(to: 2)
        XCTAssertTrue(flow.isCTAEnabled)

        flow.disclaimerChecked = false
        flow.jump(to: 2)
        XCTAssertTrue(flow.isCTAEnabled)
    }

    func test_ctaEnabled_stepThree_dependsOnDisclaimer() {
        var flow = OnboardingFlowModel()
        flow.jump(to: 3)
        XCTAssertFalse(flow.isCTAEnabled)

        flow.disclaimerChecked = true
        XCTAssertTrue(flow.isCTAEnabled)

        flow.disclaimerChecked = false
        XCTAssertFalse(flow.isCTAEnabled)
    }

    func test_ctaLabelKey_switchesOnStepThree() {
        var flow = OnboardingFlowModel()
        flow.jump(to: 1)
        XCTAssertEqual(flow.ctaLabelKey, "onboarding.cta.next")
        flow.jump(to: 2)
        XCTAssertEqual(flow.ctaLabelKey, "onboarding.cta.next")
        flow.jump(to: 3)
        XCTAssertEqual(flow.ctaLabelKey, "onboarding.cta.start")
    }

    func test_goNext_clampsAtLastStep() {
        var flow = OnboardingFlowModel()
        flow.goNext()
        XCTAssertEqual(flow.step, 2)
        flow.goNext()
        XCTAssertEqual(flow.step, 3)
        flow.goNext()
        XCTAssertEqual(flow.step, 3)
    }

    func test_goPrevious_clampsAtFirstStep() {
        var flow = OnboardingFlowModel()
        flow.jump(to: 3)
        flow.goPrevious()
        XCTAssertEqual(flow.step, 2)
        flow.goPrevious()
        XCTAssertEqual(flow.step, 1)
        flow.goPrevious()
        XCTAssertEqual(flow.step, 1)
    }

    func test_jump_outOfRange_isIgnored() {
        var flow = OnboardingFlowModel()
        flow.jump(to: 2)
        flow.jump(to: 0)
        XCTAssertEqual(flow.step, 2)
        flow.jump(to: 4)
        XCTAssertEqual(flow.step, 2)
    }

    func test_toggleDisclaimer() {
        var flow = OnboardingFlowModel()
        XCTAssertFalse(flow.disclaimerChecked)
        flow.toggleDisclaimer()
        XCTAssertTrue(flow.disclaimerChecked)
        flow.toggleDisclaimer()
        XCTAssertFalse(flow.disclaimerChecked)
    }

    func test_isFirstStep_isLastStep_flags() {
        var flow = OnboardingFlowModel()
        XCTAssertTrue(flow.isFirstStep)
        XCTAssertFalse(flow.isLastStep)

        flow.jump(to: 3)
        XCTAssertFalse(flow.isFirstStep)
        XCTAssertTrue(flow.isLastStep)
    }
}
