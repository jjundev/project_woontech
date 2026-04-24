import Foundation

protocol NotificationCenterProviding {
    var unreadCount: Int { get }
}

struct MockNotificationCenterProvider: NotificationCenterProviding {
    var unreadCount: Int

    init(unreadCount: Int = 2) {
        self.unreadCount = unreadCount
    }
}
