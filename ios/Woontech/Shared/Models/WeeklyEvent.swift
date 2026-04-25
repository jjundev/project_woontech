import Foundation

// MARK: - WeeklyEvent Model

struct WeeklyEvent: Hashable, Identifiable, Codable {
    let id: UUID
    let type: EventType
    let icon: String
    let title: String
    let hanja: String?
    let dday: Int
    let ddayDate: String
    let impact: Impact
    let oneLiner: String
    let investContext: String
    let badge: String?
    let timeGroup: TimeGroup

    init(
        id: UUID = UUID(),
        type: EventType,
        icon: String,
        title: String,
        hanja: String? = nil,
        dday: Int,
        ddayDate: String,
        impact: Impact,
        oneLiner: String,
        investContext: String,
        badge: String? = nil,
        timeGroup: TimeGroup
    ) {
        self.id = id
        self.type = type
        self.icon = icon
        self.title = title
        self.hanja = hanja
        self.dday = dday
        self.ddayDate = ddayDate
        self.impact = impact
        self.oneLiner = oneLiner
        self.investContext = investContext
        self.badge = badge
        self.timeGroup = timeGroup
    }
}

// MARK: - EventType Enum

enum EventType: String, Codable, CaseIterable {
    case daewoon = "daewoon"
    case jeolgi = "jeolgi"
    case hapchung = "hapchung"
    case special = "special"
}

// MARK: - Impact Enum

enum Impact: String, Codable, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
}

// MARK: - TimeGroup Enum

enum TimeGroup: String, Codable, CaseIterable {
    case thisWeek = "이번 주"
    case thisMonth = "이번 달"
    case within3Months = "3개월 이내"

    var displayName: String {
        self.rawValue
    }
}
