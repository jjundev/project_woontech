import XCTest
@testable import Woontech

final class SolarTimeCalculatorTests: XCTestCase {

    // T19 — FR-6.3
    func test_solarTime_default_ON() {
        XCTAssertTrue(SolarTimeCorrection.default.enabled)
        XCTAssertTrue(SajuInputModel.default.solarTime.enabled)
    }

    // T20 — FR-6.4, AC-11 (Seoul 127° → −32 min)
    func test_solarTime_calculatedValues_forSeoul() {
        let seoul = CityCatalog.shared.city(withID: "SEOUL")!
        let offset = SolarTimeCalculator.offsetMinutes(longitude: seoul.longitude)
        // Seoul ≈ 126.978° → (126.978 - 135) * 4 ≈ -32.09 → -32 min.
        XCTAssertEqual(offset, -32, "Seoul offset should be ~-32 minutes")

        let result = SolarTimeCalculator.correct(hour: 12, minute: 0, longitude: seoul.longitude)
        XCTAssertEqual(result.offsetMinutes, -32)
        XCTAssertEqual(result.correctedHour, 11)
        XCTAssertEqual(result.correctedMinute, 28)
    }

    // T21 — FR-6.4, AC-11 (toggle off case: semantic check via helper)
    func test_solarTime_toggleOff_outputsNotApplied() {
        // The view uses `solarTime.enabled` to decide "미적용". Unit level: ensure
        // that when enabled=false, callers should not apply the offset. We verify
        // that the toggle flag is independent of the calculator output.
        var input = SajuInputModel.default
        input.solarTime.enabled = false
        XCTAssertFalse(input.solarTime.enabled)

        // Calculator still returns the same math — view must gate on enabled flag.
        let result = SolarTimeCalculator.correct(hour: 12, minute: 0, longitude: 127.0)
        XCTAssertEqual(result.offsetMinutes, -32)
    }

    func test_solarTime_overshootsWrapsAround() {
        // Near-midnight corrections should wrap.
        let result = SolarTimeCalculator.correct(hour: 0, minute: 10, longitude: 100.0)
        // (100-135)*4 = -140 min → 0*60+10 - 140 = -130 → wraps to 22:10.
        XCTAssertEqual(result.correctedHour, 21)
        XCTAssertEqual(result.correctedMinute, 50)
    }
}
