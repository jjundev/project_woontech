import SwiftUI
import UIKit // UIAccessibility.post(notification:argument:) for toast announcement

/// 사주 공부 리스트 화면 (WF4-06).
///
/// `SajuRoute.learn` 목적지. 카테고리 필터 pill, 주간 진행 배너,
/// 듀오링고식 코스 셀, 추천 아티클 섹션으로 구성된다.
struct SajuLearnListView: View {
    let provider: any SajuLearningPathProviding
    let onNavigate: (SajuRoute) -> Void

    @State private var selectedCategoryId: String = "all"
    @State private var toastVisible: Bool = false
    @State private var toastTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // 1. 카테고리 pill 가로 스크롤 — full-width
                    SajuLearnCategoryPillsView(
                        categories: provider.learnCategories,
                        selectedId: $selectedCategoryId
                    )
                    .padding(.top, 12)

                    // 2~5. 나머지 콘텐츠 — 16pt horizontal padding
                    VStack(alignment: .leading, spacing: 0) {

                        // 2. 주간 진행 배너
                        SajuWeeklyProgressBannerView(progress: provider.weeklyProgress)
                            .padding(.top, 12)

                        // 3. 코스 헤더
                        CourseHeaderView(course: provider.introductoryCourse)
                            .padding(.top, 18)

                        // 4. 코스 레슨 리스트
                        VStack(spacing: 6) {
                            ForEach(provider.introductoryCourse.lessons) { lesson in
                                SajuLessonRowCardView(lesson: lesson) {
                                    handleLessonTap(lesson)
                                }
                            }
                        }
                        .padding(.top, 8)

                        // 5. 추천 아티클 섹션 (비어있으면 전체 숨김)
                        if !provider.recommendedArticles.isEmpty {
                            ArticlesSectionView(articles: provider.recommendedArticles)
                                .padding(.top, 18)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }

            // 토스트 overlay
            if toastVisible {
                ToastBannerView(message: "이전 강의를 먼저 완료하세요")
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .accessibilityIdentifier("SajuLearnToast")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toastVisible)
        .navigationTitle("사주 공부")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* no-op */ }) {
                    Text("검색")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.muted)
                }
                .accessibilityHint("준비중")
                .accessibilityIdentifier("SajuLearnSearchButton")
            }
        }
        // Hidden Color.clear root marker for UI tests.
        // Queried as app.otherElements["SajuLearnListView"].
        // (Mirrors SajuElementsDetailView / SajuTenGodsDetailView pattern:
        //  attaching .accessibilityElement(children:.contain) after .toolbar
        //  causes the identifier to be masked in iOS 26 NavigationStack.)
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityIdentifier("SajuLearnListView")
                .accessibilityHidden(false)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Lesson Tap Handling

    private func handleLessonTap(_ lesson: LessonRow) {
        switch lesson.status {
        case .completed, .current, .pending:
            onNavigate(.lesson(id: lesson.id))
        case .locked:
            showLockedToast()
        }
    }

    private func showLockedToast() {
        toastTask?.cancel()
        withAnimation { toastVisible = true }
        UIAccessibility.post(notification: .announcement,
                             argument: "이전 강의를 먼저 완료하세요")
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { toastVisible = false }
            }
        }
    }
}

// MARK: - Course Header (inner)

private struct CourseHeaderView: View {
    let course: CourseSection

    var body: some View {
        HStack {
            Text("\(course.name) 코스")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DesignTokens.ink)

            Spacer()

            Text("\(course.lessonCount)강 · 평균 \(course.averageMinutes)분")
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(course.name) 코스, \(course.lessonCount)강")
        .accessibilityIdentifier("SajuLearnCourseHeader")
    }
}

// MARK: - Articles Section (inner)

private struct ArticlesSectionView: View {
    let articles: [Article]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이번 주 읽을거리")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DesignTokens.ink)

            ForEach(articles) { article in
                SajuLearnArticleCardView(article: article, onTap: { /* no-op */ })
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuLearnArticleSection")
    }
}

// MARK: - Toast Banner

struct ToastBannerView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.8))
            )
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SajuLearnListView(
            provider: MockSajuLearningPathProvider(),
            onNavigate: { _ in }
        )
    }
}
