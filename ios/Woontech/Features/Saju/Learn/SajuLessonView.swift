import SwiftUI

/// 레슨 상세 화면 (WF4-07).
///
/// `SajuRoute.lesson(id:)` 목적지. 진행 바, 개념 박스, 다이어그램 placeholder,
/// 인라인 퀴즈, 하단 고정 CTA로 구성된다.
struct SajuLessonView: View {
    let lesson: Lesson
    let onReplaceTop: (SajuRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedChoiceIndex: Int? = nil

    // MARK: - Static Pure Helpers (unit-testable)

    /// 진행 바 채움 비율 (0.0 ~ 1.0, clamp).
    static func progressRatio(currentIndex: Int, totalCount: Int) -> Double {
        guard totalCount > 0 else { return 0 }
        return min(Double(currentIndex) / Double(totalCount), 1.0)
    }

    /// VoiceOver용 진행 바 레이블 (예: "진행률 43%").
    static func progressBarA11yLabel(current: Int, total: Int) -> String {
        let pct = Int((progressRatio(currentIndex: current, totalCount: total) * 100).rounded())
        return "진행률 \(pct)%"
    }

    /// 옵션 박스 외형 (border, background, weight). AC#8~10 로직.
    static func choiceAppearance(
        index: Int,
        selected: Int?,
        correct: Int
    ) -> (border: Color, background: Color, weight: Font.Weight) {
        guard let sel = selected else {
            // 미선택 상태: 모두 회색
            return (DesignTokens.gray2, Color.white, .regular)
        }
        if index == correct {
            // 정답 옵션 강조 (정답 선택이든 오답 선택 후든 모두)
            return (DesignTokens.quizCorrectBorder, DesignTokens.quizCorrectBackground, .bold)
        }
        if index == sel {
            // 선택한 오답 옵션
            return (DesignTokens.quizIncorrectBorder, DesignTokens.quizIncorrectBg, .regular)
        }
        return (DesignTokens.gray2, Color.white, .regular)
    }

    /// VoiceOver용 퀴즈 카드 레이블.
    static func quizA11yLabel(question: String) -> String {
        "퀴즈, \(question)"
    }

    /// VoiceOver용 옵션 accessibilityValue ("정답" / "오답" / "").
    static func choiceA11yValue(index: Int, selected: Int?, correct: Int) -> String {
        guard let sel = selected else { return "" }
        if index == sel && index == correct { return "정답" }
        if index == sel && index != correct { return "오답" }
        if index == correct && sel != correct { return "정답" }
        return ""
    }

    // MARK: - CTA computed helpers

    private var ctaLabel: String {
        lesson.nextLessonId != nil ? "다음 강의" : "학습 완료"
    }

    private var ctaEnabled: Bool {
        !lesson.isFallback && selectedChoiceIndex != nil
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // 진행 바 (NavBar 직하단)
                    progressBarView

                    // 본문 (18pt horizontal padding)
                    VStack(alignment: .leading, spacing: 0) {

                        // sectionLabel
                        Text(lesson.sectionLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(DesignTokens.muted)
                            .accessibilityIdentifier("SajuLessonSectionLabel")
                            .padding(.top, 18)

                        // headline
                        Text(lesson.headline)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("SajuLessonHeadline")
                            .padding(.top, 6)

                        // 개념 박스
                        ConceptBoxView(text: lesson.conceptBox)
                            .padding(.top, 14)

                        // 다이어그램 placeholder
                        DiagramPlaceholderView(label: lesson.diagramPlaceholderLabel)
                            .padding(.top, 14)

                        // 퀴즈 카드 (fallback 시 숨김)
                        if !lesson.isFallback {
                            QuizCardView(
                                quiz: lesson.quiz,
                                selectedChoiceIndex: $selectedChoiceIndex
                            )
                            .padding(.top, 16)
                        }

                        // 하단 CTA 영역 높이만큼 스크롤 여백
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .scrollIndicators(.hidden)

            // 하단 고정 CTA
            BottomCTABarView(
                label: ctaLabel,
                isEnabled: ctaEnabled,
                onTap: handleCTATap
            )
        }
        // Color.clear 마커 — UI 테스트 루트 식별자
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityIdentifier("SajuLessonView")
                .accessibilityHidden(false)
                .allowsHitTesting(false)
        }
        .navigationTitle("\(lesson.number)강 · \(lesson.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(lesson.currentIndex)/\(lesson.totalCount)")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBarView: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(DesignTokens.gray)
                    .frame(height: 3)

                Rectangle()
                    .fill(DesignTokens.ink)
                    .frame(
                        width: geo.size.width * CGFloat(Self.progressRatio(
                            currentIndex: lesson.currentIndex,
                            totalCount: lesson.totalCount
                        )),
                        height: 3
                    )
            }
        }
        .frame(height: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.progressBarA11yLabel(current: lesson.currentIndex, total: lesson.totalCount))
        .accessibilityIdentifier("SajuLessonProgressBar")
    }

    // MARK: - CTA tap

    private func handleCTATap() {
        guard ctaEnabled else { return }
        if let nextId = lesson.nextLessonId {
            onReplaceTop(.lesson(id: nextId))
        } else {
            dismiss()
        }
    }
}

// MARK: - ConceptBoxView

private struct ConceptBoxView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(DesignTokens.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.gray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityIdentifier("SajuLessonConceptBox")
    }
}

// MARK: - DiagramPlaceholderView

private struct DiagramPlaceholderView: View {
    let label: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.gray2, lineWidth: 1)
                .background(DesignTokens.gray.clipShape(RoundedRectangle(cornerRadius: 8)))

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.muted)
                .multilineTextAlignment(.center)
        }
        .frame(width: 200, height: 140)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("다이어그램 자리, \(label)")
        .accessibilityIdentifier("SajuLessonDiagramPlaceholder")
    }
}

// MARK: - QuizCardView

private struct QuizCardView: View {
    let quiz: Quiz
    @Binding var selectedChoiceIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 헤더: Q 라벨 + quiz.label
            HStack(spacing: 6) {
                Text("Q")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(DesignTokens.ink, lineWidth: 1)
                    )

                Text(quiz.label)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.muted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(SajuLessonView.quizA11yLabel(question: quiz.question))

            // question
            Text(quiz.question)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            // 4지선다 옵션
            let _ = precondition(quiz.choices.count == 4, "SajuLessonView: quiz.choices must have exactly 4 elements")

            VStack(spacing: 6) {
                ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                    ChoiceOptionView(
                        symbol: choice.symbol,
                        index: index,
                        selectedChoiceIndex: $selectedChoiceIndex,
                        correctIndex: quiz.correctIndex
                    )
                }
            }
            .padding(.top, 10)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuLessonQuizCard")
    }
}

// MARK: - ChoiceOptionView

private struct ChoiceOptionView: View {
    let symbol: String
    let index: Int
    @Binding var selectedChoiceIndex: Int?
    let correctIndex: Int

    private var appearance: (border: Color, background: Color, weight: Font.Weight) {
        SajuLessonView.choiceAppearance(
            index: index,
            selected: selectedChoiceIndex,
            correct: correctIndex
        )
    }

    private var a11yValue: String {
        SajuLessonView.choiceA11yValue(
            index: index,
            selected: selectedChoiceIndex,
            correct: correctIndex
        )
    }

    var body: some View {
        Button {
            guard selectedChoiceIndex == nil else { return }
            selectedChoiceIndex = index
        } label: {
            HStack {
                Text(symbol)
                    .font(.system(size: 11, weight: appearance.weight))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(appearance.background)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(appearance.border, lineWidth: index == correctIndex && selectedChoiceIndex != nil ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol)
        .accessibilityValue(a11yValue)
        .accessibilityIdentifier("SajuLessonQuizChoice_\(index)")
    }
}

// MARK: - BottomCTABarView

private struct BottomCTABarView: View {
    let label: String
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignTokens.line3)
                .frame(height: 1)

            Button(action: onTap) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isEnabled ? Color.white : DesignTokens.muted)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(
                        isEnabled ? DesignTokens.ink : DesignTokens.gray
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            // Identifier placed directly on Button for app.buttons["SajuLessonNextCTA"]
            .accessibilityIdentifier("SajuLessonNextCTA")
            .disabled(!isEnabled)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SajuLessonView(
            lesson: MockSajuLessonProvider.defaultLesson,
            onReplaceTop: { _ in }
        )
    }
}
