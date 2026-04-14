import SwiftUI

struct LectureQuiz1View: View {
    @Environment(ContentService.self) private var content
    @State private var selectedMode: QuizMode = .all
    @State private var startQuiz = false

    enum QuizMode: String, CaseIterable {
        case basic = "Basic (50 questions)"
        case advanced = "Advanced (50 questions)"
        case all = "Full Quiz (100 questions)"
    }

    private var filteredQuestions: [QuizQuestion] {
        let lq1 = content.allQuestions.filter { $0.chapterID == "lq1" }
        switch selectedMode {
        case .basic:
            return lq1.filter { $0.sectionID == "lq1_basic" }.shuffled()
        case .advanced:
            return lq1.filter { $0.sectionID == "lq1_advanced" }.shuffled()
        case .all:
            return lq1.shuffled()
        }
    }

    var body: some View {
        List {
            Section {
                BioHeroBanner(
                    system: .skeletal,
                    title: "Lecture Quiz 1",
                    subtitle: "Anatomical terminology, body planes & cavities,\nelements, isotopes, bonds, properties of water",
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
                            if mode == .basic {
                                Text("Fundamentals")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if mode == .advanced {
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
        .navigationTitle("Lecture Quiz 1 Practice")
        .navigationDestination(isPresented: $startQuiz) {
            QuizView(questions: filteredQuestions, chapterTitle: "Lecture Quiz 1")
        }
    }
}
