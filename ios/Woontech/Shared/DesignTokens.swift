import SwiftUI

enum DesignTokens {
    static let ink = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255)
    static let muted = Color(red: 0x80 / 255, green: 0x80 / 255, blue: 0x80 / 255)
    static let gray = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF2 / 255)
    static let gray2 = Color(red: 0xD6 / 255, green: 0xD6 / 255, blue: 0xD6 / 255)
    static let line2 = Color(red: 0xBF / 255, green: 0xBF / 255, blue: 0xBF / 255)
    static let line3 = Color(red: 0xE6 / 255, green: 0xE6 / 255, blue: 0xE6 / 255)
    static let bg = Color.white
    static let disabled = Color(red: 0xC4 / 255, green: 0xC4 / 255, blue: 0xC4 / 255)

    // MARK: - 홈 Header 토큰
    static let headerBorder = Color(red: 0xE6 / 255, green: 0xE6 / 255, blue: 0xE6 / 255)  // line3 재사용
    static let avatarBg     = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF2 / 255)  // gray 재사용

    // MARK: - 오행 색상
    static let woodColor  = Color(red: 0x4C / 255, green: 0xAF / 255, blue: 0x50 / 255)
    static let fireColor  = Color(red: 0xE5 / 255, green: 0x39 / 255, blue: 0x35 / 255)
    static let earthColor = Color(red: 0xD4 / 255, green: 0xA0 / 255, blue: 0x17 / 255)
    static let metalColor = Color(red: 0x78 / 255, green: 0x90 / 255, blue: 0x9C / 255)
    static let waterColor = Color(red: 0x1E / 255, green: 0x88 / 255, blue: 0xE5 / 255)

    // MARK: - Insight badge 색상 (오행 색상과 동일 값)
    static let tabooColor    = fireColor   // red  — 금기
    static let todayColor    = muted       // gray — 일진
    static let practiceColor = woodColor   // green — 실천

    // MARK: - 사주 원국 카드 토큰
    static let dayMasterHighlight = Color(red: 0xD6/255, green: 0xD6/255, blue: 0xD6/255) // gray2 재사용
    static let dayMasterLineBg    = Color(red: 0xF2/255, green: 0xF2/255, blue: 0xF2/255) // gray 재사용

    // MARK: - 십성 배지·경고 색상 (WF4-05)
    /// "핵심" 배지 배경 — 검정(ink 재사용).
    static let coreBadgeBg    = ink
    /// 부재 텍스트·카드 테두리 — fireColor 재사용.
    static let absentRed      = fireColor
    /// 경고 카드 copy 박스 배경 — 연한 빨강.
    static let absentRedLight = Color(red: 1.0, green: 0.9, blue: 0.9)

    // MARK: - 퀴즈 색상 토큰 (WF4-07)
    /// 정답 옵션 테두리 — ink 재사용.
    static let quizCorrectBorder     = ink
    /// 정답 옵션 배경 — gray 재사용.
    static let quizCorrectBackground = gray
    /// 오답 옵션 테두리 — absentRed(fireColor) 재사용.
    static let quizIncorrectBorder   = absentRed
    /// 오답 옵션 배경 — absentRedLight 재사용.
    static let quizIncorrectBg       = absentRedLight
}
