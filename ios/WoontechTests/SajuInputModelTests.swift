import XCTest
@testable import Woontech

final class SajuInputModelTests: XCTestCase {

    // T7 — FR-2.4
    func test_input_name_trimming_limit20chars_activates() {
        var input = SajuInputModel.default
        input.name = "   "
        XCTAssertFalse(input.isNameComplete, "Whitespace-only name should not count")

        input.name = "민"
        XCTAssertTrue(input.isNameComplete)

        // Sanitize clamps to 20 chars.
        let raw = String(repeating: "가", count: 25)
        input.name = SajuInputModel.sanitizeName(raw)
        XCTAssertEqual(input.name.count, 20)
        XCTAssertTrue(input.isNameComplete)
    }

    // T8 — FR-3.4
    func test_input_birthDate_default_1990_03_15_solar() {
        let input = SajuInputModel.default
        XCTAssertEqual(input.birthDate.year, 1990)
        XCTAssertEqual(input.birthDate.month, 3)
        XCTAssertEqual(input.birthDate.day, 15)
        XCTAssertTrue(input.birthDate.kind.isSolar)
    }

    // T9 — FR-3.5
    func test_input_birthDate_yearRange_1900_toCurrent() {
        let range = BirthDate.yearRange()
        XCTAssertEqual(range.lowerBound, 1900)
        XCTAssertEqual(range.upperBound, Calendar.current.component(.year, from: Date()))
        XCTAssertTrue(range.contains(1990))
    }

    // T10 — FR-3.6
    func test_input_birthDate_invalidDays_filtered() {
        XCTAssertEqual(BirthDate.daysInMonth(year: 2023, month: 2), 28)
        XCTAssertEqual(BirthDate.daysInMonth(year: 2024, month: 2), 29) // leap
        XCTAssertEqual(BirthDate.daysInMonth(year: 2024, month: 4), 30)
        XCTAssertFalse(BirthDate.isValid(year: 2024, month: 2, day: 30))
        XCTAssertFalse(BirthDate.isValid(year: 2024, month: 4, day: 31))
        XCTAssertTrue(BirthDate.isValid(year: 1990, month: 3, day: 15))
    }

    // T11 — FR-3.3 (leap-month availability predicate)
    func test_input_lunar_leapMonth_toggle_availability() {
        // 2020 is a known year with an intercalary 4th month on the Chinese calendar.
        let hasLeap2020 = LunarCalendar.hasLeapMonth(year: 2020, month: 4)
        XCTAssertTrue(hasLeap2020, "2020 should have a leap month in April lunar")
        // Pick a year/month with no leap — Jan of 2020 has no leap.
        let hasLeapJan = LunarCalendar.hasLeapMonth(year: 2020, month: 1)
        XCTAssertFalse(hasLeapJan)
    }

    // T12 — FR-3.7, AC-4
    func test_input_birthDate_isCTAEnabled_default() {
        let input = SajuInputModel.default
        XCTAssertTrue(input.isBirthDateComplete)
    }

    // T13 — FR-4.3, FR-4.4
    func test_input_birthTime_hourKnownFalse_disablesPicker() {
        var input = SajuInputModel.default
        input.birthTime = BirthTime(hour: 99, minute: 99, hourKnown: false)
        XCTAssertTrue(input.isBirthTimeComplete, "hourKnown=false must pass regardless of hour/minute")
        input.birthTime = BirthTime(hour: 25, minute: 0, hourKnown: true)
        XCTAssertFalse(input.isBirthTimeComplete, "Invalid hour should fail when hourKnown=true")
    }

    // T14 — FR-4.5
    func test_input_birthTime_ctaEnabledWhenKnownOrUnknown() {
        var input = SajuInputModel.default
        input.birthTime = BirthTime(hour: 5, minute: 30, hourKnown: true)
        XCTAssertTrue(input.isBirthTimeComplete)
        input.birthTime = BirthTime(hour: 12, minute: 0, hourKnown: false)
        XCTAssertTrue(input.isBirthTimeComplete)
    }

    // T16 — FR-5.3
    func test_input_birthPlace_default_seoul_enablesCTA() {
        let input = SajuInputModel.default
        if case .domestic(let id) = input.birthPlace {
            XCTAssertEqual(id, "SEOUL")
        } else {
            XCTFail("Default should be Seoul")
        }
        XCTAssertTrue(input.isBirthPlaceComplete)
    }

    // T17 — FR-5.5, FR-5.6
    func test_input_birthPlace_overseas_longitudeRange() {
        XCTAssertTrue(BirthPlace.isLongitudeValid(0))
        XCTAssertTrue(BirthPlace.isLongitudeValid(-180))
        XCTAssertTrue(BirthPlace.isLongitudeValid(180))
        XCTAssertFalse(BirthPlace.isLongitudeValid(180.0001))
        XCTAssertFalse(BirthPlace.isLongitudeValid(-180.0001))
        XCTAssertFalse(BirthPlace.isLongitudeValid(.nan))
        XCTAssertFalse(BirthPlace.isLongitudeValid(.infinity))
        var input = SajuInputModel.default
        input.birthPlace = .overseas(longitude: 139.69)
        XCTAssertTrue(input.isBirthPlaceComplete)
        input.birthPlace = .overseas(longitude: 200)
        XCTAssertFalse(input.isBirthPlaceComplete)
    }

    // T24 — FR-8.3, AC-16
    func test_result_displayLabel_truncatesOver10chars() {
        var input = SajuInputModel.default
        input.name = String(repeating: "가", count: 11)
        let label = input.displayNameLabel
        // "가가가가가가가가…님의 투자 성향"
        XCTAssertTrue(label.contains("…"), "Long name must be truncated with ellipsis")
        XCTAssertTrue(label.hasSuffix("님의 투자 성향"))
    }

    // T25 — FR-8.3, AC-16
    func test_result_displayLabel_fallback_whenNameEmpty() {
        var input = SajuInputModel.default
        input.name = "   "
        XCTAssertEqual(input.displayNameLabel, "당신의 투자 성향")
    }

    // T26 — FR-8.4, AC-17
    func test_result_accuracyBadge_rules() {
        var input = SajuInputModel.default
        // hour known + place + solar ON → high
        input.birthTime.hourKnown = true
        input.solarTime.enabled = true
        XCTAssertEqual(input.accuracy, .high)

        // hour known but solar OFF → medium
        input.solarTime.enabled = false
        XCTAssertEqual(input.accuracy, .medium)

        // hour unknown → mediumAddTime
        input.birthTime.hourKnown = false
        XCTAssertEqual(input.accuracy, .mediumAddTime)
    }
}
