import SwiftUI

/// Block A — 내 원국 4주 카드.
///
/// 상단 헤더("내 사주 원국" / "전체 보기 ›"), 4-column 기둥 grid,
/// 일간 한줄 박스 순서로 배치된다.
struct SajuOriginCardView: View {
    let provider: any UserSajuOriginProviding
    let onViewAll: () -> Void

    /// 항상 [時, 日, 月, 年] 고정 순서.
    private let displayOrder: [Pillar.Position] = [.hour, .day, .month, .year]

    var body: some View {
        // Precondition: provider must supply exactly 4 pillars.
        let pillars = provider.pillars
        precondition(pillars.count == 4,
            "UserSajuOriginProviding must supply exactly 4 pillars (hour/day/month/year)")

        let pillarMap: [Pillar.Position: Pillar] = Dictionary(
            uniqueKeysWithValues: pillars.map { ($0.position, $0) }
        )

        return VStack(spacing: 8) {
            // 헤더 행
            HStack {
                Text("내 사주 원국")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.muted)
                    .accessibilityIdentifier("SajuOriginCardHeaderLabel")
                Spacer()
                Button(action: onViewAll) {
                    Text("전체 보기 ›")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.muted)
                }
                .accessibilityHint("준비중")
                .accessibilityIdentifier("SajuOriginCardViewAllButton")
            }

            // 4-column grid
            HStack(spacing: 8) {
                ForEach(displayOrder, id: \.self) { position in
                    SajuPillarCellView(
                        pillar: pillarMap[position]!,
                        columnLabel: label(for: position),
                        isDayMaster: position == .day
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            // 일간 한줄 박스
            Text(provider.dayMasterLine)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(DesignTokens.dayMasterLineBg)
                .cornerRadius(6)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("SajuDayMasterLine")
        }
        .padding(16)
        .background(DesignTokens.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuOriginCard")
    }

    private func label(for position: Pillar.Position) -> String {
        switch position {
        case .hour:  return "時"
        case .day:   return "日"
        case .month: return "月"
        case .year:  return "年"
        }
    }
}
