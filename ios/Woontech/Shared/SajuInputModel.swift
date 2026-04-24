import Foundation

// MARK: - Gender

enum Gender: String, Codable, CaseIterable, Equatable {
    case male
    case female
}

// MARK: - Calendar Kind

enum CalendarKind: Codable, Equatable {
    case solar
    case lunar(leap: Bool)

    var isSolar: Bool {
        if case .solar = self { return true }
        return false
    }

    var isLunar: Bool {
        if case .lunar = self { return true }
        return false
    }

    var isLeap: Bool {
        if case .lunar(let leap) = self { return leap }
        return false
    }
}

// MARK: - Birth Date

struct BirthDate: Codable, Equatable {
    var year: Int
    var month: Int
    var day: Int
    var kind: CalendarKind

    static let `default` = BirthDate(year: 1990, month: 3, day: 15, kind: .solar)

    static let yearLowerBound = 1900

    static func yearUpperBound(calendar: Calendar = .current, now: Date = Date()) -> Int {
        calendar.component(.year, from: now)
    }

    static func yearRange(calendar: Calendar = .current, now: Date = Date()) -> ClosedRange<Int> {
        yearLowerBound...yearUpperBound(calendar: calendar, now: now)
    }

    /// Returns the number of valid days for the given (year, month) under a proleptic
    /// Gregorian calendar. Used for filtering invalid date combinations (e.g. Feb 30).
    static func daysInMonth(year: Int, month: Int) -> Int {
        guard (1...12).contains(month) else { return 0 }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        if let date = cal.date(from: comps),
           let range = cal.range(of: .day, in: .month, for: date) {
            return range.count
        }
        return 30
    }

    static func isValid(year: Int, month: Int, day: Int) -> Bool {
        guard yearRange().contains(year) else { return false }
        guard (1...12).contains(month) else { return false }
        return (1...daysInMonth(year: year, month: month)).contains(day)
    }
}

// MARK: - Birth Time

struct BirthTime: Codable, Equatable {
    var hour: Int
    var minute: Int
    var hourKnown: Bool

    static let `default` = BirthTime(hour: 12, minute: 0, hourKnown: true)
}

// MARK: - Birth Place

enum BirthPlace: Codable, Equatable {
    case domestic(cityID: String)
    case overseas(longitude: Double)

    var isDomestic: Bool {
        if case .domestic = self { return true }
        return false
    }

    var isOverseas: Bool {
        if case .overseas = self { return true }
        return false
    }

    /// Whether the overseas longitude (if any) is within the valid −180…180 range.
    var isValid: Bool {
        switch self {
        case .domestic(let cityID):
            return CityCatalog.shared.city(withID: cityID) != nil
        case .overseas(let lon):
            return BirthPlace.isLongitudeValid(lon)
        }
    }

    static func isLongitudeValid(_ lon: Double) -> Bool {
        guard lon.isFinite else { return false }
        return lon >= -180.0 && lon <= 180.0
    }
}

// MARK: - Solar Time Correction

struct SolarTimeCorrection: Codable, Equatable {
    var enabled: Bool

    static let `default` = SolarTimeCorrection(enabled: true)
}

// MARK: - Accuracy Level

enum AccuracyLevel: String, Codable, Equatable {
    /// 시간·출생지·진태양시 모두 입력/보정
    case high
    /// 시간 입력 (진태양시 OFF or overseas 기본)
    case medium
    /// 시간 미입력
    case mediumAddTime
}

// MARK: - Saju Input Model

struct SajuInputModel: Codable, Equatable {
    var gender: Gender?
    var name: String
    var birthDate: BirthDate
    var birthTime: BirthTime
    var birthPlace: BirthPlace
    var solarTime: SolarTimeCorrection

    static let `default` = SajuInputModel(
        gender: nil,
        name: "",
        birthDate: .default,
        birthTime: .default,
        birthPlace: .domestic(cityID: ""),
        solarTime: .default
    )

    // MARK: Name helpers

    static let maxNameLength = 20

    /// Trim trailing whitespace and clamp to 20 chars.
    static func sanitizeName(_ raw: String) -> String {
        var s = raw
        if s.count > maxNameLength {
            s = String(s.prefix(maxNameLength))
        }
        return s
    }

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Step 8 hero label: "{이름}님의 투자 성향", with 10-char truncation + ellipsis,
    /// fallback "당신의 투자 성향" when empty. Implements FR-8.3 / AC-16.
    var displayNameLabel: String {
        let n = normalizedName
        if n.isEmpty { return "당신의 투자 성향" }
        let display: String
        if n.count > 10 {
            display = String(n.prefix(8)) + "…"
        } else {
            display = n
        }
        return "\(display)님의 투자 성향"
    }

    /// Accuracy badge rule — FR-8.4 / AC-17.
    var accuracy: AccuracyLevel {
        if !birthTime.hourKnown { return .mediumAddTime }
        if birthPlace.isValid && solarTime.enabled { return .high }
        return .medium
    }

    // MARK: Per-step completion predicates

    var isGenderComplete: Bool { gender != nil }

    var isNameComplete: Bool {
        !normalizedName.isEmpty
    }

    var isBirthDateComplete: Bool {
        BirthDate.isValid(year: birthDate.year, month: birthDate.month, day: birthDate.day)
    }

    var isBirthTimeComplete: Bool {
        if !birthTime.hourKnown { return true }
        return (0...23).contains(birthTime.hour) && (0...59).contains(birthTime.minute)
    }

    var isBirthPlaceComplete: Bool {
        birthPlace.isValid
    }

    /// Step 6 CTA is always enabled per FR-6.6.
    var isSolarTimeStepComplete: Bool { true }
}
