import SwiftUI

/// 가로 스크롤 카테고리 필터 pill 스트립.
///
/// - Note: 부모로부터 horizontal padding을 받지 않는다.
///   내부 HStack에 `.padding(.leading, 16).padding(.trailing, 16)` 을 직접 적용.
struct SajuLearnCategoryPillsView: View {
    let categories: [LearnCategory]
    @Binding var selectedId: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(categories) { category in
                    let isSelected = selectedId == category.id
                    Button {
                        selectedId = category.id
                    } label: {
                        Text(category.label)
                            .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? Color.white : DesignTokens.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.black : Color.white)
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.clear : DesignTokens.line3, lineWidth: 1)
                                    )
                            )
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(category.label), \(isSelected ? "선택됨" : "선택 안됨")")
                    .accessibilityIdentifier("SajuLearnCategoryPill_\(category.id)")
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuLearnCategoryPills")
    }
}

#Preview {
    SajuLearnCategoryPillsView(
        categories: MockSajuLearningPathProvider.defaultLearnCategories,
        selectedId: .constant("all")
    )
}
