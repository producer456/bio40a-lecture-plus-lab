import Foundation

struct SpacedRepetitionEngine {
    struct ReviewResult {
        let ease: Double
        let interval: Int
        let nextReviewDate: Date
        let repetitions: Int
    }

    func processAnswer(progress: FlashcardProgress, grade: Int) -> ReviewResult {
        let q = min(max(grade, 0), 5)
        let g = Double(q)

        var ease = progress.ease
        var interval = progress.interval
        var repetitions = progress.repetitions

        // SM-2 ease factor update
        let newEase = ease + 0.1 - (5.0 - g) * (0.08 + (5.0 - g) * 0.02)
        ease = max(1.3, newEase)

        if q >= 3 {
            switch repetitions {
            case 0: interval = 1
            case 1: interval = 6
            default: interval = Int(Double(interval) * ease)
            }
            repetitions += 1
        } else {
            interval = 1
            repetitions = 0
        }

        let nextReview = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()

        return ReviewResult(ease: ease, interval: interval, nextReviewDate: nextReview, repetitions: repetitions)
    }
}
