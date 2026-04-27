import SwiftUI

/// Block A~E 조립 컨테이너 — 사주 공부하기 섹션 전체.
///
/// WF4-02 above-fold 아래에 `.padding(.top, 18)`로 배치된다.
struct SajuStudySectionView: View {
    let provider: any SajuLearningPathProviding
    let onNavigate: (SajuRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Block A — 헤더
            SajuStudySectionHeaderView(
                streakDays: provider.streakDays,
                onAllTap: { onNavigate(.learn) }
            )

            // Block B — 오늘의 한 가지 (nil이면 숨김)
            if let lesson = provider.featuredLesson {
                SajuFeaturedLessonCardView(
                    lesson: lesson,
                    onTap: { onNavigate(.lesson(id: lesson.id)) }
                )
            }

            // Block C — 학습 경로 4-그리드
            SajuCourseGridView(
                coursePaths: provider.coursePaths,
                onTap: { onNavigate(.learn) }
            )

            // Block D — 용어 사전
            SajuGlossaryCardView(glossaryTermCount: provider.glossaryTermCount)

            // Block E — Disclaimer
            DisclaimerView()
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuStudySection")
    }
}

#Preview {
    ScrollView {
        SajuStudySectionView(
            provider: MockSajuLearningPathProvider(),
            onNavigate: { _ in }
        )
        .padding(.top, 18)
    }
}
