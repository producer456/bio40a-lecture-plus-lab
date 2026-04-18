import SwiftUI

struct LectureQuiz5View: View {
    @Environment(ContentService.self) private var content
    @State private var startQuiz = false

    private var questions: [QuizQuestion] {
        content.allQuestions.filter { $0.chapterID == "lq5" }.shuffled()
    }

    var body: some View {
        List {
            Section {
                BioHeroBanner(
                    system: .muscular,
                    title: "Lecture Quiz 5",
                    subtitle: "Chapter 2 — Chemistry of Life\nbody cavities, water, metabolism, macromolecules",
                    height: 140
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                Button {
                    startQuiz = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Quiz")
                        Spacer()
                        Text("\(questions.count) questions")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Lecture Quiz 5 Practice")
        .navigationDestination(isPresented: $startQuiz) {
            QuizView(questions: questions, chapterTitle: "Lecture Quiz 5")
        }
    }
}
