import SwiftUI

/// Block C — 학습 경로 2×2 그리드.
///
/// 슬롯 순서는 `[입문, 오행, 십성, 대운]`으로 고정되며, provider 배열의 순서와
/// 무관하게 이름 매칭으로 각 슬롯의 CoursePath를 조회한다.
/// 4개 미만이면 해당 슬롯은 `nil`(locked)으로 렌더한다.
struct SajuCourseGridView: View {
    let coursePaths: [CoursePath]
    let onTap: () -> Void

    /// 고정 슬롯 순서 — 스펙 AC7 및 TB-10 단위 테스트에서 직접 참조.
    static let fixedOrder: [String] = ["입문", "오행", "십성", "대운"]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 8
        ) {
            ForEach(Self.fixedOrder, id: \.self) { slotName in
                let match = coursePaths.first(where: { $0.name == slotName })
                SajuCourseCardView(
                    coursePath: match,
                    slotName: slotName,
                    onTap: onTap
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuCourseGrid")
    }
}

#Preview {
    SajuCourseGridView(
        coursePaths: MockSajuLearningPathProvider().coursePaths,
        onTap: {}
    )
    .padding()
}
