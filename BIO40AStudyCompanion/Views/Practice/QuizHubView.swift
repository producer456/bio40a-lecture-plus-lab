import SwiftUI

struct QuizHubView: View {
    var body: some View {
        List {
            Section("Lecture Quiz Practice") {
                NavigationLink(destination: LectureQuiz1View()) {
                    HStack(spacing: 14) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundStyle(BodySystem.skeletal.primaryColor)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lecture Quiz 1")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("100 questions — anatomy, chemistry, body systems")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
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
}
