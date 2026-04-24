import Foundation

/// 국내 전체 시/군/구 고정 경도 테이블.
/// FR-5.3(기본 6개), FR-5.4(검색 — 전국 시/군/구).
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

    // MARK: - 전국 시/군/구 경도 데이터 (시청/구청/군청 대표 좌표)

    static let builtIn: [SajuCity] = [

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: FR-5.3 기본 도시 (표시 순서 유지)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "SEOUL",   name: "서울특별시",     longitude: 126.9780, isPrimary: true),
        SajuCity(id: "BUSAN",   name: "부산광역시",     longitude: 129.0756, isPrimary: true),
        SajuCity(id: "INCHEON", name: "인천광역시",     longitude: 126.7052, isPrimary: true),
        SajuCity(id: "DAEGU",   name: "대구광역시",     longitude: 128.6014, isPrimary: true),
        SajuCity(id: "GWANGJU", name: "광주광역시",     longitude: 126.8514, isPrimary: true),
        SajuCity(id: "DAEJEON", name: "대전광역시",     longitude: 127.3845, isPrimary: true),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 기타 광역자치단체
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "ULSAN",  name: "울산광역시",       longitude: 129.3114, isPrimary: false),
        SajuCity(id: "SEJONG", name: "세종특별자치시",   longitude: 127.2890, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 서울특별시 자치구 (25)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "SEOUL_JONGNO",     name: "서울 종로구",   longitude: 126.9816, isPrimary: false),
        SajuCity(id: "SEOUL_JUNG",       name: "서울 중구",     longitude: 126.9978, isPrimary: false),
        SajuCity(id: "SEOUL_YONGSAN",    name: "서울 용산구",   longitude: 126.9653, isPrimary: false),
        SajuCity(id: "SEOUL_SEONGDONG",  name: "서울 성동구",   longitude: 127.0366, isPrimary: false),
        SajuCity(id: "SEOUL_GWANGJIN",   name: "서울 광진구",   longitude: 127.0823, isPrimary: false),
        SajuCity(id: "SEOUL_DONGDAEMUN", name: "서울 동대문구", longitude: 127.0398, isPrimary: false),
        SajuCity(id: "SEOUL_JUNGNANG",   name: "서울 중랑구",   longitude: 127.0928, isPrimary: false),
        SajuCity(id: "SEOUL_SEONGBUK",   name: "서울 성북구",   longitude: 127.0176, isPrimary: false),
        SajuCity(id: "SEOUL_GANGBUK",    name: "서울 강북구",   longitude: 127.0115, isPrimary: false),
        SajuCity(id: "SEOUL_DOBONG",     name: "서울 도봉구",   longitude: 127.0472, isPrimary: false),
        SajuCity(id: "SEOUL_NOWON",      name: "서울 노원구",   longitude: 127.0564, isPrimary: false),
        SajuCity(id: "SEOUL_EUNPYEONG",  name: "서울 은평구",   longitude: 126.9293, isPrimary: false),
        SajuCity(id: "SEOUL_SEODAEMUN",  name: "서울 서대문구", longitude: 126.9388, isPrimary: false),
        SajuCity(id: "SEOUL_MAPO",       name: "서울 마포구",   longitude: 126.9011, isPrimary: false),
        SajuCity(id: "SEOUL_YANGCHEON",  name: "서울 양천구",   longitude: 126.8665, isPrimary: false),
        SajuCity(id: "SEOUL_GANGSEO",    name: "서울 강서구",   longitude: 126.8228, isPrimary: false),
        SajuCity(id: "SEOUL_GURO",       name: "서울 구로구",   longitude: 126.8562, isPrimary: false),
        SajuCity(id: "SEOUL_GEUMCHEON",  name: "서울 금천구",   longitude: 126.8955, isPrimary: false),
        SajuCity(id: "SEOUL_YEONGDEUNGPO", name: "서울 영등포구", longitude: 126.8964, isPrimary: false),
        SajuCity(id: "SEOUL_DONGJAK",    name: "서울 동작구",   longitude: 126.9517, isPrimary: false),
        SajuCity(id: "SEOUL_GWANAK",     name: "서울 관악구",   longitude: 126.9518, isPrimary: false),
        SajuCity(id: "SEOUL_SEOCHO",     name: "서울 서초구",   longitude: 127.0088, isPrimary: false),
        SajuCity(id: "SEOUL_GANGNAM",    name: "서울 강남구",   longitude: 127.0474, isPrimary: false),
        SajuCity(id: "SEOUL_SONGPA",     name: "서울 송파구",   longitude: 127.1059, isPrimary: false),
        SajuCity(id: "SEOUL_GANGDONG",   name: "서울 강동구",   longitude: 127.1237, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 부산광역시 구/군 (16)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "BUSAN_JUNG",      name: "부산 중구",     longitude: 129.0328, isPrimary: false),
        SajuCity(id: "BUSAN_SEO",       name: "부산 서구",     longitude: 129.0241, isPrimary: false),
        SajuCity(id: "BUSAN_DONG",      name: "부산 동구",     longitude: 129.0451, isPrimary: false),
        SajuCity(id: "BUSAN_YEONGDO",   name: "부산 영도구",   longitude: 129.0668, isPrimary: false),
        SajuCity(id: "BUSAN_BUSANJIN",  name: "부산 부산진구", longitude: 129.0563, isPrimary: false),
        SajuCity(id: "BUSAN_DONGNAE",   name: "부산 동래구",   longitude: 129.0858, isPrimary: false),
        SajuCity(id: "BUSAN_NAM",       name: "부산 남구",     longitude: 129.0833, isPrimary: false),
        SajuCity(id: "BUSAN_BUK",       name: "부산 북구",     longitude: 129.0326, isPrimary: false),
        SajuCity(id: "BUSAN_HAEUNDAE",  name: "부산 해운대구", longitude: 129.1604, isPrimary: false),
        SajuCity(id: "BUSAN_SAHA",      name: "부산 사하구",   longitude: 128.9746, isPrimary: false),
        SajuCity(id: "BUSAN_GEUMJEONG", name: "부산 금정구",   longitude: 129.0922, isPrimary: false),
        SajuCity(id: "BUSAN_GANGSEO",   name: "부산 강서구",   longitude: 128.9385, isPrimary: false),
        SajuCity(id: "BUSAN_YEONJE",    name: "부산 연제구",   longitude: 129.0797, isPrimary: false),
        SajuCity(id: "BUSAN_SUYEONG",   name: "부산 수영구",   longitude: 129.1133, isPrimary: false),
        SajuCity(id: "BUSAN_SASANG",    name: "부산 사상구",   longitude: 128.9828, isPrimary: false),
        SajuCity(id: "BUSAN_GIJANG",    name: "부산 기장군",   longitude: 129.2189, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 대구광역시 구/군 (8)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "DAEGU_JUNG",      name: "대구 중구",     longitude: 128.6061, isPrimary: false),
        SajuCity(id: "DAEGU_DONG",      name: "대구 동구",     longitude: 128.6524, isPrimary: false),
        SajuCity(id: "DAEGU_SEO",       name: "대구 서구",     longitude: 128.5591, isPrimary: false),
        SajuCity(id: "DAEGU_NAM",       name: "대구 남구",     longitude: 128.5973, isPrimary: false),
        SajuCity(id: "DAEGU_BUK",       name: "대구 북구",     longitude: 128.5829, isPrimary: false),
        SajuCity(id: "DAEGU_SUSEONG",   name: "대구 수성구",   longitude: 128.6317, isPrimary: false),
        SajuCity(id: "DAEGU_DALSEO",    name: "대구 달서구",   longitude: 128.5327, isPrimary: false),
        SajuCity(id: "DAEGU_DALSEONG",  name: "대구 달성군",   longitude: 128.4314, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 인천광역시 구/군 (10)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "INCHEON_JUNG",      name: "인천 중구",     longitude: 126.6218, isPrimary: false),
        SajuCity(id: "INCHEON_DONG",      name: "인천 동구",     longitude: 126.6438, isPrimary: false),
        SajuCity(id: "INCHEON_MICHUHOL",  name: "인천 미추홀구", longitude: 126.6502, isPrimary: false),
        SajuCity(id: "INCHEON_YEONSU",    name: "인천 연수구",   longitude: 126.6780, isPrimary: false),
        SajuCity(id: "INCHEON_NAMDONG",   name: "인천 남동구",   longitude: 126.7310, isPrimary: false),
        SajuCity(id: "INCHEON_BUPYEONG",  name: "인천 부평구",   longitude: 126.7217, isPrimary: false),
        SajuCity(id: "INCHEON_GYEYANG",   name: "인천 계양구",   longitude: 126.7368, isPrimary: false),
        SajuCity(id: "INCHEON_SEO",       name: "인천 서구",     longitude: 126.6762, isPrimary: false),
        SajuCity(id: "INCHEON_GANGHWA",   name: "인천 강화군",   longitude: 126.4879, isPrimary: false),
        SajuCity(id: "INCHEON_ONGJIN",    name: "인천 옹진군",   longitude: 126.6360, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 광주광역시 구 (5)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "GWANGJU_DONG",     name: "광주 동구",     longitude: 126.9231, isPrimary: false),
        SajuCity(id: "GWANGJU_SEO",      name: "광주 서구",     longitude: 126.8897, isPrimary: false),
        SajuCity(id: "GWANGJU_NAM",      name: "광주 남구",     longitude: 126.9025, isPrimary: false),
        SajuCity(id: "GWANGJU_BUK",      name: "광주 북구",     longitude: 126.9120, isPrimary: false),
        SajuCity(id: "GWANGJU_GWANGSAN", name: "광주 광산구",   longitude: 126.7946, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 대전광역시 구 (5)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "DAEJEON_DONG",    name: "대전 동구",     longitude: 127.4557, isPrimary: false),
        SajuCity(id: "DAEJEON_JUNG",    name: "대전 중구",     longitude: 127.4215, isPrimary: false),
        SajuCity(id: "DAEJEON_SEO",     name: "대전 서구",     longitude: 127.3716, isPrimary: false),
        SajuCity(id: "DAEJEON_YUSEONG", name: "대전 유성구",   longitude: 127.3561, isPrimary: false),
        SajuCity(id: "DAEJEON_DAEDEOK", name: "대전 대덕구",   longitude: 127.4164, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 울산광역시 구/군 (5)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "ULSAN_JUNG",  name: "울산 중구",     longitude: 129.3320, isPrimary: false),
        SajuCity(id: "ULSAN_NAM",   name: "울산 남구",     longitude: 129.3228, isPrimary: false),
        SajuCity(id: "ULSAN_DONG",  name: "울산 동구",     longitude: 129.4175, isPrimary: false),
        SajuCity(id: "ULSAN_BUK",   name: "울산 북구",     longitude: 129.3616, isPrimary: false),
        SajuCity(id: "ULSAN_ULJU",  name: "울산 울주군",   longitude: 129.2425, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 경기도 (31)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "SUWON",       name: "수원시",       longitude: 127.0286, isPrimary: false),
        SajuCity(id: "SEONGNAM",    name: "성남시",       longitude: 127.1378, isPrimary: false),
        SajuCity(id: "GOYANG",      name: "고양시",       longitude: 126.8320, isPrimary: false),
        SajuCity(id: "YONGIN",      name: "용인시",       longitude: 127.1776, isPrimary: false),
        SajuCity(id: "BUCHEON",     name: "부천시",       longitude: 126.7660, isPrimary: false),
        SajuCity(id: "ANSAN",       name: "안산시",       longitude: 126.8309, isPrimary: false),
        SajuCity(id: "ANYANG",      name: "안양시",       longitude: 126.9517, isPrimary: false),
        SajuCity(id: "NAMYANGJU",   name: "남양주시",     longitude: 127.2162, isPrimary: false),
        SajuCity(id: "HWASEONG",    name: "화성시",       longitude: 126.8312, isPrimary: false),
        SajuCity(id: "PYEONGTAEK",  name: "평택시",       longitude: 127.1126, isPrimary: false),
        SajuCity(id: "UIJEONGBU",   name: "의정부시",     longitude: 127.0337, isPrimary: false),
        SajuCity(id: "SIHEUNG",     name: "시흥시",       longitude: 126.8019, isPrimary: false),
        SajuCity(id: "PAJU",        name: "파주시",       longitude: 126.7798, isPrimary: false),
        SajuCity(id: "GIMPO",       name: "김포시",       longitude: 126.7153, isPrimary: false),
        SajuCity(id: "GWANGMYEONG", name: "광명시",       longitude: 126.8664, isPrimary: false),
        SajuCity(id: "GWANGJU_GG",  name: "광주시",       longitude: 127.2552, isPrimary: false),
        SajuCity(id: "GUNPO",       name: "군포시",       longitude: 126.9354, isPrimary: false),
        SajuCity(id: "HANAM",       name: "하남시",       longitude: 127.2146, isPrimary: false),
        SajuCity(id: "OSAN",        name: "오산시",       longitude: 127.0769, isPrimary: false),
        SajuCity(id: "ICHEON",      name: "이천시",       longitude: 127.4353, isPrimary: false),
        SajuCity(id: "ANSEONG",     name: "안성시",       longitude: 127.2793, isPrimary: false),
        SajuCity(id: "UIWANG",      name: "의왕시",       longitude: 126.9686, isPrimary: false),
        SajuCity(id: "YANGJU",      name: "양주시",       longitude: 127.0458, isPrimary: false),
        SajuCity(id: "GURI",        name: "구리시",       longitude: 127.1296, isPrimary: false),
        SajuCity(id: "POCHEON",     name: "포천시",       longitude: 127.2005, isPrimary: false),
        SajuCity(id: "DONGDUCHEON", name: "동두천시",     longitude: 127.0607, isPrimary: false),
        SajuCity(id: "YEOJU",       name: "여주시",       longitude: 127.6372, isPrimary: false),
        SajuCity(id: "GWACHEON",    name: "과천시",       longitude: 126.9876, isPrimary: false),
        SajuCity(id: "YANGPYEONG",  name: "양평군",       longitude: 127.4868, isPrimary: false),
        SajuCity(id: "GAPYEONG",    name: "가평군",       longitude: 127.5096, isPrimary: false),
        SajuCity(id: "YEONCHEON",   name: "연천군",       longitude: 127.0754, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 강원특별자치도 (18)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "CHUNCHEON",  name: "춘천시",   longitude: 127.7298, isPrimary: false),
        SajuCity(id: "WONJU",      name: "원주시",   longitude: 127.9204, isPrimary: false),
        SajuCity(id: "GANGNEUNG",  name: "강릉시",   longitude: 128.8761, isPrimary: false),
        SajuCity(id: "DONGHAE",    name: "동해시",   longitude: 129.1144, isPrimary: false),
        SajuCity(id: "TAEBAEK",    name: "태백시",   longitude: 128.9858, isPrimary: false),
        SajuCity(id: "SOKCHO",     name: "속초시",   longitude: 128.5917, isPrimary: false),
        SajuCity(id: "SAMCHEOK",   name: "삼척시",   longitude: 129.1648, isPrimary: false),
        SajuCity(id: "HONGCHEON",  name: "홍천군",   longitude: 127.8886, isPrimary: false),
        SajuCity(id: "HOENGSEONG", name: "횡성군",   longitude: 127.9846, isPrimary: false),
        SajuCity(id: "YEONGWOL",   name: "영월군",   longitude: 128.4616, isPrimary: false),
        SajuCity(id: "PYEONGCHANG", name: "평창군",  longitude: 128.3901, isPrimary: false),
        SajuCity(id: "JEONGSEON",  name: "정선군",   longitude: 128.6608, isPrimary: false),
        SajuCity(id: "CHEORWON",   name: "철원군",   longitude: 127.3133, isPrimary: false),
        SajuCity(id: "HWACHEON",   name: "화천군",   longitude: 127.7079, isPrimary: false),
        SajuCity(id: "YANGGU",     name: "양구군",   longitude: 127.9897, isPrimary: false),
        SajuCity(id: "INJE",       name: "인제군",   longitude: 128.1706, isPrimary: false),
        SajuCity(id: "GW_GOSEONG", name: "고성군 (강원)", longitude: 128.4677, isPrimary: false),
        SajuCity(id: "YANGYANG",   name: "양양군",   longitude: 128.6186, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 충청북도 (11)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "CHEONGJU",   name: "청주시",   longitude: 127.4890, isPrimary: false),
        SajuCity(id: "CHUNGJU",    name: "충주시",   longitude: 127.9260, isPrimary: false),
        SajuCity(id: "JECHEON",    name: "제천시",   longitude: 128.1910, isPrimary: false),
        SajuCity(id: "BOEUN",      name: "보은군",   longitude: 127.7293, isPrimary: false),
        SajuCity(id: "OKCHEON",    name: "옥천군",   longitude: 127.5710, isPrimary: false),
        SajuCity(id: "YEONGDONG",  name: "영동군",   longitude: 127.7836, isPrimary: false),
        SajuCity(id: "JEUNGPYEONG", name: "증평군",  longitude: 127.5820, isPrimary: false),
        SajuCity(id: "JINCHEON",   name: "진천군",   longitude: 127.4366, isPrimary: false),
        SajuCity(id: "GOESAN",     name: "괴산군",   longitude: 127.7863, isPrimary: false),
        SajuCity(id: "EUMSEONG",   name: "음성군",   longitude: 127.6904, isPrimary: false),
        SajuCity(id: "DANYANG",    name: "단양군",   longitude: 128.3655, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 충청남도 (15)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "CHEONAN",    name: "천안시",   longitude: 127.1522, isPrimary: false),
        SajuCity(id: "GONGJU",     name: "공주시",   longitude: 127.1189, isPrimary: false),
        SajuCity(id: "BORYEONG",   name: "보령시",   longitude: 126.6125, isPrimary: false),
        SajuCity(id: "ASAN",       name: "아산시",   longitude: 126.9784, isPrimary: false),
        SajuCity(id: "SEOSAN",     name: "서산시",   longitude: 126.4501, isPrimary: false),
        SajuCity(id: "NONSAN",     name: "논산시",   longitude: 127.0986, isPrimary: false),
        SajuCity(id: "GYERYONG",   name: "계룡시",   longitude: 127.2487, isPrimary: false),
        SajuCity(id: "DANGJIN",    name: "당진시",   longitude: 126.6297, isPrimary: false),
        SajuCity(id: "GEUMSAN",    name: "금산군",   longitude: 127.4872, isPrimary: false),
        SajuCity(id: "BUYEO",      name: "부여군",   longitude: 126.9098, isPrimary: false),
        SajuCity(id: "SEOCHEON",   name: "서천군",   longitude: 126.6913, isPrimary: false),
        SajuCity(id: "CHEONGYANG", name: "청양군",   longitude: 126.8023, isPrimary: false),
        SajuCity(id: "HONGSEONG",  name: "홍성군",   longitude: 126.6611, isPrimary: false),
        SajuCity(id: "YESAN",      name: "예산군",   longitude: 126.8481, isPrimary: false),
        SajuCity(id: "TAEAN",      name: "태안군",   longitude: 126.2979, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 전북특별자치도 (14)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "JEONJU",     name: "전주시",   longitude: 127.1480, isPrimary: false),
        SajuCity(id: "GUNSAN",     name: "군산시",   longitude: 126.7367, isPrimary: false),
        SajuCity(id: "IKSAN",      name: "익산시",   longitude: 126.9577, isPrimary: false),
        SajuCity(id: "JEONGEUP",   name: "정읍시",   longitude: 126.8560, isPrimary: false),
        SajuCity(id: "NAMWON",     name: "남원시",   longitude: 127.3901, isPrimary: false),
        SajuCity(id: "GIMJE",      name: "김제시",   longitude: 126.8808, isPrimary: false),
        SajuCity(id: "WANJU",      name: "완주군",   longitude: 127.1621, isPrimary: false),
        SajuCity(id: "JINAN",      name: "진안군",   longitude: 127.4248, isPrimary: false),
        SajuCity(id: "MUJU",       name: "무주군",   longitude: 127.6604, isPrimary: false),
        SajuCity(id: "JANGSU",     name: "장수군",   longitude: 127.5213, isPrimary: false),
        SajuCity(id: "IMSIL",      name: "임실군",   longitude: 127.2793, isPrimary: false),
        SajuCity(id: "SUNCHANG",   name: "순창군",   longitude: 127.1375, isPrimary: false),
        SajuCity(id: "GOCHANG",    name: "고창군",   longitude: 126.7020, isPrimary: false),
        SajuCity(id: "BUAN",       name: "부안군",   longitude: 126.7327, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 전라남도 (22)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "MOKPO",      name: "목포시",   longitude: 126.3920, isPrimary: false),
        SajuCity(id: "YEOSU",      name: "여수시",   longitude: 127.6626, isPrimary: false),
        SajuCity(id: "SUNCHEON",   name: "순천시",   longitude: 127.4872, isPrimary: false),
        SajuCity(id: "NAJU",       name: "나주시",   longitude: 126.7109, isPrimary: false),
        SajuCity(id: "GWANGYANG",  name: "광양시",   longitude: 127.5855, isPrimary: false),
        SajuCity(id: "DAMYANG",    name: "담양군",   longitude: 126.9882, isPrimary: false),
        SajuCity(id: "GOKSEONG",   name: "곡성군",   longitude: 127.2925, isPrimary: false),
        SajuCity(id: "GURYE",      name: "구례군",   longitude: 127.4629, isPrimary: false),
        SajuCity(id: "GOHEUNG",    name: "고흥군",   longitude: 127.2753, isPrimary: false),
        SajuCity(id: "BOSEONG",    name: "보성군",   longitude: 127.0802, isPrimary: false),
        SajuCity(id: "HWASUN",     name: "화순군",   longitude: 126.9862, isPrimary: false),
        SajuCity(id: "JANGHEUNG",  name: "장흥군",   longitude: 126.9069, isPrimary: false),
        SajuCity(id: "GANGJIN",    name: "강진군",   longitude: 126.7672, isPrimary: false),
        SajuCity(id: "HAENAM",     name: "해남군",   longitude: 126.5995, isPrimary: false),
        SajuCity(id: "YEONGAM",    name: "영암군",   longitude: 126.6969, isPrimary: false),
        SajuCity(id: "MUAN",       name: "무안군",   longitude: 126.4817, isPrimary: false),
        SajuCity(id: "HAMPYEONG",  name: "함평군",   longitude: 126.5164, isPrimary: false),
        SajuCity(id: "YEONGGWANG", name: "영광군",   longitude: 126.5118, isPrimary: false),
        SajuCity(id: "JANGSEONG",  name: "장성군",   longitude: 126.7847, isPrimary: false),
        SajuCity(id: "WANDO",      name: "완도군",   longitude: 126.7550, isPrimary: false),
        SajuCity(id: "JINDO",      name: "진도군",   longitude: 126.2632, isPrimary: false),
        SajuCity(id: "SINAN",      name: "신안군",   longitude: 126.1071, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 경상북도 (23)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "POHANG",     name: "포항시",   longitude: 129.3435, isPrimary: false),
        SajuCity(id: "GYEONGJU",   name: "경주시",   longitude: 129.2249, isPrimary: false),
        SajuCity(id: "GIMCHEON",   name: "김천시",   longitude: 128.1135, isPrimary: false),
        SajuCity(id: "ANDONG",     name: "안동시",   longitude: 128.7298, isPrimary: false),
        SajuCity(id: "GUMI",       name: "구미시",   longitude: 128.3444, isPrimary: false),
        SajuCity(id: "YEONGJU",    name: "영주시",   longitude: 128.6239, isPrimary: false),
        SajuCity(id: "YEONGCHEON", name: "영천시",   longitude: 128.9384, isPrimary: false),
        SajuCity(id: "SANGJU",     name: "상주시",   longitude: 128.1567, isPrimary: false),
        SajuCity(id: "MUNGYEONG",  name: "문경시",   longitude: 128.1867, isPrimary: false),
        SajuCity(id: "GYEONGSAN",  name: "경산시",   longitude: 128.7363, isPrimary: false),
        SajuCity(id: "UISEONG",    name: "의성군",   longitude: 128.6974, isPrimary: false),
        SajuCity(id: "CHEONGSONG", name: "청송군",   longitude: 129.0571, isPrimary: false),
        SajuCity(id: "YEONGYANG",  name: "영양군",   longitude: 129.1124, isPrimary: false),
        SajuCity(id: "YEONGDEOK",  name: "영덕군",   longitude: 129.3665, isPrimary: false),
        SajuCity(id: "CHEONGDO",   name: "청도군",   longitude: 128.7340, isPrimary: false),
        SajuCity(id: "GORYEONG",   name: "고령군",   longitude: 128.2624, isPrimary: false),
        SajuCity(id: "SEONGJU",    name: "성주군",   longitude: 128.2831, isPrimary: false),
        SajuCity(id: "CHILGOK",    name: "칠곡군",   longitude: 128.4015, isPrimary: false),
        SajuCity(id: "YECHEON",    name: "예천군",   longitude: 128.4528, isPrimary: false),
        SajuCity(id: "BONGHWA",    name: "봉화군",   longitude: 128.7323, isPrimary: false),
        SajuCity(id: "ULJIN",      name: "울진군",   longitude: 129.4005, isPrimary: false),
        SajuCity(id: "ULLEUNG",    name: "울릉군",   longitude: 130.9057, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 경상남도 (18)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "CHANGWON",   name: "창원시",   longitude: 128.6811, isPrimary: false),
        SajuCity(id: "JINJU",      name: "진주시",   longitude: 128.1088, isPrimary: false),
        SajuCity(id: "TONGYEONG",  name: "통영시",   longitude: 128.4330, isPrimary: false),
        SajuCity(id: "SACHEON",    name: "사천시",   longitude: 128.0644, isPrimary: false),
        SajuCity(id: "GIMHAE",     name: "김해시",   longitude: 128.8893, isPrimary: false),
        SajuCity(id: "MIRYANG",    name: "밀양시",   longitude: 128.7527, isPrimary: false),
        SajuCity(id: "GEOJE",      name: "거제시",   longitude: 128.6213, isPrimary: false),
        SajuCity(id: "YANGSAN",    name: "양산시",   longitude: 129.0370, isPrimary: false),
        SajuCity(id: "UIRYEONG",   name: "의령군",   longitude: 128.2614, isPrimary: false),
        SajuCity(id: "HAMAN",      name: "함안군",   longitude: 128.4063, isPrimary: false),
        SajuCity(id: "CHANGNYEONG", name: "창녕군",  longitude: 128.4919, isPrimary: false),
        SajuCity(id: "GN_GOSEONG", name: "고성군 (경남)", longitude: 128.3223, isPrimary: false),
        SajuCity(id: "NAMHAE",     name: "남해군",   longitude: 127.8926, isPrimary: false),
        SajuCity(id: "HADONG",     name: "하동군",   longitude: 127.7511, isPrimary: false),
        SajuCity(id: "SANCHEONG",  name: "산청군",   longitude: 127.8734, isPrimary: false),
        SajuCity(id: "HAMYANG",    name: "함양군",   longitude: 127.7253, isPrimary: false),
        SajuCity(id: "GEOCHANG",   name: "거창군",   longitude: 127.9097, isPrimary: false),
        SajuCity(id: "HAPCHEON",   name: "합천군",   longitude: 128.1658, isPrimary: false),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 제주특별자치도 (2)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        SajuCity(id: "JEJU",       name: "제주시",   longitude: 126.5312, isPrimary: false),
        SajuCity(id: "SEOGWIPO",   name: "서귀포시", longitude: 126.5122, isPrimary: false),
    ]
}
