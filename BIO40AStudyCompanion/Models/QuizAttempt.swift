import Foundation
import SwiftData

@Model
final class QuizAttempt {
    @Attribute(.unique) var id: UUID
    var chapterIDs: [String]
    var date: Date
    var score: Int
    var totalQuestions: Int
    var missedQuestionIDs: [String]
    var quizType: String

    init(
        id: UUID = UUID(),
        chapterIDs: [String],
        date: Date = .now,
        score: Int,
        totalQuestions: Int,
        missedQuestionIDs: [String] = [],
        quizType: String = "practice"
    ) {
        self.id = id
        self.chapterIDs = chapterIDs
        self.date = date
        self.score = score
        self.totalQuestions = totalQuestions
        self.missedQuestionIDs = missedQuestionIDs
        self.quizType = quizType
    }

    /// Percentage score (0-100).
    var scorePercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100.0
    }
}
