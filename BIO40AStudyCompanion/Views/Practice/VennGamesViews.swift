import SwiftUI
import SwiftData

// MARK: - Venn Games Menu

struct VennGamesMenuView: View {
    @Environment(ContentService.self) private var content

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Venn Diagram Games", systemImage: "circle.grid.cross.fill")
                        .font(.headline)
                    Text("Test your knowledge of how concepts relate. All games pull from your comparison diagrams and update automatically as new content is added.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Choose a Game") {
                NavigationLink(destination: SortTheTraitsView()) {
                    gameRow(icon: "arrow.up.arrow.down.square.fill", title: "Sort the Traits", subtitle: "Place jumbled traits into the correct Venn zones", color: .blue)
                }
                NavigationLink(destination: WhichCircleView()) {
                    gameRow(icon: "questionmark.circle.fill", title: "Which Circle?", subtitle: "Quick-fire: tap where each trait belongs", color: .orange)
                }
                NavigationLink(destination: FillTheVennView()) {
                    gameRow(icon: "circle.grid.cross.fill", title: "Fill the Venn", subtitle: "Build a Venn diagram from scratch", color: .purple)
                }
            }
        }
        .navigationTitle("Venn Games")
    }

    private func gameRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Trait Zone (supports any number of terms)

enum TraitZone: Hashable {
    case term(Int)
    case shared

    func label(for table: ComparisonTable) -> String {
        switch self {
        case .term(let i):
            return i < table.terms.count ? table.terms[i] : "Unknown"
        case .shared:
            return "Shared"
        }
    }

    func color(termCount: Int) -> Color {
        switch self {
        case .term(0): return .blue
        case .term(1): return .orange
        case .term(2): return .purple
        case .term(_): return .teal
        case .shared: return .gray
        }
    }
}

// MARK: - Trait Item

struct TraitItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let zone: TraitZone
}

private func buildTraits(from table: ComparisonTable) -> [TraitItem] {
    var items: [TraitItem] = []
    for (termIndex, traits) in table.unique.enumerated() {
        for trait in traits {
            items.append(TraitItem(text: trait, zone: .term(termIndex)))
        }
    }
    for trait in table.shared {
        items.append(TraitItem(text: trait, zone: .shared))
    }
    return items
}

private func allZones(for table: ComparisonTable) -> [TraitZone] {
    var zones: [TraitZone] = []
    for i in 0..<table.terms.count {
        zones.append(.term(i))
    }
    zones.append(.shared)
    return zones
}

// MARK: - Shared: Section lookup

private func findSection(for table: ComparisonTable, in comparisons: [ComparisonSection]) -> ComparisonSection? {
    comparisons.first { $0.tables.contains(where: { $0.id == table.id }) }
}

// MARK: - Shared: Save QuizAttempt

private func saveQuizAttempt(table: ComparisonTable, correct: Int, total: Int, missed: [String], section: ComparisonSection?, modelContext: ModelContext) {
    let attempt = QuizAttempt(
        chapterIDs: [section?.sectionID ?? "unknown"],
        score: correct,
        totalQuestions: total,
        missedQuestionIDs: missed,
        quizType: "vennGame"
    )
    modelContext.insert(attempt)
}

// MARK: - Shared: Comparison Picker

struct VennGamePicker: View {
    @Environment(ContentService.self) private var content
    let title: String
    let description: String
    let icon: String
    let color: Color
    let onSelect: (ComparisonTable) -> Void

    @State private var selectedGroup: String?

    private var chapterGroups: [String] {
        var seen: Set<String> = []
        return content.comparisons.compactMap { s in
            if seen.contains(s.chapterGroup) { return nil }
            seen.insert(s.chapterGroup)
            return s.chapterGroup
        }
    }

    private var tablesForGroup: [ComparisonTable] {
        content.comparisons
            .filter { selectedGroup == nil || $0.chapterGroup == selectedGroup }
            .flatMap(\.tables)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(color)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(chapterGroups, id: \.self) { group in
                            Button {
                                selectedGroup = group
                            } label: {
                                Text(group)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedGroup == group ? color : Color(.tertiarySystemFill),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .foregroundStyle(selectedGroup == group ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(spacing: 8) {
                    ForEach(tablesForGroup) { table in
                        Button { onSelect(table) } label: {
                            HStack {
                                Text(table.pillLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(table.unique.flatMap { $0 }.count + table.shared.count) traits")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(color)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                if !tablesForGroup.isEmpty {
                    Button {
                        if let random = tablesForGroup.randomElement() { onSelect(random) }
                    } label: {
                        HStack {
                            Image(systemName: "shuffle")
                            Text("Random")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            if selectedGroup == nil { selectedGroup = chapterGroups.first }
        }
    }
}

// MARK: - Shared: Game Complete View

struct VennGameCompleteView: View {
    let correct: Int
    let total: Int
    let table: ComparisonTable
    let color: Color
    let onPlayAgain: () -> Void
    let onNewComparison: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                let pct = total > 0 ? Double(correct) / Double(total) : 0
                Image(systemName: pct >= 0.8 ? "star.circle.fill" : pct >= 0.5 ? "hand.thumbsup.circle.fill" : "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(pct >= 0.8 ? .yellow : pct >= 0.5 ? .blue : .orange)

                Text("\(correct)/\(total) Correct")
                    .font(.system(size: 36, weight: .bold))

                Text(table.pillLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(pct >= 0.8 ? "Excellent! You know this well." : pct >= 0.5 ? "Good effort! Review the ones you missed." : "Keep studying — try again!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button { onPlayAgain() } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Play Again")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    }
                    Button { onNewComparison() } label: {
                        Text("Pick New Comparison")
                            .font(.subheadline)
                            .foregroundStyle(color)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Game 1: Sort the Traits

struct SortTheTraitsView: View {
    @Environment(ContentService.self) private var content
    @Environment(\.modelContext) private var modelContext
    @State private var table: ComparisonTable?
    @State private var traits: [TraitItem] = []
    @State private var placed: [UUID: TraitZone] = [:]
    @State private var selectedTrait: UUID?
    @State private var showResults = false
    @State private var showReview = false
    @State private var correct = 0

    var body: some View {
        if let table {
            if showResults {
                VennGameCompleteView(
                    correct: correct,
                    total: traits.count,
                    table: table,
                    color: .blue,
                    onPlayAgain: { startGame(table) },
                    onNewComparison: { self.table = nil; showResults = false }
                )
                .navigationTitle("Sort the Traits")
            } else if showReview {
                reviewView(table)
                    .navigationTitle("Sort the Traits")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                gameView(table)
                    .navigationTitle("Sort the Traits")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            VennGamePicker(
                title: "Sort the Traits",
                description: "All traits are jumbled up. Tap a trait, then tap the zone it belongs to.",
                icon: "arrow.up.arrow.down.square.fill",
                color: .blue,
                onSelect: { startGame($0) }
            )
            .navigationTitle("Sort the Traits")
        }
    }

    private func gameView(_ table: ComparisonTable) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("\(placed.count)/\(traits.count) placed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if placed.count == traits.count {
                        Button("Check Answers") { checkAnswers(table) }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)

                // Drop zones — dynamically sized for term count
                let zones = allZones(for: table)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(zones.count, 3)), spacing: 8) {
                    ForEach(zones, id: \.self) { zone in
                        dropZone(zone, table: table)
                    }
                }
                .padding(.horizontal)

                let unplaced = traits.filter { placed[$0.id] == nil }
                if !unplaced.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap a trait, then tap a zone above")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(unplaced) { trait in
                                Button {
                                    selectedTrait = trait.id
                                } label: {
                                    Text(trait.text)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTrait == trait.id ? Color.blue : Color(.tertiarySystemFill),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(selectedTrait == trait.id ? .white : .primary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func dropZone(_ zone: TraitZone, table: ComparisonTable) -> some View {
        let zoneColor = zone.color(termCount: table.terms.count)
        let placedHere = traits.filter { placed[$0.id] == zone }
        return VStack(spacing: 6) {
            Text(zone.label(for: table))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(zoneColor)

            VStack(spacing: 4) {
                ForEach(placedHere) { trait in
                    Text(trait.text)
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(zoneColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        .onTapGesture { placed.removeValue(forKey: trait.id) }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(8)
        .background(zoneColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(zoneColor.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5])))
        .contentShape(Rectangle())
        .onTapGesture {
            if let id = selectedTrait {
                placed[id] = zone
                selectedTrait = nil
            }
        }
    }

    // Review screen showing correct/incorrect before completion
    private func reviewView(_ table: ComparisonTable) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(correct)/\(traits.count) Correct")
                    .font(.title2)
                    .fontWeight(.bold)

                let zones = allZones(for: table)
                ForEach(zones, id: \.self) { zone in
                    let zoneColor = zone.color(termCount: table.terms.count)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(zone.label(for: table))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(zoneColor)

                        ForEach(traits.filter { $0.zone == zone }) { trait in
                            let userPlaced = placed[trait.id]
                            let isCorrect = userPlaced == trait.zone
                            HStack(spacing: 8) {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(isCorrect ? .green : .red)
                                    .font(.caption)
                                Text(trait.text)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                if !isCorrect, let userPlaced {
                                    Text("(you said: \(userPlaced.label(for: table)))")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                } else if !isCorrect {
                                    Text("(not placed)")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showReview = false
                    showResults = true
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
            .padding()
        }
    }

    private func startGame(_ t: ComparisonTable) {
        table = t
        traits = buildTraits(from: t).shuffled()
        placed = [:]
        selectedTrait = nil
        showResults = false
        showReview = false
        correct = 0
    }

    private func checkAnswers(_ t: ComparisonTable) {
        correct = traits.filter { placed[$0.id] == $0.zone }.count
        var missed: [String] = []
        let section = findSection(for: t, in: content.comparisons)
        for trait in traits {
            let wasCorrect = placed[trait.id] == trait.zone
            if !wasCorrect { missed.append("venn_sort_\(t.id)_\(trait.text.prefix(20))") }
            let record = PerformanceRecord(
                questionID: "venn_sort_\(t.id)_\(trait.text.prefix(20))",
                chapterID: String(section?.sectionID.prefix(5) ?? "unknown"),
                sectionID: section?.sectionID ?? "unknown",
                wasCorrect: wasCorrect,
                quizType: "vennGame"
            )
            modelContext.insert(record)
        }
        saveQuizAttempt(table: t, correct: correct, total: traits.count, missed: missed, section: section, modelContext: modelContext)
        showReview = true
    }
}

// MARK: - Game 2: Which Circle?

struct WhichCircleView: View {
    @Environment(ContentService.self) private var content
    @Environment(\.modelContext) private var modelContext
    @State private var table: ComparisonTable?
    @State private var traits: [TraitItem] = []
    @State private var currentIndex = 0
    @State private var correct = 0
    @State private var missedIDs: [String] = []
    @State private var feedbackText: String?
    @State private var feedbackCorrect: Bool?
    @State private var isProcessing = false
    @State private var gameOver = false

    var body: some View {
        if let table {
            if gameOver {
                VennGameCompleteView(
                    correct: correct,
                    total: traits.count,
                    table: table,
                    color: .orange,
                    onPlayAgain: { startGame(table) },
                    onNewComparison: { self.table = nil; gameOver = false }
                )
                .navigationTitle("Which Circle?")
            } else if currentIndex < traits.count {
                quizView(table)
                    .navigationTitle("Which Circle?")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            VennGamePicker(
                title: "Which Circle?",
                description: "A trait flashes on screen. Tap which term it belongs to — or tap Shared.",
                icon: "questionmark.circle.fill",
                color: .orange,
                onSelect: { startGame($0) }
            )
            .navigationTitle("Which Circle?")
        }
    }

    private func quizView(_ table: ComparisonTable) -> some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(currentIndex), total: Double(traits.count))
                .tint(.orange)
                .padding(.horizontal)

            HStack {
                Text("\(currentIndex + 1)/\(traits.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(correct) correct")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            .padding(.horizontal)

            Spacer()

            Text(traits[currentIndex].text)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

            if let text = feedbackText, let isCorrect = feedbackCorrect {
                HStack {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(text)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isCorrect ? .green : .red)
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Dynamic answer buttons for all zones
            VStack(spacing: 12) {
                ForEach(allZones(for: table), id: \.self) { zone in
                    Button {
                        answer(zone, table: table)
                    } label: {
                        Text(zone.label(for: table))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(zone.color(termCount: table.terms.count), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .disabled(isProcessing)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func answer(_ zone: TraitZone, table: ComparisonTable) {
        guard !isProcessing else { return }
        isProcessing = true

        let trait = traits[currentIndex]
        let isCorrect = zone == trait.zone
        if isCorrect { correct += 1 }

        // Capture feedback text before any index change
        let correctLabel = trait.zone.label(for: table)
        let qID = "venn_which_\(table.id)_\(trait.text.prefix(20))"
        if !isCorrect { missedIDs.append(qID) }

        let section = findSection(for: table, in: content.comparisons)
        let record = PerformanceRecord(
            questionID: qID,
            chapterID: String(section?.sectionID.prefix(5) ?? "unknown"),
            sectionID: section?.sectionID ?? "unknown",
            wasCorrect: isCorrect,
            quizType: "vennGame"
        )
        modelContext.insert(record)

        withAnimation(.easeInOut(duration: 0.3)) {
            feedbackCorrect = isCorrect
            feedbackText = isCorrect ? "Correct!" : "That belongs to: \(correctLabel)"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                feedbackText = nil
                feedbackCorrect = nil
                currentIndex += 1
                isProcessing = false
                if currentIndex >= traits.count {
                    saveQuizAttempt(table: table, correct: correct, total: traits.count, missed: missedIDs, section: section, modelContext: modelContext)
                    gameOver = true
                }
            }
        }
    }

    private func startGame(_ t: ComparisonTable) {
        table = t
        traits = buildTraits(from: t).shuffled()
        currentIndex = 0
        correct = 0
        missedIDs = []
        feedbackText = nil
        feedbackCorrect = nil
        isProcessing = false
        gameOver = false
    }
}

// MARK: - Game 3: Fill the Venn

struct FillTheVennView: View {
    @Environment(ContentService.self) private var content
    @Environment(\.modelContext) private var modelContext
    @State private var table: ComparisonTable?
    @State private var traits: [TraitItem] = []
    @State private var placed: [UUID: TraitZone] = [:]
    @State private var selectedTrait: UUID?
    @State private var showResults = false
    @State private var correct = 0
    @State private var showAnswer = false
    @State private var hasPeeked = false

    var body: some View {
        if let table {
            if showResults {
                VennGameCompleteView(
                    correct: correct,
                    total: traits.count,
                    table: table,
                    color: .purple,
                    onPlayAgain: { startGame(table) },
                    onNewComparison: { self.table = nil; showResults = false }
                )
                .navigationTitle("Fill the Venn")
            } else {
                fillView(table)
                    .navigationTitle("Fill the Venn")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            VennGamePicker(
                title: "Fill the Venn",
                description: "An empty Venn diagram awaits. Tap a trait pill, then tap a zone to place it.",
                icon: "circle.grid.cross.fill",
                color: .purple,
                onSelect: { startGame($0) }
            )
            .navigationTitle("Fill the Venn")
        }
    }

    private func fillView(_ table: ComparisonTable) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Zone buttons instead of overlapping tap areas
                let zones = allZones(for: table)
                HStack(spacing: 8) {
                    ForEach(zones, id: \.self) { zone in
                        zoneButton(zone, table: table)
                    }
                }
                .padding(.horizontal)

                // Venn diagram (display only — no tap zones)
                vennDisplay(table)

                // Action buttons
                HStack(spacing: 12) {
                    if placed.count == traits.count {
                        Button { checkAnswers(table) } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Check")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                        }
                    }
                    Button {
                        showAnswer.toggle()
                        if showAnswer { hasPeeked = true }
                    } label: {
                        HStack {
                            Image(systemName: showAnswer ? "eye.slash" : "eye")
                            Text(showAnswer ? "Hide" : "Peek")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                if hasPeeked && !showAnswer {
                    Text("Score will note that you peeked")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                if showAnswer {
                    answerView(table)
                        .padding(.horizontal)
                }

                // Unplaced trait pills
                let unplaced = traits.filter { placed[$0.id] == nil }
                if !unplaced.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap a trait below, then tap a zone button above")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(unplaced) { trait in
                                Button {
                                    selectedTrait = trait.id
                                } label: {
                                    Text(trait.text)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTrait == trait.id ? Color.purple : Color(.tertiarySystemFill),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(selectedTrait == trait.id ? .white : .primary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func zoneButton(_ zone: TraitZone, table: ComparisonTable) -> some View {
        let zoneColor = zone.color(termCount: table.terms.count)
        let count = traits.filter { placed[$0.id] == zone }.count
        return Button {
            if let id = selectedTrait {
                placed[id] = zone
                selectedTrait = nil
            }
        } label: {
            VStack(spacing: 4) {
                Text(zone.label(for: table))
                    .font(.caption)
                    .fontWeight(.bold)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(zoneColor.opacity(selectedTrait != nil ? 0.2 : 0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(zoneColor.opacity(0.3), lineWidth: 1))
            .foregroundStyle(zoneColor)
        }
        .disabled(selectedTrait == nil)
    }

    private func vennDisplay(_ table: ComparisonTable) -> some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width * 0.50, 240.0)
            let overlap = diameter * 0.35
            let totalWidth = diameter * 2 - overlap
            let startX = (geo.size.width - totalWidth) / 2

            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                    .frame(width: diameter, height: diameter)
                    .position(x: startX + diameter / 2, y: diameter / 2)

                Circle()
                    .fill(Color.orange.opacity(0.08))
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                    .frame(width: diameter, height: diameter)
                    .position(x: startX + totalWidth - diameter / 2, y: diameter / 2)

                // Left placed items
                VStack(spacing: 2) {
                    ForEach(traits.filter { placed[$0.id] == .term(0) }) { t in
                        Text(t.text).font(.system(size: 9)).foregroundStyle(.blue)
                            .onTapGesture { placed.removeValue(forKey: t.id) }
                    }
                }
                .frame(width: diameter - overlap - 10)
                .position(x: startX + (diameter - overlap) / 2, y: diameter / 2)

                // Shared placed items
                VStack(spacing: 2) {
                    ForEach(traits.filter { placed[$0.id] == .shared }) { t in
                        Text(t.text).font(.system(size: 9)).foregroundStyle(.secondary)
                            .onTapGesture { placed.removeValue(forKey: t.id) }
                    }
                }
                .frame(width: overlap - 10)
                .position(x: startX + diameter - overlap / 2, y: diameter / 2)

                // Right placed items
                VStack(spacing: 2) {
                    ForEach(traits.filter { placed[$0.id] == .term(1) }) { t in
                        Text(t.text).font(.system(size: 9)).foregroundStyle(.orange)
                            .onTapGesture { placed.removeValue(forKey: t.id) }
                    }
                }
                .frame(width: diameter - overlap - 10)
                .position(x: startX + totalWidth - (diameter - overlap) / 2, y: diameter / 2)

                // Labels
                Text(table.terms[0]).font(.caption).fontWeight(.bold).foregroundStyle(.blue)
                    .position(x: startX + (diameter - overlap) / 2, y: -8)
                Text("Shared").font(.caption2).foregroundStyle(.secondary)
                    .position(x: startX + diameter - overlap / 2, y: -8)
                if table.terms.count > 1 {
                    Text(table.terms[1]).font(.caption).fontWeight(.bold).foregroundStyle(.orange)
                        .position(x: startX + totalWidth - (diameter - overlap) / 2, y: -8)
                }
            }
        }
        .frame(height: min(UIScreen.main.bounds.width * 0.50, 240) + 10)
        .padding(.top, 16)
    }

    private func answerView(_ table: ComparisonTable) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(table.terms[0]).font(.caption).fontWeight(.bold).foregroundStyle(.blue)
                ForEach(table.unique[0], id: \.self) { t in
                    Text("• \(t)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Shared").font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                ForEach(table.shared, id: \.self) { t in
                    Text("• \(t)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            if table.terms.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(table.terms[1]).font(.caption).fontWeight(.bold).foregroundStyle(.orange)
                    ForEach(table.unique[1], id: \.self) { t in
                        Text("• \(t)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func startGame(_ t: ComparisonTable) {
        table = t
        traits = buildTraits(from: t).shuffled()
        placed = [:]
        selectedTrait = nil
        showResults = false
        showAnswer = false
        hasPeeked = false
        correct = 0
    }

    private func checkAnswers(_ t: ComparisonTable) {
        correct = traits.filter { placed[$0.id] == $0.zone }.count
        var missed: [String] = []
        let section = findSection(for: t, in: content.comparisons)
        for trait in traits {
            let wasCorrect = placed[trait.id] == trait.zone
            let qID = "venn_fill_\(t.id)_\(trait.text.prefix(20))"
            if !wasCorrect { missed.append(qID) }
            let record = PerformanceRecord(
                questionID: qID,
                chapterID: String(section?.sectionID.prefix(5) ?? "unknown"),
                sectionID: section?.sectionID ?? "unknown",
                wasCorrect: wasCorrect,
                quizType: hasPeeked ? "vennGamePeeked" : "vennGame"
            )
            modelContext.insert(record)
        }
        saveQuizAttempt(table: t, correct: correct, total: traits.count, missed: missed, section: section, modelContext: modelContext)
        showResults = true
    }
}
