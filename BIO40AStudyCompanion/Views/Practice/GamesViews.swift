import SwiftUI
import SwiftData

// MARK: - Games Menu

struct GamesMenuView: View {
    @Environment(ContentService.self) private var content

    var body: some View {
        List {
            Section("Choose a Game") {
                NavigationLink(destination: MatchingGameView()) {
                    gameRow(icon: "rectangle.grid.2x2.fill", title: "Term Matching", subtitle: "Match terms to their definitions", color: .blue)
                }
                NavigationLink(destination: FillInBlankView()) {
                    gameRow(icon: "text.cursor", title: "Fill in the Blank", subtitle: "Complete sentences with key terms", color: .purple)
                }
            }
        }
        .navigationTitle("Games")
    }

    private func gameRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Matching Game

struct MatchingGameView: View {
    @Environment(ContentService.self) private var content
    @State private var selectedChapter: String = ""
    @State private var terms: [GlossaryTerm] = []
    @State private var shuffledDefinitions: [String] = []
    @State private var selectedTerm: Int? = nil
    @State private var selectedDef: Int? = nil
    @State private var matched: Set<Int> = []
    @State private var wrongPair: (Int, Int)? = nil
    @State private var gameComplete = false
    @State private var attempts = 0

    var body: some View {
        VStack {
            if terms.isEmpty {
                chapterPicker
            } else if gameComplete {
                gameCompleteView
            } else {
                gameBoard
            }
        }
        .navigationTitle("Term Matching")
    }

    private var chapterPicker: some View {
        List {
            Section("Select Chapter") {
                ForEach(content.chapters) { chapter in
                    Button {
                        startGame(chapterID: chapter.id)
                    } label: {
                        HStack {
                            Text("Ch. \(chapter.number): \(chapter.title)")
                                .font(.subheadline)
                            Spacer()
                            Text("\(chapter.glossaryTerms.count) terms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
            }
        }
    }

    private var gameBoard: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats
                HStack {
                    Text("Matched: \(matched.count)/\(terms.count)")
                        .font(.subheadline)
                    Spacer()
                    Text("Attempts: \(attempts)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Game grid
                HStack(alignment: .top, spacing: 12) {
                    // Terms column
                    VStack(spacing: 8) {
                        Text("Terms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(Array(terms.enumerated()), id: \.offset) { index, term in
                            Button {
                                if !matched.contains(index) {
                                    selectedTerm = index
                                    checkMatch()
                                }
                            } label: {
                                Text(term.term)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(termBackground(index), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .tint(.primary)
                            .disabled(matched.contains(index))
                        }
                    }

                    // Definitions column
                    VStack(spacing: 8) {
                        Text("Definitions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(Array(shuffledDefinitions.enumerated()), id: \.offset) { index, def in
                            let originalIndex = terms.firstIndex { $0.definition == def } ?? -1
                            Button {
                                if !matched.contains(originalIndex) {
                                    selectedDef = index
                                    checkMatch()
                                }
                            } label: {
                                Text(def)
                                    .font(.caption2)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(defBackground(index, originalIndex: originalIndex), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .tint(.primary)
                            .disabled(matched.contains(originalIndex))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func termBackground(_ index: Int) -> some ShapeStyle {
        if matched.contains(index) { return AnyShapeStyle(.green.opacity(0.2)) }
        if selectedTerm == index { return AnyShapeStyle(.blue.opacity(0.3)) }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    private func defBackground(_ defIndex: Int, originalIndex: Int) -> some ShapeStyle {
        if matched.contains(originalIndex) { return AnyShapeStyle(.green.opacity(0.2)) }
        if selectedDef == defIndex { return AnyShapeStyle(.blue.opacity(0.3)) }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    private var gameCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            Text("All Matched!")
                .font(.title2)
                .fontWeight(.bold)
            Text("Completed in \(attempts) attempts")
                .foregroundStyle(.secondary)
            Button("Play Again") {
                terms = []
                matched = []
                attempts = 0
                gameComplete = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func startGame(chapterID: String) {
        let allTerms = content.glossaryForChapter(chapterID)
        terms = Array(allTerms.shuffled().prefix(8))
        shuffledDefinitions = terms.map(\.definition).shuffled()
        matched = []
        attempts = 0
        selectedTerm = nil
        selectedDef = nil
    }

    private func checkMatch() {
        guard let termIdx = selectedTerm, let defIdx = selectedDef else { return }
        attempts += 1

        let term = terms[termIdx]
        let def = shuffledDefinitions[defIdx]

        if term.definition == def {
            matched.insert(termIdx)
            selectedTerm = nil
            selectedDef = nil
            if matched.count == terms.count {
                gameComplete = true
            }
        } else {
            wrongPair = (termIdx, defIdx)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                selectedTerm = nil
                selectedDef = nil
                wrongPair = nil
            }
        }
    }
}

// MARK: - Fill in the Blank

struct FillInBlankView: View {
    @Environment(ContentService.self) private var content
    @State private var currentTermIndex = 0
    @State private var userInput = ""
    @State private var showAnswer = false
    @State private var score = 0
    @State private var total = 0
    @State private var terms: [GlossaryTerm] = []
    @State private var gameStarted = false

    var body: some View {
        VStack {
            if !gameStarted {
                chapterPicker
            } else if currentTermIndex >= terms.count {
                resultsView
            } else {
                fillView
            }
        }
        .navigationTitle("Fill in the Blank")
    }

    private var chapterPicker: some View {
        List {
            Section("Select Chapter") {
                ForEach(content.chapters) { chapter in
                    Button {
                        terms = Array(chapter.glossaryTerms.shuffled().prefix(10))
                        gameStarted = true
                    } label: {
                        Text("Ch. \(chapter.number): \(chapter.title)")
                            .font(.subheadline)
                    }
                    .tint(.primary)
                }
            }
        }
    }

    private var fillView: some View {
        VStack(spacing: 24) {
            // Progress
            Text("\(currentTermIndex + 1) / \(terms.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Definition as clue
            let term = terms[currentTermIndex]
            VStack(spacing: 16) {
                Text("What term matches this definition?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(term.definition)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            // Input
            TextField("Type your answer...", text: $userInput)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal)

            if showAnswer {
                VStack(spacing: 8) {
                    let isCorrect = userInput.lowercased().trimmingCharacters(in: .whitespaces) == term.term.lowercased().trimmingCharacters(in: .whitespaces)
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isCorrect ? .green : .red)
                        Text(isCorrect ? "Correct!" : "The answer is: \(term.term)")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                }
            }

            Spacer()

            // Buttons
            if !showAnswer {
                HStack(spacing: 16) {
                    Button("Skip") {
                        showAnswer = true
                        total += 1
                    }
                    .buttonStyle(.bordered)

                    Button("Check") {
                        showAnswer = true
                        total += 1
                        let isCorrect = userInput.lowercased().trimmingCharacters(in: .whitespaces) == terms[currentTermIndex].term.lowercased().trimmingCharacters(in: .whitespaces)
                        if isCorrect { score += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userInput.isEmpty)
                }
            } else {
                Button("Next") {
                    currentTermIndex += 1
                    userInput = ""
                    showAnswer = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var resultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Game Over!")
                .font(.title2)
                .fontWeight(.bold)
            Text("\(score)/\(total) correct")
                .font(.title3)
            Button("Play Again") {
                gameStarted = false
                currentTermIndex = 0
                score = 0
                total = 0
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
