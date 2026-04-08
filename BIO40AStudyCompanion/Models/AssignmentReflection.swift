import Foundation
import SwiftData

/// Logs a student's reflection on a real class assignment — what it covered,
/// how they did, and what they struggled with. This feeds into the weak spot
/// analysis so study recommendations are based on real class performance.
@Model
final class AssignmentReflection {
    @Attribute(.unique) var id: UUID
    var assignmentCode: String       // e.g. "Q1", "MT2", "H5", "PreLab3"
    var assignmentName: String       // e.g. "Quiz 1", "Midterm 2"
    var assignmentType: String       // matches AssignmentType rawValue
    var date: Date
    var pointsEarned: Double?        // optional — user may not know yet
    var pointsPossible: Double?
    var topicsCovered: [String]      // section IDs that appeared on assignment
    var topicsStruggled: [String]    // section IDs user found difficult
    var instructorEmphasis: [String] // section IDs instructor emphasized
    var notes: String                // free-text reflection
    var week: Int                    // which syllabus week

    init(
        id: UUID = UUID(),
        assignmentCode: String,
        assignmentName: String,
        assignmentType: String,
        date: Date = .now,
        pointsEarned: Double? = nil,
        pointsPossible: Double? = nil,
        topicsCovered: [String] = [],
        topicsStruggled: [String] = [],
        instructorEmphasis: [String] = [],
        notes: String = "",
        week: Int = 0
    ) {
        self.id = id
        self.assignmentCode = assignmentCode
        self.assignmentName = assignmentName
        self.assignmentType = assignmentType
        self.date = date
        self.pointsEarned = pointsEarned
        self.pointsPossible = pointsPossible
        self.topicsCovered = topicsCovered
        self.topicsStruggled = topicsStruggled
        self.instructorEmphasis = instructorEmphasis
        self.notes = notes
        self.week = week
    }

    var scorePercentage: Double? {
        guard let earned = pointsEarned, let possible = pointsPossible, possible > 0 else { return nil }
        return earned / possible
    }
}
