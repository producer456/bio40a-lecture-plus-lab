import SwiftUI

struct PracticeMenuView: View {
    @Environment(ContentService.self) private var content

    var body: some View {
        List {
            // Hero banner
            Section {
                BioHeroBanner(
                    system: .cardiovascular,
                    title: "Practice",
                    subtitle: "\(content.allQuestions.count) questions across \(content.chapters.count) chapters",
                    height: 120
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Study Tools") {
                NavigationLink(destination: FlashcardDeckView()) {
                    practiceRow(icon: "rectangle.on.rectangle.angled", title: "Flashcards", subtitle: "Review key terms with spaced repetition", color: BodySystem.endocrine.primaryColor)
                }
                NavigationLink(destination: QuizSetupView()) {
                    practiceRow(icon: "checkmark.circle.fill", title: "Practice Quizzes", subtitle: "\(content.allQuestions.count) questions available", color: BodySystem.cardiovascular.primaryColor)
                }
                NavigationLink(destination: ComparisonListView()) {
                    practiceRow(icon: "circle.grid.cross.fill", title: "Comparisons", subtitle: "Compare & contrast key concepts", color: BodySystem.organ.primaryColor)
                }
            }

            Section("Games") {
                NavigationLink(destination: MatchingGameView()) {
                    practiceRow(icon: "rectangle.grid.2x2.fill", title: "Term Matching", subtitle: "Match terms to definitions", color: BodySystem.nervous.primaryColor)
                }
                NavigationLink(destination: FillInBlankView()) {
                    practiceRow(icon: "text.cursor", title: "Fill in the Blank", subtitle: "Complete key sentences", color: BodySystem.muscular.primaryColor)
                }
                NavigationLink(destination: VennGamesMenuView()) {
                    practiceRow(icon: "circle.grid.cross.fill", title: "Venn Diagram Games", subtitle: "3 games to master compare & contrast", color: BodySystem.integumentary.primaryColor)
                }
            }

            Section("Analysis") {
                NavigationLink(destination: WeakSpotsView()) {
                    practiceRow(icon: "exclamationmark.triangle.fill", title: "Weak Spots", subtitle: "See where you need to improve", color: BodySystem.muscular.primaryColor)
                }
                NavigationLink(destination: ProgressDashboardView()) {
                    practiceRow(icon: "chart.bar.fill", title: "Progress", subtitle: "Track your study progress", color: BodySystem.organ.primaryColor)
                }
            }
        }
        .navigationTitle("Practice")
    }

    private func practiceRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
