import SwiftUI
import SwiftData

// MARK: - Deck Selection

struct FlashcardDeckView: View {
    @Environment(ContentService.self) private var content
    @Query private var flashcardProgress: [FlashcardProgress]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BioHeroBanner(
                    system: .endocrine,
                    title: "Flashcards",
                    subtitle: "Spaced repetition for long-term retention",
                    badge: "FLASHCARDS",
                    height: 160
                )

                // Review Due
                let dueCount = flashcardProgress.filter { $0.nextReviewDate <= Date() }.count
                if dueCount > 0 {
                    NavigationLink(destination: FlashcardStudyView(chapterID: nil)) {
                        BioCard(system: .endocrine) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.badge.exclamationmark.fill")
                                    .font(.title2)
                                    .foregroundStyle(BodySystem.endocrine.accentColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Review Due Cards")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text("\(dueCount) cards ready for review")
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
                    .tint(.primary)
                }

                // By Chapter
                BioSectionHeader(title: "By Chapter", icon: "book.closed.fill", system: .endocrine)

                ForEach(content.flashcardDecks, id: \.chapterID) { deck in
                    NavigationLink(destination: FlashcardStudyView(chapterID: deck.chapterID)) {
                        BioCard(system: .endocrine) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(content.chapter(id: deck.chapterID)?.title ?? deck.chapterID)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text("\(deck.cards.count) cards")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                deckProgressView(for: deck)
                            }
                        }
                    }
                    .tint(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Flashcards")
    }

    private func deckProgressView(for deck: FlashcardDeck) -> some View {
        let studied = flashcardProgress.filter { progress in
            deck.cards.contains { $0.id == progress.cardID }
        }.count
        let total = deck.cards.count
        return CircularProgressView(progress: total > 0 ? Double(studied) / Double(total) : 0)
            .frame(width: 36, height: 36)
    }
}

// MARK: - Study Session

struct FlashcardStudyView: View {
    let chapterID: String?
    @Environment(ContentService.self) private var content
    @Environment(\.modelContext) private var modelContext
    @Query private var allProgress: [FlashcardProgress]
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var cards: [Flashcard] = []
    @State private var sessionComplete = false

    var body: some View {
        VStack {
            if sessionComplete || cards.isEmpty {
                sessionCompleteView
            } else {
                cardView
            }
        }
        .navigationTitle(chapterID != nil ? "Ch. \(content.chapter(id: chapterID!)?.number ?? 0)" : "Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCards() }
    }

    private var cardView: some View {
        VStack(spacing: 20) {
            // Progress
            HStack {
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                BloodFlowProgress(
                    value: Double(currentIndex) / max(1, Double(cards.count)),
                    system: .endocrine
                )
                .frame(width: 120)
            }
            .padding(.horizontal, 16)

            Spacer()

            // Card — clean, minimal background for readability
            let card = cards[currentIndex]
            VStack(spacing: 16) {
                Text(isFlipped ? "Definition" : "Term")
                    .font(.caption)
                    .foregroundStyle(BodySystem.endocrine.accentColor)
                    .textCase(.uppercase)
                    .fontWeight(.semibold)

                Text(isFlipped ? card.definition : card.term)
                    .font(isFlipped ? .body : .title2)
                    .fontWeight(isFlipped ? .regular : .bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("Tap to \(isFlipped ? "see term" : "reveal")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlipped.toggle()
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Rating Buttons (shown when flipped)
            if isFlipped {
                VStack(spacing: 8) {
                    Text("How well did you know this?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ratingButton(grade: 1, label: "Again", color: .red)
                        ratingButton(grade: 3, label: "Hard", color: .orange)
                        ratingButton(grade: 4, label: "Good", color: .green)
                        ratingButton(grade: 5, label: "Easy", color: .blue)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical)
    }

    private func ratingButton(grade: Int, label: String, color: Color) -> some View {
        Button {
            recordAnswer(grade: grade)
            nextCard()
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(color, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Session Complete!")
                .font(.title2)
                .fontWeight(.bold)
            Text(cards.isEmpty ? "No cards to review right now" : "You reviewed \(cards.count) cards")
                .foregroundStyle(.secondary)
            MuscleContractButton("Study Again", icon: "arrow.clockwise", color: BodySystem.endocrine.primaryColor) {
                currentIndex = 0
                sessionComplete = false
                isFlipped = false
                cards.shuffle()
            }
            .padding(.horizontal, 16)
        }
    }

    private func loadCards() {
        currentIndex = 0
        if let chapterID {
            cards = content.flashcardDecks.first { $0.chapterID == chapterID }?.cards ?? []
        } else {
            // Load due cards using spaced repetition
            let dueProgress = allProgress.filter { $0.nextReviewDate <= Date() }
            let dueCardIDs = Set(dueProgress.map(\.cardID))
            cards = content.flashcardDecks
                .flatMap(\.cards)
                .filter { dueCardIDs.contains($0.id) }

            if cards.isEmpty {
                // If no due cards, show all unreviewed cards
                let reviewedIDs = Set(allProgress.map(\.cardID))
                cards = content.flashcardDecks
                    .flatMap(\.cards)
                    .filter { !reviewedIDs.contains($0.id) }
            }
        }
        cards.shuffle()
    }

    private func recordAnswer(grade: Int) {
        let card = cards[currentIndex]
        let existing = allProgress.first { $0.cardID == card.id }

        if let progress = existing {
            let engine = SpacedRepetitionEngine()
            let updated = engine.processAnswer(progress: progress, grade: grade)
            progress.ease = updated.ease
            progress.interval = updated.interval
            progress.nextReviewDate = updated.nextReviewDate
            progress.repetitions = updated.repetitions
        } else {
            let newProgress = FlashcardProgress(cardID: card.id, chapterID: card.chapterID)
            let engine = SpacedRepetitionEngine()
            let updated = engine.processAnswer(progress: newProgress, grade: grade)
            newProgress.ease = updated.ease
            newProgress.interval = updated.interval
            newProgress.nextReviewDate = updated.nextReviewDate
            newProgress.repetitions = updated.repetitions
            modelContext.insert(newProgress)
        }
    }

    private func nextCard() {
        isFlipped = false
        if currentIndex + 1 < cards.count {
            withAnimation {
                currentIndex += 1
            }
        } else {
            sessionComplete = true
        }
    }
}
