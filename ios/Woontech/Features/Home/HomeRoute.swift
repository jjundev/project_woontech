import Foundation

enum HomeRoute: Hashable {
    case investing
    case event(WeeklyEvent)
    case today
    case tabooPlaceholder
    case practicePlaceholder
}
