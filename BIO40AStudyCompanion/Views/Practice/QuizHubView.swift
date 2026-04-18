import SwiftUI

struct QuizHubView: View {
    var body: some View {
        List {
            Section("Lecture Quiz Practice") {
                NavigationLink(destination: LectureQuiz1View()) {
                    quizRow(title: "Lecture Quiz 1", subtitle: "100 questions — anatomy, chemistry, body systems", color: BodySystem.skeletal.primaryColor)
                }
                NavigationLink(destination: LectureQuiz2View()) {
                    quizRow(title: "Lecture Quiz 2", subtitle: "100 questions — syllabus, macromolecules, enzymes, clinical", color: BodySystem.nervous.primaryColor)
                }
                NavigationLink(destination: LectureQuiz3View()) {
                    quizRow(title: "Lecture Quiz 3", subtitle: "34 questions — chemistry, bonds, proteins, beta amyloid", color: BodySystem.endocrine.primaryColor)
                }
                NavigationLink(destination: LectureQuiz4View()) {
                    quizRow(title: "Lecture Quiz 4", subtitle: "100 questions — comprehensive review, clinical cases, imaging", color: BodySystem.cardiovascular.primaryColor)
                }
                NavigationLink(destination: LectureQuiz5View()) {
                    quizRow(title: "Lecture Quiz 5", subtitle: "100 questions — Ch.2 chemistry of life, metabolism, macromolecules", color: BodySystem.muscular.primaryColor)
                }
            }

            Section("Custom Practice") {
                NavigationLink(destination: QuizSetupView()) {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(BodySystem.cardiovascular.primaryColor)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Practice Quiz")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Build a quiz from any chapter")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Quizzes")
    }

    private func quizRow(title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
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
