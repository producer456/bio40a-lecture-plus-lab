import Foundation

// MARK: - Lab Prep Content

struct LabPrepData: Codable {
    let instructor: String
    let weeks: [LabWeek]
}

struct LabWeek: Codable, Identifiable {
    var id: Int { week }

    let week: Int
    let topic: String
    let chapters: [String]?
    let isAssessment: Bool
    let isOff: Bool
    let preLabChecklist: [String]
    let keyConcepts: [String]
    let checkInQuestions: [LabCheckInQuestion]
    let labTips: [String]
    let assessmentInfo: LabAssessmentInfo?
}

struct LabCheckInQuestion: Codable, Identifiable {
    var id: String { question }

    let question: String
    let answer: String
}

struct LabAssessmentInfo: Codable {
    let coveredWeeks: String
    let topics: [String]
    let studyTips: [String]
}
