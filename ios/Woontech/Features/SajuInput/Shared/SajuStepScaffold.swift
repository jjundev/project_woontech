import SwiftUI

/// 각 입력 스텝의 공통 레이아웃: 타이틀 + 힌트 + 콘텐츠.
struct SajuStepScaffold<Content: View>: View {
    let titleKey: LocalizedStringKey
    let hintKey: LocalizedStringKey?
    let content: Content

    init(titleKey: LocalizedStringKey,
         hintKey: LocalizedStringKey? = nil,
         @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.hintKey = hintKey
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titleKey, bundle: .main)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .accessibilityAddTraits(.isHeader)
            if let hintKey {
                Text(hintKey, bundle: .main)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.muted)
            }
            content
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
