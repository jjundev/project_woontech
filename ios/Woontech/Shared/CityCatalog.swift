import Foundation

/// 국내 시/도 + 주요 시/군/구 고정 경도 테이블(1차 릴리스 스텁).
/// FR-5.3(기본 6개), FR-5.4(검색).
struct SajuCity: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String
    var longitude: Double
    /// 기본 리스트 포함 여부(서울·부산·인천·대구·광주·대전).
    var isPrimary: Bool
}

final class CityCatalog {
    static let shared = CityCatalog()

    static let defaultCityID = "SEOUL"

    let cities: [SajuCity]

    init(cities: [SajuCity]? = nil) {
        self.cities = cities ?? CityCatalog.builtIn
    }

    func city(withID id: String) -> SajuCity? {
        cities.first { $0.id == id }
    }

    var primaryCities: [SajuCity] {
        cities.filter { $0.isPrimary }
    }

    /// Search filter by prefix (han-gul or latin). Returns at most `limit` results
    /// ordered: primary cities first, then others. FR-5.4.
    func search(_ query: String, limit: Int = 12) -> [SajuCity] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return primaryCities }
        let matches = cities.filter { $0.name.hasPrefix(q) || $0.name.contains(q) }
        let primary = matches.filter { $0.isPrimary }
        let rest = matches.filter { !$0.isPrimary }
        return Array((primary + rest).prefix(limit))
    }

    static let builtIn: [SajuCity] = [
        // FR-5.3 기본 도시 (표시 순서 유지)
        SajuCity(id: "SEOUL", name: "서울특별시", longitude: 126.9780, isPrimary: true),
        SajuCity(id: "BUSAN", name: "부산광역시", longitude: 129.0756, isPrimary: true),
        SajuCity(id: "INCHEON", name: "인천광역시", longitude: 126.7052, isPrimary: true),
        SajuCity(id: "DAEGU", name: "대구광역시", longitude: 128.6014, isPrimary: true),
        SajuCity(id: "GWANGJU", name: "광주광역시", longitude: 126.8514, isPrimary: true),
        SajuCity(id: "DAEJEON", name: "대전광역시", longitude: 127.3845, isPrimary: true),

        // 검색용 추가 시/군/구 (스텁)
        SajuCity(id: "ULSAN", name: "울산광역시", longitude: 129.3114, isPrimary: false),
        SajuCity(id: "SEJONG", name: "세종특별자치시", longitude: 127.2890, isPrimary: false),
        SajuCity(id: "SUWON", name: "수원시", longitude: 127.0286, isPrimary: false),
        SajuCity(id: "SEONGNAM", name: "성남시", longitude: 127.1378, isPrimary: false),
        SajuCity(id: "GOYANG", name: "고양시", longitude: 126.8320, isPrimary: false),
        SajuCity(id: "YONGIN", name: "용인시", longitude: 127.1776, isPrimary: false),
        SajuCity(id: "CHEONGJU", name: "청주시", longitude: 127.4890, isPrimary: false),
        SajuCity(id: "JEONJU", name: "전주시", longitude: 127.1480, isPrimary: false),
        SajuCity(id: "POHANG", name: "포항시", longitude: 129.3435, isPrimary: false),
        SajuCity(id: "CHANGWON", name: "창원시", longitude: 128.6811, isPrimary: false),
        SajuCity(id: "JEJU", name: "제주시", longitude: 126.5312, isPrimary: false),
        SajuCity(id: "CHUNCHEON", name: "춘천시", longitude: 127.7298, isPrimary: false),
        SajuCity(id: "GANGNEUNG", name: "강릉시", longitude: 128.8761, isPrimary: false),
        SajuCity(id: "MOKPO", name: "목포시", longitude: 126.3920, isPrimary: false)
    ]
}
