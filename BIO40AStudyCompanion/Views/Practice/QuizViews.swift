import SwiftUI
import SwiftData

// MARK: - Quiz Setup

struct QuizSetupView: View {
    @Environment(ContentService.self) private var content
    @Query private var performanceRecords: [PerformanceRecord]
    @State private var selectedChapters: Set<String> = []
    @State private var questionCount = 20
    @State private var focusWeakSpots = false
    @State private var startQuiz = false

    var body: some View {
        List {
            Section("Select Chapters") {
                ForEach(content.chapters) { chapter in
                    let questionCount = content.questionsForChapter(chapter.id).count
                    Button {
                        if selectedChapters.contains(chapter.id) {
                            selectedChapters.remove(chapter.id)
                        } else {
                            selectedChapters.insert(chapter.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedChapters.contains(chapter.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedChapters.contains(chapter.id) ? .blue : .gray)
                            VStack(alignment: .leading) {
                                Text("Ch. \(chapter.number): \(chapter.title)")
                                    .font(.subheadline)
                                Text("\(questionCount) questions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.primary)
                }

                Button("Select All") {
                    selectedChapters = Set(content.chapters.map(\.id))
                }
                .font(.subheadline)
            }

            Section("Options") {
                Stepper("Questions: \(questionCount)", value: $questionCount, in: 5...50, step: 5)
                Toggle("Focus on Weak Spots", isOn: $focusWeakSpots)
            }

            Section {
                let available = selectedChapters.flatMap { content.questionsForChapter($0) }.count
                NavigationLink(destination: QuizView(
                    questions: generateQuiz(),
                    chapterTitle: "Practice Quiz"
                )) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Quiz")
                        Spacer()
                        Text("\(min(questionCount, available)) questions")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(selectedChapters.isEmpty)
            }
        }
        .navigationTitle("Practice Quiz")
    }

    private func generateQuiz() -> [QuizQuestion] {
        let allQ = selectedChapters.flatMap { content.questionsForChapter($0) }

        if focusWeakSpots && !performanceRecords.isEmpty {
            let generator = QuizGeneratorService()
            return generator.generateQuiz(
                chapters: Array(selectedChapters),
                questionCount: questionCount,
                allQuestions: allQ,
                focusWeakSpots: true,
                performanceRecords: performanceRecords
            )
        }

        return Array(allQ.shuffled().prefix(questionCount))
    }
}

// MARK: - Quiz View

struct QuizView: View {
    let questions: [QuizQuestion]
    let chapterTitle: String
    @Environment(\.modelContext) private var modelContext
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var showResult = false
    @State private var score = 0
    @State private var missedIDs: [String] = []
    @State private var quizComplete = false
    @State private var answers: [Int: Int] = [:] // questionIndex: selectedAnswer

    var body: some View {
        if quizComplete {
            quizResultsView
        } else if questions.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("No questions available")
                    .font(.title3)
                Text("Try selecting different chapters")
                    .foregroundStyle(.secondary)
            }
        } else {
            questionView
        }
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentIndex), total: Double(questions.count))
                .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question number
                    Text("Question \(currentIndex + 1) of \(questions.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Question text
                    let q = questions[currentIndex]
                    Text(q.question)
                        .font(.body)
                        .fontWeight(.medium)

                    // Choices
                    ForEach(Array(q.choices.enumerated()), id: \.offset) { index, choice in
                        Button {
                            if !showResult {
                                selectedAnswer = index
                            }
                        } label: {
                            HStack(alignment: .top) {
                                Text("\(["A", "B", "C", "D"][index]).")
                                    .fontWeight(.bold)
                                    .frame(width: 24)
                                Text(choice)
                                Spacer()
                                if showResult {
                                    if index == q.correctAnswer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if index == selectedAnswer {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(choiceBackground(index: index, question: q), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                    }

                    // Explanation
                    if showResult, let explanation = q.explanation, !explanation.isEmpty {
                        Text(explanation)
                            .font(.callout)
                            .padding()
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }

            // Bottom buttons
            HStack(spacing: 16) {
                if !showResult {
                    Button {
                        guard let selected = selectedAnswer else { return }
                        showResult = true
                        answers[currentIndex] = selected
                        let q = questions[currentIndex]
                        if selected == q.correctAnswer {
                            score += 1
                        } else {
                            missedIDs.append(q.id ?? "")
                        }
                        recordPerformance(question: q, wasCorrect: selected == q.correctAnswer)
                    } label: {
                        Text("Check Answer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedAnswer != nil ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .disabled(selectedAnswer == nil)
                } else {
                    Button {
                        if currentIndex + 1 < questions.count {
                            currentIndex += 1
                            selectedAnswer = nil
                            showResult = false
                        } else {
                            saveQuizAttempt()
                            quizComplete = true
                        }
                    } label: {
                        Text(currentIndex + 1 < questions.count ? "Next Question" : "See Results")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(chapterTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choiceBackground(index: Int, question: QuizQuestion) -> some ShapeStyle {
        if showResult {
            if index == question.correctAnswer {
                return AnyShapeStyle(.green.opacity(0.15))
            } else if index == selectedAnswer {
                return AnyShapeStyle(.red.opacity(0.15))
            }
        } else if index == selectedAnswer {
            return AnyShapeStyle(.blue.opacity(0.15))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    // MARK: - Results

    private var quizResultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score
                VStack(spacing: 8) {
                    Text("\(score)/\(questions.count)")
                        .font(.system(size: 48, weight: .bold))
                    Text("\(Int(Double(score) / Double(questions.count) * 100))%")
                        .font(.title2)
                        .foregroundStyle(scoreColor)
                    Text(scoreMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()

                // Missed questions
                if !missedIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review Missed Questions")
                            .font(.headline)

                        ForEach(Array(questions.enumerated()), id: \.offset) { index, q in
                            if let selected = answers[index], selected != q.correctAnswer {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(q.question)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Your answer: \(q.choices[selected])")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                    Text("Correct: \(q.choices[q.correctAnswer])")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Results")
    }

    private var scoreColor: Color {
        let pct = Double(score) / Double(questions.count)
        if pct >= 0.8 { return .green }
        if pct >= 0.6 { return .yellow }
        return .red
    }

    private var scoreMessage: String {
        let pct = Double(score) / Double(questions.count)
        if pct >= 0.9 { return "Excellent work!" }
        if pct >= 0.8 { return "Great job!" }
        if pct >= 0.7 { return "Good effort, keep studying!" }
        if pct >= 0.6 { return "Review the material and try again" }
        return "Focus on your weak spots and retry"
    }

    private func recordPerformance(question: QuizQuestion, wasCorrect: Bool) {
        let record = PerformanceRecord(
            questionID: question.id ?? UUID().uuidString,
            chapterID: question.chapterID ?? "",
            sectionID: question.sectionID ?? "",
            wasCorrect: wasCorrect
        )
        modelContext.insert(record)
    }

    private func saveQuizAttempt() {
        let chapterIDs = Array(Set(questions.compactMap(\.chapterID)))
        let attempt = QuizAttempt(
            chapterIDs: chapterIDs,
            score: score,
            totalQuestions: questions.count,
            missedQuestionIDs: missedIDs
        )
        modelContext.insert(attempt)
    }
}
