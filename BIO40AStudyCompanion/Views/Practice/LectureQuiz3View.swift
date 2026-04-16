import SwiftUI

struct LectureQuiz3View: View {
    @Environment(ContentService.self) private var content
    @State private var selectedMode: QuizMode = .all
    @State private var startQuiz = false

    enum QuizMode: String, CaseIterable {
        case chem = "Chemistry (17 questions)"
        case biochem = "Biochemistry (17 questions)"
        case all = "Full Quiz (34 questions)"
    }

    private var filteredQuestions: [QuizQuestion] {
        let lq3 = content.allQuestions.filter { $0.chapterID == "lq3" }
        switch selectedMode {
        case .chem:
            return lq3.filter { $0.sectionID == "lq3_chem" }.shuffled()
        case .biochem:
            return lq3.filter { $0.sectionID == "lq3_biochem" }.shuffled()
        case .all:
            return lq3.shuffled()
        }
    }

    var body: some View {
        List {
            Section {
                BioHeroBanner(
                    system: .endocrine,
                    title: "Lecture Quiz 3",
                    subtitle: "Chemistry & Biochemistry:\natoms, bonds, macromolecules, proteins",
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
                            if mode == .chem {
                                Text("Atoms & Bonds")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if mode == .biochem {
                                Text("Macromolecules")
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
        .navigationTitle("Lecture Quiz 3 Practice")
        .navigationDestination(isPresented: $startQuiz) {
            QuizView(questions: filteredQuestions, chapterTitle: "Lecture Quiz 3")
        }
    }
}
