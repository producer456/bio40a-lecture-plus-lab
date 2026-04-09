import SwiftUI
import SwiftData

// MARK: - How We Learn Hub

struct HowWeLearnView: View {
    @Environment(ContentService.self) private var content
    @AppStorage("userName") private var userName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How We Learn")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Evidence-based techniques from cognitive psychology, applied to your A&P studies")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !userName.isEmpty {
                        Text("\(userName), using these techniques can help you retain 2-3x more material.")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)

                // Key insight card
                insightCard

                // Technique cards
                ForEach(LearningTechnique.all) { technique in
                    NavigationLink(destination: TechniqueDetailView(technique: technique)) {
                        techniqueCard(technique)
                    }
                    .tint(.primary)
                }

                // Smart Study Mode
                NavigationLink(destination: SmartStudyView()) {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(.yellow)
                        Text("Smart Study Mode")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Combines all techniques into one optimized study session tailored to your weak spots")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal)
                    .background(
                        LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("How We Learn")
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("The Key Insight")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            Text("Research shows that how you study matters more than how long you study. Students using active recall retain 80% of material after one week — compared to just 36% for those who re-read the same content.")
                .font(.caption)
            Text("— Roediger & Karpicke, 2006")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding()
        .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func techniqueCard(_ technique: LearningTechnique) -> some View {
        HStack(spacing: 14) {
            Image(systemName: technique.icon)
                .font(.title2)
                .foregroundStyle(technique.color)
                .frame(width: 40, height: 40)
                .background(technique.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(technique.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(technique.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

// MARK: - Technique Detail View

struct TechniqueDetailView: View {
    let technique: LearningTechnique
    @Environment(ContentService.self) private var content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: technique.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(technique.color)
                    Text(technique.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(technique.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                // What is it?
                sectionCard(title: "What Is It?", icon: "info.circle.fill", color: .blue) {
                    Text(technique.explanation)
                        .font(.body)
                        .lineSpacing(4)
                }

                // The Research
                sectionCard(title: "The Research", icon: "book.closed.fill", color: .green) {
                    Text(technique.keyResearch)
                        .font(.body)
                        .lineSpacing(4)
                }

                // For A&P Specifically
                sectionCard(title: "For A&P Specifically", icon: "figure.stand", color: .purple) {
                    Text(technique.apApplication)
                        .font(.body)
                        .lineSpacing(4)
                }

                // How to Use in This App
                sectionCard(title: "How to Use It", icon: "iphone", color: .orange) {
                    Text(technique.howToUse)
                        .font(.body)
                        .lineSpacing(4)
                }

                // Try It Now button
                tryItButton
            }
            .padding()
        }
        .navigationTitle(technique.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionCard(title: String, icon: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var tryItButton: some View {
        switch technique.studyModeType {
        case .spacedRepetition:
            NavigationLink(destination: FlashcardDeckView()) {
                tryItLabel("Try Spaced Repetition Flashcards")
            }
        case .activeRecall:
            NavigationLink(destination: QuizSetupView()) {
                tryItLabel("Take a Practice Quiz")
            }
        case .interleaving:
            NavigationLink(destination: QuizSetupView()) {
                tryItLabel("Try Mixed-Topic Quiz")
            }
        case .chunking:
            NavigationLink(destination: InteractiveLearningListView()) {
                tryItLabel("Try Chunked Interactive Learning")
            }
        case .metacognition:
            NavigationLink(destination: WeakSpotsView()) {
                tryItLabel("Check Your Weak Spots")
            }
        case .feynman:
            NavigationLink(destination: FeynmanPracticeView()) {
                tryItLabel("Practice Explaining")
            }
        case .elaboration:
            NavigationLink(destination: ElaborationPracticeView()) {
                tryItLabel("Practice 'Why?' Questions")
            }
        default:
            EmptyView()
        }
    }

    private func tryItLabel(_ text: String) -> some View {
        HStack {
            Image(systemName: "play.fill")
            Text(text)
        }
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .padding()
        .background(technique.color, in: RoundedRectangle(cornerRadius: 14))
        .foregroundStyle(.white)
    }
}

// MARK: - Smart Study Mode

struct SmartStudyView: View {
    @Environment(ContentService.self) private var content
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PerformanceRecord.date, order: .reverse) private var records: [PerformanceRecord]
    @Query(sort: \FlashcardProgress.nextReviewDate) private var flashcardProgress: [FlashcardProgress]
    @AppStorage("userName") private var userName = ""

    @State private var currentPhase = 0
    @State private var sessionActive = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !sessionActive {
                    sessionSetup
                } else {
                    activeSession
                }
            }
            .padding()
        }
        .navigationTitle("Smart Study")
    }

    private var sessionSetup: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)

            Text(userName.isEmpty ? "Smart Study Session" : "\(userName)'s Smart Study Session")
                .font(.title2)
                .fontWeight(.bold)

            Text("This session combines multiple evidence-based techniques into one optimized study flow:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                phaseRow(number: 1, title: "Spaced Review", description: "Review flashcards due today", icon: "clock.arrow.2.circlepath", color: .blue)
                phaseRow(number: 2, title: "Weak Spot Focus", description: "Quiz on your lowest-scoring topics", icon: "exclamationmark.triangle.fill", color: .red)
                phaseRow(number: 3, title: "Interleaved Practice", description: "Mixed questions across chapters", icon: "arrow.triangle.swap", color: .purple)
                phaseRow(number: 4, title: "Self-Assessment", description: "Rate your confidence and compare to reality", icon: "brain.fill", color: .pink)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

            Button {
                sessionActive = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Session")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
            }
        }
    }

    private func phaseRow(number: Int, title: String, description: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activeSession: some View {
        VStack(spacing: 20) {
            // Phase indicator
            HStack(spacing: 4) {
                ForEach(0..<4) { phase in
                    Capsule()
                        .fill(phase <= currentPhase ? Color.blue : Color.gray.opacity(0.2))
                        .frame(height: 4)
                }
            }

            switch currentPhase {
            case 0:
                // Phase 1: Spaced Review
                VStack(spacing: 16) {
                    Label("Phase 1: Spaced Review", systemImage: "clock.arrow.2.circlepath")
                        .font(.headline)
                        .foregroundStyle(.blue)

                    let dueCount = flashcardProgress.filter { $0.nextReviewDate <= Date() }.count
                    if dueCount > 0 {
                        Text("You have \(dueCount) flashcards due for review")
                            .font(.subheadline)
                        NavigationLink(destination: FlashcardStudyView(chapterID: nil)) {
                            actionButton("Review Flashcards", color: .blue)
                        }
                    } else {
                        Text("No flashcards due right now!")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }

                    Button { currentPhase = 1 } label: {
                        Text("Next Phase →")
                            .font(.subheadline)
                    }
                }

            case 1:
                // Phase 2: Weak Spot Focus
                VStack(spacing: 16) {
                    Label("Phase 2: Weak Spot Focus", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)

                    let weakChapters = findWeakChapters()
                    if weakChapters.isEmpty {
                        Text("No weak spots detected yet — take some quizzes first!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Focus quiz on your weakest areas:")
                            .font(.subheadline)
                        ForEach(weakChapters, id: \.0) { chID, accuracy in
                            HStack {
                                Text(content.chapter(id: chID)?.title ?? chID)
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(accuracy * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(accuracy < 0.6 ? .red : .orange)
                            }
                        }
                        let questions = QuizGeneratorService().generateAdaptiveQuiz(
                            performanceRecords: records,
                            allQuestions: content.allQuestions,
                            count: 10
                        )
                        NavigationLink(destination: QuizView(questions: questions, chapterTitle: "Weak Spot Quiz")) {
                            actionButton("Take Weak Spot Quiz", color: .red)
                        }
                    }

                    Button { currentPhase = 2 } label: {
                        Text("Next Phase →")
                            .font(.subheadline)
                    }
                }

            case 2:
                // Phase 3: Interleaved Practice
                VStack(spacing: 16) {
                    Label("Phase 3: Interleaved Practice", systemImage: "arrow.triangle.swap")
                        .font(.headline)
                        .foregroundStyle(.purple)

                    Text("Mixed questions from across all chapters — this builds your ability to discriminate between concepts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    let mixed = Array(content.allQuestions.shuffled().prefix(15))
                    NavigationLink(destination: QuizView(questions: mixed, chapterTitle: "Interleaved Practice")) {
                        actionButton("Start Mixed Quiz (15 questions)", color: .purple)
                    }

                    Button { currentPhase = 3 } label: {
                        Text("Next Phase →")
                            .font(.subheadline)
                    }
                }

            case 3:
                // Phase 4: Self-Assessment
                VStack(spacing: 16) {
                    Label("Phase 4: Self-Assessment", systemImage: "brain.fill")
                        .font(.headline)
                        .foregroundStyle(.pink)

                    Text("How well do you know each chapter? Rate your confidence, then check your Weak Spots to see if your perception matches reality.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    NavigationLink(destination: WeakSpotsView()) {
                        actionButton("View Weak Spots Dashboard", color: .pink)
                    }

                    Text("Session Complete!")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .padding(.top, 8)

                    Button {
                        sessionActive = false
                        currentPhase = 0
                    } label: {
                        Text("Done")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }

            default:
                EmptyView()
            }
        }
    }

    private func actionButton(_ text: String, color: Color) -> some View {
        Text(text)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
    }

    private func findWeakChapters() -> [(String, Double)] {
        let grouped = Dictionary(grouping: records, by: \.chapterID)
        return grouped.compactMap { chapterID, recs in
            guard recs.count >= 3 else { return nil }
            let accuracy = Double(recs.filter(\.wasCorrect).count) / Double(recs.count)
            guard accuracy < 0.75 else { return nil }
            return (chapterID, accuracy)
        }
        .sorted { $0.1 < $1.1 }
        .prefix(3)
        .map { $0 }
    }
}

// MARK: - Feynman Practice View

struct FeynmanPracticeView: View {
    @Environment(ContentService.self) private var content
    @State private var selectedChapter: Chapter?
    @State private var selectedSection: ChapterSection?
    @State private var explanation = ""
    @State private var showModelAnswer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("The Feynman Technique", systemImage: "text.bubble.fill")
                        .font(.headline)
                    Text("Pick a topic, then explain it in simple language as if teaching someone who knows nothing about biology. When you get stuck, that's where you need to study more.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if selectedSection == nil {
                    // Topic picker
                    ForEach(content.chapters) { chapter in
                        DisclosureGroup("Ch. \(chapter.number): \(chapter.title)") {
                            ForEach(chapter.sections) { section in
                                Button {
                                    selectedChapter = chapter
                                    selectedSection = section
                                } label: {
                                    Text(section.title)
                                        .font(.caption)
                                        .padding(.vertical, 4)
                                }
                                .tint(.primary)
                            }
                        }
                        .font(.subheadline)
                    }
                } else if let section = selectedSection {
                    // Explain it
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Explain: \(section.title)")
                            .font(.headline)

                        Text("Write your explanation in simple, everyday language:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $explanation)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        Button {
                            showModelAnswer = true
                        } label: {
                            Text("Compare with Chapter Review")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        if showModelAnswer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Chapter Review says:")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(section.chapterReviewText)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                        }

                        Button("Try Another Topic") {
                            selectedSection = nil
                            selectedChapter = nil
                            explanation = ""
                            showModelAnswer = false
                        }
                        .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Explain It Simply")
    }
}

// MARK: - Elaboration Practice View

struct ElaborationPracticeView: View {
    @Environment(ContentService.self) private var content
    @State private var currentTermIndex = 0
    @State private var userExplanation = ""
    @State private var showAnswer = false
    @State private var terms: [GlossaryTerm] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Why? & How?", systemImage: "questionmark.bubble.fill")
                    .font(.headline)

                if terms.isEmpty {
                    Text("Loading terms...")
                        .onAppear {
                            terms = Array(content.glossaryTerms.shuffled().prefix(10))
                        }
                } else if currentTermIndex >= terms.count {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green)
                        Text("Great practice!")
                            .font(.title3)
                            .fontWeight(.bold)
                        Button("Start Over") {
                            currentTermIndex = 0
                            terms = Array(content.glossaryTerms.shuffled().prefix(10))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    let term = terms[currentTermIndex]

                    Text("\(currentTermIndex + 1) of \(terms.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(term.term.capitalized)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(term.definition)
                            .font(.body)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Text("WHY is this important? HOW does it relate to body function?")
                        .font(.subheadline)
                        .foregroundStyle(.orange)

                    TextEditor(text: $userExplanation)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        currentTermIndex += 1
                        userExplanation = ""
                    } label: {
                        Text("Next Term")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Elaboration Practice")
    }
}
