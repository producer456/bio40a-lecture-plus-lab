import SwiftUI

struct PracticeMenuView: View {
    @Environment(ContentService.self) private var content

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero banner
                BioHeroBanner(
                    system: .cardiovascular,
                    title: "Practice",
                    subtitle: "\(content.allQuestions.count) questions across \(content.chapters.count) chapters",
                    badge: "PRACTICE",
                    height: 120
                )

                // Lecture Quizzes
                VStack(alignment: .leading, spacing: 12) {
                    BioSectionHeader(title: "Lecture Quizzes", icon: "doc.text.fill", system: .cardiovascular)

                    NavigationLink(destination: LectureQuiz1View()) {
                        practiceCard(icon: "doc.text.fill", title: "Lecture Quiz 1 Practice", subtitle: "100 questions — anatomy, chemistry, body systems", system: .skeletal)
                    }
                    NavigationLink(destination: LectureQuiz2View()) {
                        practiceCard(icon: "doc.text.fill", title: "Lecture Quiz 2 Practice", subtitle: "100 questions — syllabus, macromolecules, enzymes, clinical", system: .nervous)
                    }
                    NavigationLink(destination: LectureQuiz3View()) {
                        practiceCard(icon: "doc.text.fill", title: "Lecture Quiz 3 Practice", subtitle: "34 questions — chemistry, bonds, proteins, beta amyloid", system: .endocrine)
                    }
                    NavigationLink(destination: LectureQuiz4View()) {
                        practiceCard(icon: "doc.text.fill", title: "Lecture Quiz 4 Practice", subtitle: "100 questions — anatomy, chemistry, macromolecules, clinical, imaging", system: .cardiovascular)
                    }
                }

                // Study Tools
                VStack(alignment: .leading, spacing: 12) {
                    BioSectionHeader(title: "Study Tools", icon: "book.fill", system: .endocrine)

                    NavigationLink(destination: FlashcardDeckView()) {
                        practiceCard(icon: "rectangle.on.rectangle.angled", title: "Flashcards", subtitle: "Review key terms with spaced repetition", system: .endocrine)
                    }
                    NavigationLink(destination: QuizSetupView()) {
                        practiceCard(icon: "checkmark.circle.fill", title: "Practice Quizzes", subtitle: "\(content.allQuestions.count) questions available", system: .cardiovascular)
                    }
                    NavigationLink(destination: ComparisonListView()) {
                        practiceCard(icon: "circle.grid.cross.fill", title: "Comparisons", subtitle: "Compare & contrast key concepts", system: .organ)
                    }
                }

                // Games
                VStack(alignment: .leading, spacing: 12) {
                    BioSectionHeader(title: "Games", icon: "gamecontroller.fill", system: .integumentary)

                    NavigationLink(destination: MatchingGameView()) {
                        practiceCard(icon: "rectangle.grid.2x2.fill", title: "Term Matching", subtitle: "Match terms to definitions", system: .nervous)
                    }
                    NavigationLink(destination: FillInBlankView()) {
                        practiceCard(icon: "text.cursor", title: "Fill in the Blank", subtitle: "Complete key sentences", system: .muscular)
                    }
                    NavigationLink(destination: VennGamesMenuView()) {
                        practiceCard(icon: "circle.grid.cross.fill", title: "Venn Diagram Games", subtitle: "3 games to master compare & contrast", system: .integumentary)
                    }
                }

                // Analysis
                VStack(alignment: .leading, spacing: 12) {
                    BioSectionHeader(title: "Analysis", icon: "chart.bar.fill", system: .muscular)

                    NavigationLink(destination: WeakSpotsView()) {
                        practiceCard(icon: "exclamationmark.triangle.fill", title: "Weak Spots", subtitle: "See where you need to improve", system: .muscular)
                    }
                    NavigationLink(destination: ProgressDashboardView()) {
                        practiceCard(icon: "chart.bar.fill", title: "Progress", subtitle: "Track your study progress", system: .organ)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Practice")
    }

    private func practiceCard(icon: String, title: String, subtitle: String, system: BodySystem) -> some View {
        BioCard(system: system) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(system.primaryColor)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
