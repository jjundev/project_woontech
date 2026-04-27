import SwiftUI

/// 사주 탭(TabBar index 2)의 컨테이너.
///
/// 구성: 상단 고정 Header / Divider / 사주 탭 전용 NavigationStack(컨텐츠 슬롯).
/// 본 슬라이스(WF4-01)에서는 컨텐츠 슬롯을 "준비중" placeholder로 둔다.
///
/// `accessibilityIdentifier("SajuTabRoot")`은 내부 hidden 마커에 부여한다 —
/// 외곽 VStack에 직접 부여하면 SwiftUI TabView가 그 식별자를 자식 트리로
/// 전파해 NavPush 트리거 등의 descendant 식별자가 가려진다(구현자 가이드).
struct SajuTabView: View {
    @EnvironmentObject var deps: SajuTabDependencies
    @State private var navigationPath: [SajuRoute] = []
    @State private var menuTapCount = 0

    private var showsUITestNavigationTriggers: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-openSajuTab") || args.contains("-openHome")
    }

    var body: some View {
        VStack(spacing: 0) {
            SajuTabHeaderView(onMenuTap: { menuTapCount += 1 })

            Rectangle()
                .fill(DesignTokens.headerBorder)
                .frame(height: 1)

            NavigationStack(path: $navigationPath) {
                SajuTabContentView(
                    originProvider: deps.userSajuOrigin,
                    categoriesProvider: deps.categories,
                    onNavigate: { route in navigationPath.append(route) }
                )
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: SajuRoute.self) { route in
                    sajuRouteDestination(for: route)
                }
            }
        }
        .accessibilityElement(children: .contain)
        // Hidden tap-counter spy for header menu button.
        .overlay(alignment: .topLeading) {
            Text("\(menuTapCount)")
                .accessibilityIdentifier("SajuTabHeaderMenuTapCount")
                .opacity(0)
                .allowsHitTesting(false)
        }
        // Hidden marker so UI tests can locate the SajuTabView root via
        // app.otherElements["SajuTabRoot"] without polluting the TabView
        // child's outer identifier.
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityIdentifier("SajuTabRoot")
                .accessibilityHidden(false)
                .allowsHitTesting(false)
        }
        // Hidden push trigger buttons for UI tests (parallels HomeDashboardView).
        .overlay(alignment: .bottomLeading) {
            if showsUITestNavigationTriggers {
                VStack(spacing: 0) {
                    sajuUITestPushButton("SajuNavPush_elements") {
                        navigationPath.append(.elements)
                    }
                    sajuUITestPushButton("SajuNavPush_tenGods") {
                        navigationPath.append(.tenGods)
                    }
                    sajuUITestPushButton("SajuNavPush_learn") {
                        navigationPath.append(.learn)
                    }
                    sajuUITestPushButton("SajuNavPush_lessonL001") {
                        navigationPath.append(.lesson(id: "L-001"))
                    }
                    sajuUITestPushButton("SajuNavPush_daewoon") {
                        navigationPath.append(.daewoonPlaceholder)
                    }
                    sajuUITestPushButton("SajuNavPush_hapchung") {
                        navigationPath.append(.hapchungPlaceholder)
                    }
                    sajuUITestPushButton("SajuNavPush_yongsin") {
                        navigationPath.append(.yongsinPlaceholder)
                    }
                }
            }
        }
    }

    private func sajuUITestPushButton(
        _ identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Color.black.opacity(0.001)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(identifier)
    }
}
