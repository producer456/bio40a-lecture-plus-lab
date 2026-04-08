import Foundation
import SwiftData

/// Tracks SM-2 spaced repetition progress for each flashcard.
@Model
final class FlashcardProgress {
    @Attribute(.unique) var cardID: String
    var ease: Double
    var interval: Int
    var nextReviewDate: Date
    var repetitions: Int
    var chapterID: String

    /// Creates a new FlashcardProgress with SM-2 defaults.
    /// - Parameters:
    ///   - cardID: Unique identifier matching the Flashcard's id.
    ///   - chapterID: The chapter this card belongs to.
    init(cardID: String, chapterID: String) {
        self.cardID = cardID
        self.ease = 2.5
        self.interval = 0
        self.nextReviewDate = .now
        self.repetitions = 0
        self.chapterID = chapterID
    }

}
