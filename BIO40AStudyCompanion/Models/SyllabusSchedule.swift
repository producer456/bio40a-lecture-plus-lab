import Foundation

// MARK: - SyllabusSchedule

struct SyllabusSchedule: Codable, Hashable {
    let lectureSchedule: [WeekEntry]
    let labSchedule: [WeekEntry]
    let grading: GradingBreakdown
    let importantDates: [ImportantDate]
}

// MARK: - WeekEntry

struct WeekEntry: Codable, Identifiable, Hashable {
    var id: Int { week }

    let week: Int
    let startDate: String
    let topic: String
    let chapters: [String]?
    let assignments: [Assignment]?
}

// MARK: - Assignment

struct Assignment: Codable, Identifiable, Hashable {
    var id: String { code }

    let name: String
    let code: String
    let dueDate: String
    let type: AssignmentType
}

// MARK: - AssignmentType

enum AssignmentType: String, Codable, Hashable, CaseIterable {
    case preLecture
    case homework
    case quiz
    case midterm
    case `final` = "final"
    case labReport
    case labAssessment
}

// MARK: - GradingBreakdown

struct GradingBreakdown: Codable, Hashable {
    let lecture: LectureGrading
    let lab: LabGrading
}

struct LectureGrading: Codable, Hashable {
    let lectureActivities: Double
    let preLectureWork: Double
    let homework: Double
    let quizzes: Double
    let midtermsAndFinal: Double
    let totalWeight: Double
}

struct LabGrading: Codable, Hashable {
    let preLabs: Double
    let labActivities: Double
    let labAssessments: Double
    let totalWeight: Double
}

// MARK: - ImportantDate

struct ImportantDate: Codable, Identifiable, Hashable {
    var id: String { "\(date)_\(event)" }

    let date: String
    let event: String
}
