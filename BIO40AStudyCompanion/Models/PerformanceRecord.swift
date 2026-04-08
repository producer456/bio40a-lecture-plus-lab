import Foundation
import SwiftData

/// Tracks every individual quiz answer for weak-spot analysis per chapter/section.
@Model
final class PerformanceRecord {
    @Attribute(.unique) var id: UUID
    var questionID: String
    var chapterID: String
    var sectionID: String
    var wasCorrect: Bool
    var date: Date
    var quizType: String

    init(
        id: UUID = UUID(),
        questionID: String,
        chapterID: String,
        sectionID: String,
        wasCorrect: Bool,
        date: Date = .now,
        quizType: String = "practice"
    ) {
        self.id = id
        self.questionID = questionID
        self.chapterID = chapterID
        self.sectionID = sectionID
        self.wasCorrect = wasCorrect
        self.date = date
        self.quizType = quizType
    }
}
