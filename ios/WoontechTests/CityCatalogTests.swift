import XCTest
@testable import Woontech

final class CityCatalogTests: XCTestCase {

    // T18 — FR-5.4
    func test_cityCatalog_searchFiltersByPrefix() {
        let catalog = CityCatalog.shared
        let seoulResults = catalog.search("서울")
        XCTAssertTrue(seoulResults.contains(where: { $0.id == "SEOUL" }))

        let pusanResults = catalog.search("부산")
        XCTAssertTrue(pusanResults.contains(where: { $0.id == "BUSAN" }))

        let empty = catalog.search("")
        XCTAssertEqual(empty.map(\.id), catalog.primaryCities.map(\.id))
    }

    func test_cityCatalog_primaryCities_exactlyTheSixRequired() {
        let primaryIDs = CityCatalog.shared.primaryCities.map(\.id)
        XCTAssertEqual(primaryIDs, ["SEOUL", "BUSAN", "INCHEON", "DAEGU", "GWANGJU", "DAEJEON"])
    }

    func test_cityCatalog_defaultCityID_isSeoul() {
        XCTAssertEqual(CityCatalog.defaultCityID, "SEOUL")
        XCTAssertNotNil(CityCatalog.shared.city(withID: "SEOUL"))
    }

    func test_cityCatalog_knownSeoulLongitude() {
        let seoul = CityCatalog.shared.city(withID: "SEOUL")
        XCTAssertEqual(seoul?.longitude ?? 0, 126.978, accuracy: 0.01)
    }
}
