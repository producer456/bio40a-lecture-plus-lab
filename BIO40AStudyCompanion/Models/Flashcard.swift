import Foundation

// MARK: - FlashcardDeck

struct FlashcardDeck: Codable, Identifiable, Hashable {
    var id: String { chapterID }

    let chapterID: String
    let cards: [Flashcard]
}

// MARK: - Flashcard

struct Flashcard: Codable, Identifiable, Hashable {
    let id: String
    let term: String
    let definition: String
    let chapterID: String
    let sectionID: String
}
