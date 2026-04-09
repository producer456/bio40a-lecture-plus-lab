import SwiftUI
import SwiftData

// MARK: - Chapter Picker

struct InteractiveLearningListView: View {
    @Environment(ContentService.self) private var content
    @Query private var studyProgress: [StudyProgress]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Learning Through Interaction", systemImage: "hand.tap.fill")
                        .font(.headline)
                    Text("Read through lessons with interactive checkpoints that test your understanding as you go. Questions, term checks, and mini-challenges appear after every few paragraphs.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Choose a Chapter") {
                ForEach(content.chapters) { chapter in
                    ForEach(chapter.sections) { section in
                        if !section.content.isEmpty {
                            NavigationLink(destination: InteractiveLessonView(section: section, chapter: chapter)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ch. \(chapter.number)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(section.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(section.content.count) paragraphs \u{2022} \(section.glossary.count) terms \u{2022} \(section.reviewQuestions.count) questions")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundStyle(.blue.opacity(0.5))
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Interactive Learning")
    }
}

// MARK: - Interactive Lesson

struct InteractiveLessonView: View {
    let section: ChapterSection
    let chapter: Chapter
    @Environment(\.modelContext) private var modelContext
    @Environment(ContentService.self) private var content
    @AppStorage("userName") private var userName = ""

    @State private var currentBlockIndex = 0
    @State private var blocks: [LessonBlock] = []
    @State private var answeredInteractions: Set<Int> = []
    @State private var correctCount = 0
    @State private var totalInteractions = 0
    @State private var lessonComplete = false

    var body: some View {
        if lessonComplete {
            completionView
        } else if blocks.isEmpty {
            ProgressView("Preparing lesson...")
                .onAppear { buildBlocks() }
        } else {
            lessonScrollView
        }
    }

    // MARK: - Lesson Scroll View

    private var lessonScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Progress header
                    progressHeader

                    // Objectives
                    if !section.objectives.isEmpty {
                        objectivesCard
                    }

                    // Content blocks
                    ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                        if index <= currentBlockIndex {
                            blockView(block, index: index)
                                .id(index)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .padding()
            }
            .onChange(of: currentBlockIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(currentBlockIndex + 1), total: Double(blocks.count))
                .tint(.blue)
            HStack {
                Text("Block \(currentBlockIndex + 1) of \(blocks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if totalInteractions > 0 {
                    Text("\(correctCount)/\(totalInteractions) correct")
                        .font(.caption)
                        .foregroundStyle(correctCount == totalInteractions ? .green : .orange)
                }
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Objectives Card

    private var objectivesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Learning Objectives", systemImage: "target")
                .font(.subheadline)
                .fontWeight(.semibold)
            ForEach(section.objectives, id: \.self) { obj in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .padding(.top, 6)
                        .foregroundStyle(.blue)
                    Text(obj)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 16)
    }

    // MARK: - Block View

    @ViewBuilder
    private func blockView(_ block: LessonBlock, index: Int) -> some View {
        switch block {
        case .paragraph(let text):
            Text(text)
                .font(.body)
                .lineSpacing(5)
                .padding(.vertical, 8)

            // Show continue button if this is the current block and next is an interaction
            if index == currentBlockIndex && index + 1 < blocks.count {
                let nextBlock = blocks[index + 1]
                if case .paragraph = nextBlock {
                    continueButton(index: index)
                } else if case .image = nextBlock {
                    continueButton(index: index)
                } else {
                    continueButton(index: index, label: "Check Your Understanding")
                }
            }

        case .image(let name, let caption):
            SectionImageView(image: SectionImage(imageName: name, caption: caption))

            if index == currentBlockIndex && index + 1 < blocks.count {
                let nextBlock = blocks[index + 1]
                if case .paragraph = nextBlock {
                    continueButton(index: index)
                } else if case .image = nextBlock {
                    continueButton(index: index)
                } else {
                    continueButton(index: index, label: "Check Your Understanding")
                }
            }

        case .termCheck(let term, let definition, let options):
            interactionCard(index: index) {
                termCheckView(term: term, definition: definition, options: options, index: index)
            }

        case .quickQuiz(let question):
            interactionCard(index: index) {
                quickQuizView(question: question, index: index)
            }

        case .fillBlank(let term, let sentence):
            interactionCard(index: index) {
                fillBlankView(term: term, sentence: sentence, index: index)
            }

        case .trueOrFalse(let statement, let isTrue, let explanation):
            interactionCard(index: index) {
                trueOrFalseView(statement: statement, isTrue: isTrue, explanation: explanation, index: index)
            }

        case .chapterReview(let text):
            VStack(alignment: .leading, spacing: 8) {
                Divider().padding(.vertical, 8)
                Label("Section Review", systemImage: "doc.text.fill")
                    .font(.headline)
                Text(text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .padding(.vertical, 8)

            if index == currentBlockIndex && index + 1 <= blocks.count - 1 {
                continueButton(index: index)
            } else if index == blocks.count - 1 && index == currentBlockIndex {
                finishButton
            }
        }
    }

    // MARK: - Interaction Wrapper

    private func interactionCard(index: Int, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(.blue)
                Text("Interactive Check")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Spacer()
            }
            .padding(.bottom, 8)

            content()
        }
        .padding()
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .padding(.vertical, 12)
    }

    // MARK: - Term Check

    @ViewBuilder
    private func termCheckView(term: String, definition: String, options: [String], index: Int) -> some View {
        let answered = answeredInteractions.contains(index)

        TermCheckInteraction(
            term: term,
            definition: definition,
            options: options,
            answered: answered,
            onAnswer: { isCorrect in
                markInteraction(index: index, correct: isCorrect)
            },
            onContinue: { advanceFrom(index) }
        )
    }

    // MARK: - Quick Quiz

    @ViewBuilder
    private func quickQuizView(question: QuizQuestion, index: Int) -> some View {
        QuickQuizInteraction(
            question: question,
            answered: answeredInteractions.contains(index),
            onAnswer: { isCorrect in
                markInteraction(index: index, correct: isCorrect)
                if let chID = question.chapterID, let sID = question.sectionID {
                    let record = PerformanceRecord(
                        questionID: question.id,
                        chapterID: chID,
                        sectionID: sID,
                        wasCorrect: isCorrect,
                        quizType: "interactiveLearning"
                    )
                    modelContext.insert(record)
                }
            },
            onContinue: { advanceFrom(index) }
        )
    }

    // MARK: - Fill in the Blank

    @ViewBuilder
    private func fillBlankView(term: String, sentence: String, index: Int) -> some View {
        FillBlankInteraction(
            term: term,
            sentence: sentence,
            answered: answeredInteractions.contains(index),
            onAnswer: { isCorrect in
                markInteraction(index: index, correct: isCorrect)
            },
            onContinue: { advanceFrom(index) }
        )
    }

    // MARK: - True or False

    @ViewBuilder
    private func trueOrFalseView(statement: String, isTrue: Bool, explanation: String, index: Int) -> some View {
        TrueOrFalseInteraction(
            statement: statement,
            isTrue: isTrue,
            explanation: explanation,
            answered: answeredInteractions.contains(index),
            onAnswer: { isCorrect in
                markInteraction(index: index, correct: isCorrect)
            },
            onContinue: { advanceFrom(index) }
        )
    }

    // MARK: - Continue / Finish Buttons

    private func continueButton(index: Int, label: String = "Continue Reading") -> some View {
        Button {
            advanceFrom(index)
        } label: {
            HStack {
                Text(label)
                    .fontWeight(.medium)
                Image(systemName: "arrow.down")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.vertical, 8)
    }

    private var finishButton: some View {
        Button {
            lessonComplete = true
            // Track progress
            let progress = StudyProgress(chapterID: chapter.id, sectionID: section.id, readPercentage: 1.0)
            modelContext.insert(progress)
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Lesson")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Completion View

    private var completionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.yellow)

                Text(userName.isEmpty ? "Lesson Complete!" : "Great work, \(userName)!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(section.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if totalInteractions > 0 {
                    VStack(spacing: 8) {
                        Text("\(correctCount)/\(totalInteractions)")
                            .font(.system(size: 40, weight: .bold))
                        Text("interactive checks correct")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        let pct = Double(correctCount) / Double(totalInteractions)
                        Text(pct >= 0.8 ? "Excellent understanding!" : pct >= 0.6 ? "Good progress, review the tricky parts" : "Consider re-reading this section")
                            .font(.caption)
                            .foregroundStyle(pct >= 0.8 ? .green : .orange)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                // Next section suggestion
                if let nextSection = nextSection {
                    NavigationLink(destination: InteractiveLessonView(section: nextSection, chapter: chapter)) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Next: \(nextSection.title)")
                        }
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                Button("Start Over") {
                    currentBlockIndex = 0
                    answeredInteractions = []
                    correctCount = 0
                    totalInteractions = 0
                    lessonComplete = false
                }
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Complete")
    }

    private var nextSection: ChapterSection? {
        guard let currentIndex = chapter.sections.firstIndex(where: { $0.id == section.id }) else { return nil }
        let nextIndex = currentIndex + 1
        guard nextIndex < chapter.sections.count else { return nil }
        let next = chapter.sections[nextIndex]
        return next.content.isEmpty ? nil : next
    }

    // MARK: - Block Building

    private func buildBlocks() {
        var result: [LessonBlock] = []
        let paragraphs = section.content
        let terms = section.glossary
        let questions = section.reviewQuestions
        let sectionImages = section.images ?? []

        // Build image insertion schedule: space images evenly through paragraphs
        var imageSchedule: [Int: Int] = [:]  // paragraph index -> image index
        if !sectionImages.isEmpty && !paragraphs.isEmpty {
            let spacing = max(2, paragraphs.count / (sectionImages.count + 1))
            var imgIdx = 0
            for paraIdx in stride(from: spacing - 1, to: paragraphs.count, by: spacing) {
                if imgIdx >= sectionImages.count { break }
                imageSchedule[paraIdx] = imgIdx
                imgIdx += 1
            }
        }

        // Interleave content with interactions every 2-4 paragraphs
        var paragraphsSinceInteraction = 0
        var usedTermIndices: Set<Int> = []
        var usedQuestionIndices: Set<Int> = []
        var interactionTypes: [Int] = [0, 1, 2, 3] // rotate through types

        for (pi, paragraph) in paragraphs.enumerated() {
            result.append(.paragraph(paragraph))
            paragraphsSinceInteraction += 1

            // Insert image if scheduled for this paragraph
            if let imgIdx = imageSchedule[pi], imgIdx < sectionImages.count {
                let img = sectionImages[imgIdx]
                result.append(.image(name: img.imageName, caption: img.caption))
            }

            // Insert interaction every 2-3 paragraphs (not after the last one)
            let threshold = Int.random(in: 2...3)
            if paragraphsSinceInteraction >= threshold && pi < paragraphs.count - 1 {
                if let interaction = generateInteraction(
                    terms: terms,
                    questions: questions,
                    usedTermIndices: &usedTermIndices,
                    usedQuestionIndices: &usedQuestionIndices,
                    interactionTypes: &interactionTypes
                ) {
                    result.append(interaction)
                    paragraphsSinceInteraction = 0
                }
            }
        }

        // Add chapter review at the end if available
        let reviewText = section.chapterReviewText
        if !reviewText.isEmpty {
            result.append(.chapterReview(reviewText))
        }

        // Add any remaining questions as a final quiz
        let remainingQuestions = questions.indices.filter { !usedQuestionIndices.contains($0) }
        for qi in remainingQuestions.prefix(2) {
            result.append(.quickQuiz(questions[qi]))
        }

        blocks = result
    }

    private func generateInteraction(
        terms: [GlossaryTerm],
        questions: [QuizQuestion],
        usedTermIndices: inout Set<Int>,
        usedQuestionIndices: inout Set<Int>,
        interactionTypes: inout [Int]
    ) -> LessonBlock? {
        // Rotate through interaction types
        let typeIndex = interactionTypes.removeFirst()
        interactionTypes.append(typeIndex)

        switch typeIndex {
        case 0:
            // Term check: show definition, pick the right term
            let availableTerms = terms.indices.filter { !usedTermIndices.contains($0) }
            guard availableTerms.count >= 3 else { return generateFallback(terms: terms, questions: questions, usedQuestionIndices: &usedQuestionIndices) }
            let correctIdx = availableTerms.randomElement()!
            usedTermIndices.insert(correctIdx)
            let correct = terms[correctIdx]
            // Pick 3 wrong options from other terms
            var wrongOptions = availableTerms.filter { $0 != correctIdx }.shuffled().prefix(3).map { terms[$0].term }
            if wrongOptions.count < 3 {
                // Pad with terms from other sections
                let otherTerms = content.glossaryTerms.filter { $0.term != correct.term }.shuffled().prefix(3 - wrongOptions.count)
                wrongOptions.append(contentsOf: otherTerms.map(\.term))
            }
            var options = wrongOptions + [correct.term]
            options.shuffle()
            return .termCheck(term: correct.term, definition: correct.definition, options: options)

        case 1:
            // Quick quiz from section review questions
            let availableQs = questions.indices.filter { !usedQuestionIndices.contains($0) }
            guard let qi = availableQs.randomElement() else { return generateFallback(terms: terms, questions: questions, usedQuestionIndices: &usedQuestionIndices) }
            usedQuestionIndices.insert(qi)
            return .quickQuiz(questions[qi])

        case 2:
            // Fill in the blank using a glossary term
            let availableTerms = terms.indices.filter { !usedTermIndices.contains($0) }
            guard let ti = availableTerms.randomElement() else { return generateFallback(terms: terms, questions: questions, usedQuestionIndices: &usedQuestionIndices) }
            usedTermIndices.insert(ti)
            let term = terms[ti]
            let sentence = "\(term.definition.prefix(1).uppercased())\(term.definition.dropFirst()). This describes the term ________."
            return .fillBlank(term: term.term, sentence: sentence)

        case 3:
            // True or false from glossary
            let availableTerms = terms.indices.filter { !usedTermIndices.contains($0) }
            guard availableTerms.count >= 2 else { return generateFallback(terms: terms, questions: questions, usedQuestionIndices: &usedQuestionIndices) }

            let isTrue = Bool.random()
            let ti = availableTerms.randomElement()!

            if isTrue {
                let term = terms[ti]
                return .trueOrFalse(
                    statement: "\"\(term.term.capitalized)\" refers to: \(term.definition)",
                    isTrue: true,
                    explanation: "Correct! \(term.term.capitalized) is defined as: \(term.definition)"
                )
            } else {
                // Mix up: use one term's name with another's definition
                let otherIdx = availableTerms.filter { $0 != ti }.randomElement() ?? ti
                let term1 = terms[ti]
                let term2 = terms[otherIdx]
                return .trueOrFalse(
                    statement: "\"\(term1.term.capitalized)\" refers to: \(term2.definition)",
                    isTrue: false,
                    explanation: "That's actually the definition of \"\(term2.term)\". \"\(term1.term.capitalized)\" means: \(term1.definition)"
                )
            }

        default:
            return nil
        }
    }

    private func generateFallback(terms: [GlossaryTerm], questions: [QuizQuestion], usedQuestionIndices: inout Set<Int>) -> LessonBlock? {
        let availableQs = questions.indices.filter { !usedQuestionIndices.contains($0) }
        if let qi = availableQs.randomElement() {
            usedQuestionIndices.insert(qi)
            return .quickQuiz(questions[qi])
        }
        return nil
    }

    // MARK: - Helpers

    private func advanceFrom(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentBlockIndex < blocks.count - 1 {
                currentBlockIndex += 1
            } else {
                lessonComplete = true
                let progress = StudyProgress(chapterID: chapter.id, sectionID: section.id, readPercentage: 1.0)
                modelContext.insert(progress)
            }
        }
    }

    private func markInteraction(index: Int, correct: Bool) {
        answeredInteractions.insert(index)
        totalInteractions += 1
        if correct { correctCount += 1 }
    }
}

// MARK: - Lesson Block

enum LessonBlock {
    case paragraph(String)
    case image(name: String, caption: String)
    case termCheck(term: String, definition: String, options: [String])
    case quickQuiz(QuizQuestion)
    case fillBlank(term: String, sentence: String)
    case trueOrFalse(statement: String, isTrue: Bool, explanation: String)
    case chapterReview(String)
}
