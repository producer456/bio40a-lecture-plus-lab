import SwiftUI

struct PracticeMenuView: View {
    @Environment(ContentService.self) private var content

    var body: some View {
        List {
            Section("Study Tools") {
                NavigationLink(destination: FlashcardDeckView()) {
                    practiceRow(icon: "rectangle.on.rectangle.angled", title: "Flashcards", subtitle: "Review key terms with spaced repetition", color: .orange)
                }
                NavigationLink(destination: QuizSetupView()) {
                    practiceRow(icon: "checkmark.circle.fill", title: "Practice Quizzes", subtitle: "\(content.allQuestions.count) questions available", color: .green)
                }
            }

            Section("Games") {
                NavigationLink(destination: MatchingGameView()) {
                    practiceRow(icon: "rectangle.grid.2x2.fill", title: "Term Matching", subtitle: "Match terms to definitions", color: .blue)
                }
                NavigationLink(destination: FillInBlankView()) {
                    practiceRow(icon: "text.cursor", title: "Fill in the Blank", subtitle: "Complete key sentences", color: .purple)
                }
            }

            Section("Analysis") {
                NavigationLink(destination: WeakSpotsView()) {
                    practiceRow(icon: "exclamationmark.triangle.fill", title: "Weak Spots", subtitle: "See where you need to improve", color: .red)
                }
                NavigationLink(destination: ProgressDashboardView()) {
                    practiceRow(icon: "chart.bar.fill", title: "Progress", subtitle: "Track your study progress", color: .teal)
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
