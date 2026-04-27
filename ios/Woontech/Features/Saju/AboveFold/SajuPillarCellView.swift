import SwiftUI

/// 사주 4기둥 중 한 기둥을 표시하는 셀 뷰.
///
/// - Parameters:
///   - pillar: 기둥 데이터(천간·지지).
///   - columnLabel: 기둥 이름 한자 (時/日/月/年).
///   - isDayMaster: 일간 여부 — true이면 천간 박스 배경을 강조 토큰으로 채색.
struct SajuPillarCellView: View {
    let pillar: Pillar
    let columnLabel: String
    let isDayMaster: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(columnLabel)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)

            // 천간(天干) 박스
            Text(pillar.heavenlyStem)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isDayMaster ? DesignTokens.dayMasterHighlight : DesignTokens.bg)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DesignTokens.line3, lineWidth: 0.5)
                )

            // 지지(地支) 박스
            Text(pillar.earthlyBranch)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(DesignTokens.gray)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DesignTokens.line3, lineWidth: 0.5)
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(columnLabel), 천간 \(pillar.heavenlyStem), 지지 \(pillar.earthlyBranch)")
        .accessibilityAddTraits(isDayMaster ? [.isHeader] : [])
        .accessibilityIdentifier("SajuPillarCell_\(pillar.position.rawValue)")
    }
}
