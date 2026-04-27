import Foundation

/// 사주 탭(SajuTabView)이 필요로 하는 6종 providing을 한 곳에 모은 DI 컨테이너.
///
/// `@EnvironmentObject` 또는 생성자 주입으로 SajuTabView에 전달한다. 테스트 시
/// 임의 mock으로 6필드 각각을 교체할 수 있다.
final class SajuTabDependencies: ObservableObject {
    var userSajuOrigin: any UserSajuOriginProviding
    var categories: any SajuCategoriesProviding
    var elementsDetail: any SajuElementsDetailProviding
    var tenGodsDetail: any SajuTenGodsDetailProviding
    var learningPath: any SajuLearningPathProviding
    var lesson: any SajuLessonProviding

    init(
        userSajuOrigin: any UserSajuOriginProviding = MockUserSajuOriginProvider(),
        categories: any SajuCategoriesProviding = MockSajuCategoriesProvider(),
        elementsDetail: any SajuElementsDetailProviding = MockSajuElementsDetailProvider(),
        tenGodsDetail: any SajuTenGodsDetailProviding = MockSajuTenGodsDetailProvider(),
        learningPath: any SajuLearningPathProviding = MockSajuLearningPathProvider(),
        lesson: any SajuLessonProviding = MockSajuLessonProvider()
    ) {
        self.userSajuOrigin = userSajuOrigin
        self.categories = categories
        self.elementsDetail = elementsDetail
        self.tenGodsDetail = tenGodsDetail
        self.learningPath = learningPath
        self.lesson = lesson
    }

    static let mock = SajuTabDependencies()
}
