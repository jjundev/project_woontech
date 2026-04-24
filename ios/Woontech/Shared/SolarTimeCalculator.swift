import Foundation

/// 진태양시 보정 계산기 (1차 스텁).
/// 실제 Swiss Ephemeris 기반 균시차 계산은 추후 교체 가능.
struct SolarTimeCorrectionResult: Equatable {
    /// 경도 기반 표준시 차이(분). 서울(127°)·표준 135° → 약 −32분.
    var offsetMinutes: Int
    var correctedHour: Int
    var correctedMinute: Int
}

enum SolarTimeCalculator {
    /// 한국 표준시의 기준 자오선. 135°E (UTC+9).
    static let koreaStandardMeridian: Double = 135.0

    /// 경도 기반 표준시 차이를 분 단위로 계산.
    /// 1° ≈ 4분. 서울 127° → (127 − 135) × 4 = −32분.
    static func offsetMinutes(longitude: Double, standardMeridian: Double = koreaStandardMeridian) -> Int {
        let minutes = (longitude - standardMeridian) * 4.0
        return Int(minutes.rounded())
    }

    /// 전체 보정 결과(경도 차이 분 + 보정 시:분).
    static func correct(
        hour: Int,
        minute: Int,
        longitude: Double,
        standardMeridian: Double = koreaStandardMeridian
    ) -> SolarTimeCorrectionResult {
        let offset = offsetMinutes(longitude: longitude, standardMeridian: standardMeridian)
        let totalMinutes = hour * 60 + minute + offset
        // Normalize into 24h range.
        var normalized = totalMinutes % (24 * 60)
        if normalized < 0 { normalized += 24 * 60 }
        let h = normalized / 60
        let m = normalized % 60
        return SolarTimeCorrectionResult(
            offsetMinutes: offset,
            correctedHour: h,
            correctedMinute: m
        )
    }
}
