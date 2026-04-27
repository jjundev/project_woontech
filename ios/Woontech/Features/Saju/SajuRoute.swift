import Foundation

/// 사주 탭 NavigationStack 라우트.
///
/// WF4-01에서는 7케이스 모두 "준비중" placeholder로 라우트되며,
/// 실제 화면은 후속 슬라이스(WF4-02~07)에서 채워진다.
enum SajuRoute: Hashable {
    case elements
    case tenGods
    case learn
    case lesson(id: String)
    case daewoonPlaceholder
    case hapchungPlaceholder
    case yongsinPlaceholder
}
