import SwiftUI

struct LectureQuiz2View: View {
    @Environment(ContentService.self) private var content
    @State private var selectedMode: QuizMode = .all
    @State private var startQuiz = false

    enum QuizMode: String, CaseIterable {
        case normal = "Normal (50 questions)"
        case hard = "Hard (50 questions)"
        case all = "Full Quiz (100 questions)"
    }

    private var filteredQuestions: [QuizQuestion] {
        let lq2 = content.allQuestions.filter { $0.chapterID == "lq2" }
        switch selectedMode {
        case .normal:
            return lq2.filter { $0.sectionID == "lq2_normal" }.shuffled()
        case .hard:
            return lq2.filter { $0.sectionID == "lq2_hard" }.shuffled()
        case .all:
            return lq2.shuffled()
        }
    }

    var body: some View {
        List {
            Section {
                BioHeroBanner(
                    system: .nervous,
                    title: "Lecture Quiz 2",
                    subtitle: "Syllabus policies, anatomy, chemistry,\nmacromolecules, enzymes, clinical cases",
                    height: 140
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Quiz Mode") {
                ForEach(QuizMode.allCases, id: \.self) { mode in
                    Button {
                        selectedMode = mode
                    } label: {
                        HStack {
                            Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedMode == mode ? .blue : .gray)
                            Text(mode.rawValue)
                                .font(.subheadline)
                            Spacer()
                            if mode == .normal {
                                Text("Fundamentals")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if mode == .hard {
                                Text("Clinical & Applied")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.primary)
                }
            }

            Section {
                Button {
                    startQuiz = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Quiz")
                        Spacer()
                        Text("\(filteredQuestions.count) questions")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Lecture Quiz 2 Practice")
        .navigationDestination(isPresented: $startQuiz) {
            QuizView(questions: filteredQuestions, chapterTitle: "Lecture Quiz 2")
        }
    }
}
