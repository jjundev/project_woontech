import SwiftUI

/// 4개 탭(홈/투자/사주/마이)을 담는 메인 컨테이너.
///
/// `-openSajuTab` 런치 인자가 주어지면 부팅 직후 사주 탭(index 2)이 활성화된다.
/// 사주 탭은 본 슬라이스(WF4-01)에서 도입된 `SajuTabView`. 투자·마이 탭은
/// 본 슬라이스 범위에서는 단순 "준비중" placeholder로 둔다.
struct MainTabContainerView: View {
    @EnvironmentObject var homeDeps: HomeDependencies
    @EnvironmentObject var sajuTabDeps: SajuTabDependencies
    @State private var selection: Int

    init(initialSelection: Int? = nil) {
        if let initialSelection {
            _selection = State(initialValue: initialSelection)
        } else {
            let parsed = MainTabContainerView.parseInitialSelection()
            _selection = State(initialValue: parsed)
        }
    }

    static func parseInitialSelection() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-openSajuTab") { return 2 }
        return 0
    }

    var body: some View {
        TabView(selection: $selection) {
            // Tab 0 — 홈
            HomeDashboardView()
                .environmentObject(homeDeps)
                .tabItem {
                    Label(
                        String(localized: "saju.tab.home.label", defaultValue: "홈"),
                        systemImage: "house"
                    )
                }
                .tag(0)
                .accessibilityLabel(Text(String(
                    localized: "saju.tab.home.label",
                    defaultValue: "홈 탭"
                )))

            // Tab 1 — 투자 (placeholder)
            MainTabPlaceholderView(label: "investing")
                .tabItem {
                    Label(
                        String(localized: "saju.tab.invest.label", defaultValue: "투자"),
                        systemImage: "chart.line.uptrend.xyaxis"
                    )
                }
                .tag(1)
                .accessibilityLabel(Text(String(
                    localized: "saju.tab.invest.label",
                    defaultValue: "투자 탭"
                )))

            // Tab 2 — 사주
            SajuTabView()
                .environmentObject(sajuTabDeps)
                .tabItem {
                    Label(
                        String(localized: "saju.tab.title", defaultValue: "사주"),
                        systemImage: "sparkles"
                    )
                }
                .tag(2)
                .accessibilityLabel(Text(String(
                    localized: "saju.tab.tabBar.label",
                    defaultValue: "사주 탭"
                )))

            // Tab 3 — 마이 (placeholder)
            MainTabPlaceholderView(label: "my")
                .tabItem {
                    Label(
                        String(localized: "saju.tab.my.label", defaultValue: "마이"),
                        systemImage: "person.crop.circle"
                    )
                }
                .tag(3)
                .accessibilityLabel(Text(String(
                    localized: "saju.tab.my.label",
                    defaultValue: "마이 탭"
                )))
        }
    }
}

/// 투자/마이 탭의 비어있는 placeholder.
private struct MainTabPlaceholderView: View {
    let label: String

    var body: some View {
        VStack {
            Spacer()
            Text(String(
                localized: "saju.tab.content.placeholder",
                defaultValue: "준비중"
            ))
            .font(.system(size: 14))
            .foregroundStyle(DesignTokens.muted)
            .accessibilityIdentifier("MainTabPlaceholder_\(label)_Text")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("MainTabPlaceholder_\(label)")
    }
}
