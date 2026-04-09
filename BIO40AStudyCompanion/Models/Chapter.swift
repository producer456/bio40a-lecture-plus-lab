import Foundation

// MARK: - Chapter

struct Chapter: Codable, Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let weekMapping: WeekMapping
    let sections: [ChapterSection]
    let glossaryTerms: [GlossaryTerm]
    let totalQuestions: Int
}

// MARK: - WeekMapping

struct WeekMapping: Codable, Hashable {
    let lectureWeek: Int
    let labWeek: Int
}

// MARK: - ChapterSection

struct ChapterSection: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let objectives: [String]
    let content: [String]
    let chapterReview: [String]
    let reviewQuestions: [QuizQuestion]
    let glossary: [GlossaryTerm]

    var chapterReviewText: String {
        chapterReview.joined(separator: " ")
    }
}
