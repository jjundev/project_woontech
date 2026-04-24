import Foundation

protocol UserProfileProviding {
    var displayName: String { get }
    var avatarInitial: String { get }
}

struct MockUserProfileProvider: UserProfileProviding {
    var displayName: String
    var avatarInitial: String

    init(displayName: String = "홍길동", avatarInitial: String = "홍") {
        self.displayName = displayName
        self.avatarInitial = avatarInitial
    }
}
