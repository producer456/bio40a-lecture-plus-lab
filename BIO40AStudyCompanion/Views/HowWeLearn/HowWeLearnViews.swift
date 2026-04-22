import SwiftUI
import SwiftData

// MARK: - How We Learn Hub

struct HowWeLearnView: View {
    @Environment(ContentService.self) private var content
    @AppStorage("userName") private var userName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero banner
                BioHeroBanner(
                    system: .muscular,
                    title: "How We Learn",
                    subtitle: "Evidence-based techniques from cognitive psychology",
                    badge: "LEARNING",
                    height: 170
                )

                if !userName.isEmpty {
                    Text("\(userName), using these techniques can help you retain 2-3x more material.")
                        .font(.caption)
                        .foregroundStyle(BodySystem.muscular.primaryColor)
                }

                // Key insight card
                insightCard

                // Technique cards
                BioSectionHeader(title: "Techniques", icon: "brain.head.profile", system: .muscular)

                ForEach(LearningTechnique.all) { technique in
                    NavigationLink(destination: TechniqueDetailView(technique: technique)) {
                        techniqueCard(technique)
                    }
                    .tint(.primary)
                }

                // Smart Study Mode
                BioSectionHeader(title: "Smart Study", icon: "sparkles", system: .muscular)

                NavigationLink(destination: SmartStudyView()) {
                    BioCard(system: .muscular) {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 36))
                                .foregroundStyle(BodySystem.muscular.accentColor)
                            Text("Smart Study Mode")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Combines all techniques into one optimized study session tailored to your weak spots")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("How We Learn")
    }

    private var insightCard: some View {
        BioCard(system: .muscular) {
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
        }
    }

    private func techniqueCard(_ technique: LearningTechnique) -> some View {
        BioCard(system: .muscular) {
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
        }
    }
}

// MARK: - Technique Detail View

struct TechniqueDetailView: View {
    let technique: LearningTechnique
    @Environment(ContentService.self) private var content

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                BioHeroBanner(
                    system: .muscular,
                    title: technique.name,
                    subtitle: technique.tagline,
                    badge: "TECHNIQUE",
                    height: 150
                )

                // What is it?
                sectionCard(title: "What Is It?", icon: "info.circle.fill") {
                    Text(technique.explanation)
                        .font(.body)
                        .lineSpacing(4)
                }

                // The Research
                sectionCard(title: "The Research", icon: "book.closed.fill") {
                    Text(technique.keyResearch)
                        .font(.body)
                        .lineSpacing(4)
                }

                // For A&P Specifically
                sectionCard(title: "For A&P Specifically", icon: "figure.stand") {
                    Text(technique.apApplication)
                        .font(.body)
                        .lineSpacing(4)
                }

                // How to Use in This App
                sectionCard(title: "How to Use It", icon: "iphone") {
                    Text(technique.howToUse)
                        .font(.body)
                        .lineSpacing(4)
                }

                // Try It Now button
                tryItButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle(technique.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionCard(title: String, icon: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        BioCard(system: .muscular) {
            VStack(alignment: .leading, spacing: 10) {
                BioSectionHeader(title: title, icon: icon, system: .muscular)
                content()
            }
        }
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
            VStack(spacing: 20) {
                if !sessionActive {
                    sessionSetup
                } else {
                    activeSession
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Smart Study")
    }

    private var sessionSetup: some View {
        VStack(spacing: 20) {
            BioHeroBanner(
                system: .muscular,
                title: userName.isEmpty ? "Smart Study Session" : "\(userName)'s Smart Study",
                subtitle: "Optimized study flow using evidence-based techniques",
                badge: "SMART STUDY",
                height: 160
            )

            BioCard(system: .muscular) {
                VStack(alignment: .leading, spacing: 12) {
                    phaseRow(number: 1, title: "Spaced Review", description: "Review flashcards due today", icon: "clock.arrow.2.circlepath", color: .blue)
                    phaseRow(number: 2, title: "Weak Spot Focus", description: "Quiz on your lowest-scoring topics", icon: "exclamationmark.triangle.fill", color: .red)
                    phaseRow(number: 3, title: "Interleaved Practice", description: "Mixed questions across chapters", icon: "arrow.triangle.swap", color: .purple)
                    phaseRow(number: 4, title: "Self-Assessment", description: "Rate your confidence and compare to reality", icon: "brain.fill", color: .pink)
                }
            }

            MuscleContractButton("Start Session", icon: "play.fill", color: BodySystem.muscular.primaryColor) {
                sessionActive = true
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
                        .fill(phase <= currentPhase ? BodySystem.muscular.primaryColor : Color.gray.opacity(0.2))
                        .frame(height: 4)
                }
            }

            switch currentPhase {
            case 0:
                // Phase 1: Spaced Review
                BioCard(system: .muscular) {
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
                    .frame(maxWidth: .infinity)
                }

            case 1:
                // Phase 2: Weak Spot Focus
                BioCard(system: .muscular) {
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
                    .frame(maxWidth: .infinity)
                }

            case 2:
                // Phase 3: Interleaved Practice
                BioCard(system: .muscular) {
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
                    .frame(maxWidth: .infinity)
                }

            case 3:
                // Phase 4: Self-Assessment
                BioCard(system: .muscular) {
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

                        MuscleContractButton("Done", icon: "checkmark", color: .green) {
                            sessionActive = false
                            currentPhase = 0
                        }
                    }
                    .frame(maxWidth: .infinity)
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
                BioCard(system: .muscular) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("The Feynman Technique", systemImage: "text.bubble.fill")
                            .font(.headline)
                            .foregroundStyle(BodySystem.muscular.primaryColor)
                        Text("Pick a topic, then explain it in simple language as if teaching someone who knows nothing about biology. When you get stuck, that's where you need to study more.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if selectedSection == nil {
                    // Topic picker
                    BioSectionHeader(title: "Pick a Topic", icon: "list.bullet", system: .muscular)

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
                        BioSectionHeader(title: "Explain: \(section.title)", icon: "pencil.line", system: .muscular)

                        Text("Write your explanation in simple, everyday language:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $explanation)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        MuscleContractButton("Compare with Chapter Review", icon: "eye.fill", color: BodySystem.muscular.primaryColor) {
                            showModelAnswer = true
                        }

                        if showModelAnswer {
                            BioCard(system: .muscular) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Chapter Review says:")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Text(section.chapterReviewText)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                BioSectionHeader(title: "Why? & How?", icon: "questionmark.bubble.fill", system: .muscular)

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
                        MuscleContractButton("Start Over", icon: "arrow.clockwise", color: BodySystem.muscular.primaryColor) {
                            currentTermIndex = 0
                            terms = Array(content.glossaryTerms.shuffled().prefix(10))
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    let term = terms[currentTermIndex]

                    Text("\(currentTermIndex + 1) of \(terms.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    BioCard(system: .muscular) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(term.term.capitalized)
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(term.definition)
                                .font(.body)
                        }
                    }

                    Text("WHY is this important? HOW does it relate to body function?")
                        .font(.subheadline)
                        .foregroundStyle(BodySystem.muscular.primaryColor)

                    TextEditor(text: $userExplanation)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    MuscleContractButton("Next Term", icon: "arrow.right", color: BodySystem.muscular.primaryColor) {
                        currentTermIndex += 1
                        userExplanation = ""
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Elaboration Practice")
    }
}
