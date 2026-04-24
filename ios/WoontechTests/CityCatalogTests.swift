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

    // MARK: - 전국 카탈로그 완전성 테스트

    func test_cityCatalog_totalCityCount() {
        // 6 primary + 2 기타 광역 + 74 광역시 구/군 + 152 도 시/군 + 서귀포 = 전체 약 230+
        XCTAssertGreaterThanOrEqual(CityCatalog.shared.cities.count, 226,
            "전국 시/군/구 226개 이상이어야 합니다")
    }

    func test_cityCatalog_noDuplicateIDs() {
        let ids = CityCatalog.shared.cities.map(\.id)
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count,
            "ID 중복이 없어야 합니다")
    }

    func test_cityCatalog_allLongitudesInKoreanRange() {
        for city in CityCatalog.shared.cities {
            XCTAssertGreaterThanOrEqual(city.longitude, 124.5,
                "\(city.name)(\(city.id)) 경도가 한국 범위 미만: \(city.longitude)")
            XCTAssertLessThanOrEqual(city.longitude, 131.9,
                "\(city.name)(\(city.id)) 경도가 한국 범위 초과: \(city.longitude)")
        }
    }

    func test_cityCatalog_searchFindsNewlyAddedCities() {
        let catalog = CityCatalog.shared

        // 이전에 없던 도시들이 검색되는지 확인
        XCTAssertFalse(catalog.search("영월").isEmpty, "영월군 검색 가능해야 합니다")
        XCTAssertFalse(catalog.search("화천").isEmpty, "화천군 검색 가능해야 합니다")
        XCTAssertFalse(catalog.search("보성").isEmpty, "보성군 검색 가능해야 합니다")
        XCTAssertFalse(catalog.search("안동").isEmpty, "안동시 검색 가능해야 합니다")
        XCTAssertFalse(catalog.search("여수").isEmpty, "여수시 검색 가능해야 합니다")
        XCTAssertFalse(catalog.search("속초").isEmpty, "속초시 검색 가능해야 합니다")
    }

    func test_cityCatalog_searchFindsGuDistricts() {
        let catalog = CityCatalog.shared

        let gangnamResults = catalog.search("강남")
        XCTAssertTrue(gangnamResults.contains(where: { $0.id == "SEOUL_GANGNAM" }),
            "서울 강남구 검색 가능해야 합니다")

        let haeundaeResults = catalog.search("해운대")
        XCTAssertTrue(haeundaeResults.contains(where: { $0.id == "BUSAN_HAEUNDAE" }),
            "부산 해운대구 검색 가능해야 합니다")
    }

    func test_cityCatalog_disambiguatesGoseong() {
        let catalog = CityCatalog.shared
        let results = catalog.search("고성")
        let ids = results.map(\.id)
        XCTAssertTrue(ids.contains("GW_GOSEONG"), "강원 고성군이 있어야 합니다")
        XCTAssertTrue(ids.contains("GN_GOSEONG"), "경남 고성군이 있어야 합니다")
    }

    func test_cityCatalog_ulleungHasHighestLongitude() {
        let catalog = CityCatalog.shared
        let ulleung = catalog.city(withID: "ULLEUNG")
        XCTAssertNotNil(ulleung)
        XCTAssertGreaterThan(ulleung!.longitude, 130.0,
            "울릉군은 경도 130° 이상이어야 합니다")
    }
}
