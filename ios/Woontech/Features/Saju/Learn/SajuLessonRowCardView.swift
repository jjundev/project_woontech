import SwiftUI

/// 코스 레슨 셀 — 4-상태(completed / current / pending / locked) 인디케이터.
struct SajuLessonRowCardView: View {
    let lesson: LessonRow
    let onTap: () -> Void

    // MARK: - Static Helpers (testable)

    /// 상태를 한국어 문자열로 반환한다(VoiceOver label 및 단위 테스트용).
    static func statusKorean(_ status: LessonStatus) -> String {
        switch status {
        case .completed: return "완료"
        case .current:   return "현재"
        case .pending:   return "미완료"
        case .locked:    return "잠김"
        }
    }

    // MARK: - Computed

    private var metaLine: String {
        lesson.status == .current
            ? "\(lesson.durationLabel) · 이어보기"
            : lesson.durationLabel
    }

    private var accessibilityLabel: String {
        let continueSuffix = lesson.status == .current ? ", 이어보기" : ""
        return "\(lesson.number)강 \(lesson.title), \(lesson.durationLabel)\(continueSuffix), 상태 \(Self.statusKorean(lesson.status))"
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 좌측: 원형 인디케이터 28×28
                indicator

                // 가운데: 타이틀 + 메타
                VStack(alignment: .leading, spacing: 2) {
                    Text(lesson.title)
                        .font(.system(size: 12, weight: titleWeight))
                        .foregroundStyle(titleColor)
                        .multilineTextAlignment(.leading)

                    Text(metaLine)
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 우측: 자물쇠 or chevron
                if lesson.status == .locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.muted)
                } else {
                    Text("›")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.muted)
                }
            }
            .padding(12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .background(DesignTokens.bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignTokens.line3, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("SajuLearnLessonCard_\(lesson.id)")
    }

    // MARK: - Indicator

    @ViewBuilder
    private var indicator: some View {
        ZStack {
            switch lesson.status {
            case .completed:
                Circle()
                    .fill(Color.black)
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white)

            case .current:
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(Color.black, lineWidth: 2)
                    )
                Text("\(lesson.number)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)

            case .pending:
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(DesignTokens.line2, lineWidth: 1)
                    )
                Text("\(lesson.number)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)

            case .locked:
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(DesignTokens.line2, lineWidth: 1)
                    )
                Text("\(lesson.number)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
        .frame(width: 28, height: 28)
    }

    // MARK: - Styling helpers

    private var titleWeight: Font.Weight {
        switch lesson.status {
        case .completed, .current: return .bold
        case .pending:  return .medium
        case .locked:   return .regular
        }
    }

    private var titleColor: Color {
        lesson.status == .locked ? DesignTokens.muted : DesignTokens.ink
    }
}

#Preview {
    VStack(spacing: 8) {
        SajuLessonRowCardView(
            lesson: LessonRow(id: "L1", number: 1, title: "사주란 무엇인가", durationLabel: "3분", status: .completed),
            onTap: {}
        )
        SajuLessonRowCardView(
            lesson: LessonRow(id: "L4", number: 4, title: "일간이 나를 나타낸다", durationLabel: "5분", status: .current),
            onTap: {}
        )
        SajuLessonRowCardView(
            lesson: LessonRow(id: "L3", number: 3, title: "오행의 의미", durationLabel: "3분", status: .pending),
            onTap: {}
        )
        SajuLessonRowCardView(
            lesson: LessonRow(id: "L5", number: 5, title: "지장간이란", durationLabel: "4분", status: .locked),
            onTap: {}
        )
    }
    .padding()
}
