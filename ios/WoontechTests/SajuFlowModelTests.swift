import XCTest
@testable import Woontech

final class SajuFlowModelTests: XCTestCase {

    // T1 — FR-C1
    func test_flow_step1_startsAtOneOfSix() {
        let flow = SajuFlowModel()
        XCTAssertEqual(flow.currentStep, .gender)
        XCTAssertEqual(flow.progressLabel, "1/6")
    }

    // T2 — FR-C1
    func test_flow_progress_updatesWithStep() {
        var flow = SajuFlowModel()
        XCTAssertEqual(flow.progressLabel, "1/6")
        flow.currentStep = .name
        XCTAssertEqual(flow.progressLabel, "2/6")
        flow.currentStep = .birthDate
        XCTAssertEqual(flow.progressLabel, "3/6")
        flow.currentStep = .birthTime
        XCTAssertEqual(flow.progressLabel, "4/6")
        flow.currentStep = .birthPlace
        XCTAssertEqual(flow.progressLabel, "5/6")
        flow.currentStep = .solarTime
        XCTAssertEqual(flow.progressLabel, "6/6")
        XCTAssertEqual(flow.progressFraction, 1.0, accuracy: 0.01)
    }

    // T3 — FR-C2
    func test_flow_back_fromStep1_triggersExit() {
        var flow = SajuFlowModel()
        let moved = flow.back(using: .default)
        XCTAssertFalse(moved)
        XCTAssertEqual(flow.currentStep, .gender)
    }

    // T4 — FR-C3
    func test_flow_ctaLabel_step1to5_next_step6_startAnalysis() {
        let labels: [(SajuStep, String)] = [
            (.gender, "saju.cta.next"),
            (.name, "saju.cta.next"),
            (.birthDate, "saju.cta.next"),
            (.birthTime, "saju.cta.next"),
            (.birthPlace, "saju.cta.next"),
            (.solarTime, "saju.cta.startAnalysis"),
        ]
        for (step, expected) in labels {
            XCTAssertEqual(step.ctaLabelKey, expected, "Step \(step) should use \(expected)")
        }
    }

    // T5 — FR-1.3, FR-C4
    func test_flow_isCTAEnabled_gender_requiresSelection() {
        let flow = SajuFlowModel()
        var input = SajuInputModel.default
        XCTAssertFalse(flow.isCTAEnabled(using: input))
        input.gender = .male
        XCTAssertTrue(flow.isCTAEnabled(using: input))
    }

    // T6 — FR-C5
    func test_flow_swipeNavigation_notExposed() {
        let flow = SajuFlowModel()
        XCTAssertFalse(flow.supportsSwipeNavigation)
    }

    // T15 — FR-6.5, AC-10
    func test_flow_skipsStep6_whenHourUnknown() {
        var flow = SajuFlowModel()
        flow.currentStep = .birthPlace
        var input = SajuInputModel.default
        input.gender = .male
        input.name = "민"
        input.birthPlace = .domestic(cityID: "SEOUL")
        input.birthTime.hourKnown = false
        flow.advance(using: input)
        XCTAssertEqual(flow.currentStep, .loader,
                       "Step 5 → Step 7 should skip Step 6 when hourKnown=false")
    }

    func test_flow_doesNotSkipStep6_whenHourKnown() {
        var flow = SajuFlowModel()
        flow.currentStep = .birthPlace
        var input = SajuInputModel.default
        input.gender = .male
        input.name = "민"
        input.birthPlace = .domestic(cityID: "SEOUL")
        input.birthTime.hourKnown = true
        flow.advance(using: input)
        XCTAssertEqual(flow.currentStep, .solarTime)
    }

    func test_flow_back_fromStepN_movesToPrevious() {
        var flow = SajuFlowModel()
        flow.currentStep = .name
        _ = flow.back(using: .default)
        XCTAssertEqual(flow.currentStep, .gender)

        flow.currentStep = .solarTime
        _ = flow.back(using: .default)
        XCTAssertEqual(flow.currentStep, .birthPlace)
    }

    func test_flow_loader_backIsNoop() {
        var flow = SajuFlowModel()
        flow.currentStep = .loader
        let moved = flow.back(using: .default)
        XCTAssertFalse(moved)
        XCTAssertEqual(flow.currentStep, .loader)
    }

    func test_flow_jump_setsReturnToResult() {
        var flow = SajuFlowModel()
        flow.currentStep = .result
        flow.jump(to: .name)
        XCTAssertEqual(flow.currentStep, .name)
        XCTAssertTrue(flow.returnToResult)
    }

    func test_flow_completeEditReturn_resetsFlagAndGoesToResult() {
        var flow = SajuFlowModel()
        flow.currentStep = .result
        flow.jump(to: .name)
        flow.completeEditReturn()
        XCTAssertEqual(flow.currentStep, .result)
        XCTAssertFalse(flow.returnToResult)
    }
}
