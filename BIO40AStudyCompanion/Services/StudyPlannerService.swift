import Foundation

// MARK: - Study Plan Types

enum StudyItemType: String, Codable, Sendable {
    case read
    case review
    case quiz
    case flashcards
}

enum StudyPriority: String, Codable, Sendable, Comparable {
    case high
    case medium
    case low

    private var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    static func < (lhs: StudyPriority, rhs: StudyPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

struct StudyPlanItem: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let description: String
    let type: StudyItemType
    let chapterID: String?
    let priority: StudyPriority
    let estimatedMinutes: Int
}

struct StudyPlan: Sendable {
    let currentWeek: Int
    let items: [StudyPlanItem]
}

// MARK: - Study Planner Service

struct StudyPlannerService {

    /// Generates a weekly study plan based on the current syllabus week, study progress, and quiz performance.
    func generateWeeklyPlan(
        currentDate: Date,
        syllabus: SyllabusSchedule,
        progress: [StudyProgress],
        quizAttempts: [QuizAttempt]
    ) -> StudyPlan {
        let currentWeek = determineCurrentWeek(date: currentDate, syllabus: syllabus)
        var items: [StudyPlanItem] = []

        let readChapterIDs = Set(progress.filter { $0.readPercentage >= 1.0 }.map(\.chapterID))
        let chapterAccuracies = computeChapterAccuracies(quizAttempts: quizAttempts)

        // Find current week's entry for context
        let weekEntry = syllabus.lectureSchedule.first { $0.week == currentWeek }

        // 1. Unread chapters for the current and prior weeks get high priority
        let relevantChapters = chaptersUpToWeek(currentWeek, syllabus: syllabus)
        for chapterID in relevantChapters where !readChapterIDs.contains(chapterID) {
            items.append(StudyPlanItem(
                title: "Read Chapter \(chapterID)",
                description: "Complete your first read-through of this chapter.",
                type: .read,
                chapterID: chapterID,
                priority: .high,
                estimatedMinutes: 45
            ))
        }

        // 2. Weak areas from quiz performance
        for (chapterID, accuracy) in chapterAccuracies where accuracy < 0.7 {
            items.append(StudyPlanItem(
                title: "Review Chapter \(chapterID)",
                description: String(format: "Your accuracy is %.0f%%. Review key concepts.", accuracy * 100),
                type: .review,
                chapterID: chapterID,
                priority: accuracy < 0.5 ? .high : .medium,
                estimatedMinutes: 30
            ))
        }

        // 3. Quiz practice for upcoming topics
        if let entry = weekEntry, let assignments = entry.assignments {
            for assignment in assignments {
                items.append(StudyPlanItem(
                    title: "Practice Quiz: \(assignment.name)",
                    description: "Take a practice quiz to prepare for this assignment.",
                    type: .quiz,
                    chapterID: nil,
                    priority: .medium,
                    estimatedMinutes: 20
                ))
            }
        }

        // 4. Flashcard review (daily habit)
        items.append(StudyPlanItem(
            title: "Daily Flashcard Review",
            description: "Review due flashcards to reinforce key terms.",
            type: .flashcards,
            chapterID: nil,
            priority: .medium,
            estimatedMinutes: 15
        ))

        // 5. General review for read-but-not-recently-quizzed chapters
        let quizzedChapters = Set(chapterAccuracies.keys)
        for chapterID in readChapterIDs where !quizzedChapters.contains(chapterID) {
            items.append(StudyPlanItem(
                title: "Quiz Yourself: Chapter \(chapterID)",
                description: "You've read this chapter but haven't been quizzed on it yet.",
                type: .quiz,
                chapterID: chapterID,
                priority: .low,
                estimatedMinutes: 15
            ))
        }

        // Sort by priority
        let sorted = items.sorted { $0.priority < $1.priority }

        return StudyPlan(currentWeek: currentWeek, items: sorted)
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func determineCurrentWeek(date: Date, syllabus: SyllabusSchedule) -> Int {
        // Find the week whose start date is closest without exceeding the current date
        let schedule = syllabus.lectureSchedule
        var currentWeek = 1
        for week in schedule {
            if let weekStart = Self.dateFormatter.date(from: week.startDate), date >= weekStart {
                currentWeek = week.week
            }
        }
        return currentWeek
    }

    private func chaptersUpToWeek(_ week: Int, syllabus: SyllabusSchedule) -> [String] {
        syllabus.lectureSchedule
            .filter { $0.week <= week }
            .flatMap { $0.chapters ?? [] }
    }

    private func computeChapterAccuracies(quizAttempts: [QuizAttempt]) -> [String: Double] {
        var totals: [String: (correct: Int, total: Int)] = [:]
        for attempt in quizAttempts {
            // Distribute score evenly across all chapters in the attempt
            let chapterCount = max(attempt.chapterIDs.count, 1)
            let perChapterScore = attempt.score / chapterCount
            let perChapterTotal = attempt.totalQuestions / chapterCount
            for chapterID in attempt.chapterIDs {
                let current = totals[chapterID, default: (0, 0)]
                totals[chapterID] = (
                    correct: current.correct + perChapterScore,
                    total: current.total + perChapterTotal
                )
            }
        }
        return totals.mapValues { $0.total > 0 ? Double($0.correct) / Double($0.total) : 0 }
    }
}
