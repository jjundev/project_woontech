import SwiftUI

/// Block C — 학습 경로 그리드의 개별 코스 카드.
///
/// `coursePath == nil`이면 locked 상태(흐린 배경, 진행률 0)로 렌더한다.
struct SajuCourseCardView: View {
    let coursePath: CoursePath?
    /// 고정 슬롯 이름(예: "입문"). coursePath가 nil일 때 표시 이름으로도 사용.
    let slotName: String
    let onTap: () -> Void

    private var isLocked: Bool { coursePath == nil }

    /// 클램프된 진행률 (0.0 ~ 1.0).
    static func clampedProgress(_ raw: Double) -> Double {
        max(0.0, min(1.0, raw))
    }

    private var displayProgress: Double {
        Self.clampedProgress(coursePath?.progress ?? 0.0)
    }

    private var displayName: String { coursePath?.name ?? slotName }
    private var displayLessonCount: Int { coursePath?.lessonCount ?? 0 }

    private var voiceOverLabel: String {
        let pct = Int((displayProgress * 100).rounded())
        let countStr = isLocked ? "-" : "\(displayLessonCount)"
        return "\(displayName) 코스, \(countStr)강, 진행률 \(pct)%"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isLocked ? DesignTokens.muted : DesignTokens.ink)

                Text(isLocked ? "-강" : "\(displayLessonCount)강")
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.muted)

                // 진행률 바 — GeometryReader 대신 overlay 방식으로 안정적으로 구현
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignTokens.gray2)
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignTokens.ink)
                            .frame(
                                width: max(0, geo.size.width * displayProgress),
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(12)
            .background(isLocked ? DesignTokens.gray2 : DesignTokens.bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignTokens.line3, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(voiceOverLabel)
        .accessibilityIdentifier("SajuCourseCard_\(slotName)")
    }
}

#Preview {
    HStack(spacing: 8) {
        SajuCourseCardView(
            coursePath: CoursePath(name: "입문", lessonCount: 7, averageMinutes: nil, progress: 1.0),
            slotName: "입문",
            onTap: {}
        )
        SajuCourseCardView(
            coursePath: nil,
            slotName: "오행",
            onTap: {}
        )
    }
    .padding()
}
