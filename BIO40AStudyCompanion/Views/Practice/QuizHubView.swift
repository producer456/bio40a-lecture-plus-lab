import SwiftUI

struct QuizHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero banner
                BioHeroBanner(
                    system: .cardiovascular,
                    title: "Quizzes",
                    subtitle: "Test your knowledge with lecture quizzes",
                    badge: "QUIZZES",
                    height: 120
                )

                // Lecture Quiz Practice
                VStack(alignment: .leading, spacing: 12) {
                    BioSectionHeader(title: "Lecture Quiz Practice", icon: "doc.text.fill", system: .cardiovascular)

                    NavigationLink(destination: LectureQuiz1View()) {
                        quizCard(title: "Lecture Quiz 1", subtitle: "100 questions — anatomy, chemistry, body systems", system: .skeletal)
                    }
                    NavigationLink(destination: LectureQuiz2View()) {
                        quizCard(title: "Lecture Quiz 2", subtitle: "100 questions — syllabus, macromolecules, enzymes, clinical", system: .nervous)
                    }
                    NavigationLink(destination: LectureQuiz3View()) {
                        quizCard(title: "Lecture Quiz 3", subtitle: "34 questions — chemistry, bonds, proteins, beta amyloid", system: .endocrine)
                    }
                    NavigationLink(destination: LectureQuiz4View()) {
                        quizCard(title: "Lecture Quiz 4", subtitle: "100 questions — comprehensive review, clinical cases, imaging", system: .cardiovascular)
                    }
                    NavigationLink(destination: LectureQuiz5View()) {
                        quizCard(title: "Lecture Quiz 5", subtitle: "100 questions — Ch.2 chemistry of life, metabolism, macromolecules", system: .muscular)
                    }
                }

                // Custom Practice
                VStack(alignment: .leading, spacing: 12) {
                    BioSectionHeader(title: "Custom Practice", icon: "slider.horizontal.3", system: .cardiovascular)

                    NavigationLink(destination: QuizSetupView()) {
                        BioCard(system: .cardiovascular) {
                            HStack(spacing: 14) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(BodySystem.cardiovascular.primaryColor)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Practice Quiz")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text("Build a quiz from any chapter")
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Quizzes")
    }

    private func quizCard(title: String, subtitle: String, system: BodySystem) -> some View {
        BioCard(system: system) {
            HStack(spacing: 14) {
                Image(systemName: "doc.text.fill")
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
