import XCTest
@testable import Woontech

final class SajuRouteTests: XCTestCase {

    // T1
    func test_sajuRoute_allSevenCasesHashable() {
        let routes: Set<SajuRoute> = [
            .elements,
            .tenGods,
            .learn,
            .lesson(id: "L-001"),
            .daewoonPlaceholder,
            .hapchungPlaceholder,
            .yongsinPlaceholder
        ]
        XCTAssertEqual(routes.count, 7, "All seven SajuRoute cases must be unique in a Set")
    }

    // T2
    func test_sajuRoute_lesson_associatedValue_equality() {
        XCTAssertEqual(SajuRoute.lesson(id: "L-001"), SajuRoute.lesson(id: "L-001"))
        XCTAssertNotEqual(SajuRoute.lesson(id: "L-001"), SajuRoute.lesson(id: "L-002"))
        XCTAssertNotEqual(SajuRoute.lesson(id: "L-001"), SajuRoute.elements)
    }

    // T3
    func test_sajuRoute_lesson_distinctIdsAreDifferentHashes() {
        let routes: Set<SajuRoute> = [
            .lesson(id: "L-001"),
            .lesson(id: "L-002")
        ]
        XCTAssertEqual(routes.count, 2,
                       "Distinct lesson ids should produce distinct hashable values")
        XCTAssertTrue(routes.contains(.lesson(id: "L-001")))
        XCTAssertTrue(routes.contains(.lesson(id: "L-002")))
    }
}
