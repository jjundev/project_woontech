import Foundation

protocol HeroInvestingProviding {
    var score: Int { get }          // 0~100 integer; view에서 clamp(0, 100)
    var oneLiner: String { get }    // 큰 본문 한줄 카피
    var displayDate: Date { get }   // 날짜 라벨 원본 값
}

struct MockHeroInvestingProvider: HeroInvestingProviding {
    var score: Int
    var oneLiner: String
    var displayDate: Date

    init(
        score: Int = 72,
        oneLiner: String = "공격보다 관찰이 내 성향에 맞아요",
        displayDate: Date = {
            var comps = DateComponents()
            comps.year = 2026
            comps.month = 4
            comps.day = 23
            return Calendar.current.date(from: comps) ?? Date()
        }()
    ) {
        self.score = score
        self.oneLiner = oneLiner
        self.displayDate = displayDate
    }
}
