import SwiftUI

/// Block B — 오늘의 한 가지 카드.
///
/// 좌측 50×50 placeholder 이미지 + 우측 텍스트 3줄(라벨/타이틀/메타).
/// 카드 전체가 Button이며 탭 시 onTap을 호출한다.
struct SajuFeaturedLessonCardView: View {
    let lesson: FeaturedLesson
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.gray)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text("오늘의 한 가지")
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.muted)

                    Text(lesson.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)

                    Text("\(lesson.durationLabel) · \(lesson.levelLabel)")
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.muted)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(14)
            .background(DesignTokens.bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignTokens.line3, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오늘의 한 가지, \(lesson.title), \(lesson.durationLabel), \(lesson.levelLabel)")
        .accessibilityIdentifier("SajuFeaturedLessonCard")
    }
}

#Preview {
    SajuFeaturedLessonCardView(
        lesson: FeaturedLesson(
            id: "L-TEN-001",
            title: "십성이란 무엇인가?",
            durationLabel: "3분",
            levelLabel: "초급"
        ),
        onTap: {}
    )
    .padding()
}
