import Foundation

struct WeeklyEvent: Hashable, Identifiable {
    let id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}

enum HomeRoute: Hashable {
    case investing
    case event(WeeklyEvent)
    case today
    case tabooPlaceholder
    case practicePlaceholder
}
