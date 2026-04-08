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

    /// Updates the progress using the SM-2 algorithm.
    /// - Parameter quality: User-rated quality of recall (0-5).
    func applyReview(quality: Int) {
        let q = max(0, min(5, quality))

        if q >= 3 {
            switch repetitions {
            case 0:
                interval = 1
            case 1:
                interval = 6
            default:
                interval = Int(round(Double(interval) * ease))
            }
            repetitions += 1
        } else {
            repetitions = 0
            interval = 1
        }

        // Update ease factor (minimum 1.3)
        let ef = ease + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        ease = max(1.3, ef)

        nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: .now) ?? .now
    }
}
