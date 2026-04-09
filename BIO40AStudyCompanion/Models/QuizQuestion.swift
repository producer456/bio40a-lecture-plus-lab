import Foundation

struct QuizQuestion: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    let question: String
    let choices: [String]
    let correctAnswer: Int
    let explanation: String?
    var chapterID: String?
    var sectionID: String?
}
