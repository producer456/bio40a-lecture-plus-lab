import Foundation

struct QuizGeneratorService {

    /// Generates a randomized quiz from the given chapters.
    /// When `focusWeakSpots` is true, questions from chapters with lower accuracy are weighted more heavily.
    func generateQuiz(
        chapters: [String],
        questionCount: Int,
        allQuestions: [QuizQuestion],
        focusWeakSpots: Bool,
        performanceRecords: [PerformanceRecord]
    ) -> [QuizQuestion] {
        let eligible = allQuestions.filter { chapters.contains($0.chapterID ?? "") }
        guard !eligible.isEmpty else { return [] }

        if focusWeakSpots {
            return weightedSelection(
                from: eligible,
                count: questionCount,
                performanceRecords: performanceRecords
            )
        } else {
            return Array(eligible.shuffled().prefix(questionCount))
        }
    }

    /// Generates a quiz composed entirely of questions from the student's weakest areas.
    func generateAdaptiveQuiz(
        performanceRecords: [PerformanceRecord],
        allQuestions: [QuizQuestion],
        count: Int
    ) -> [QuizQuestion] {
        let chapterAccuracies = computeAccuracyByChapter(records: performanceRecords)

        // Sort chapters by accuracy ascending (weakest first)
        let weakChapters = chapterAccuracies
            .sorted { $0.value < $1.value }
            .map(\.key)

        guard !weakChapters.isEmpty else {
            return Array(allQuestions.shuffled().prefix(count))
        }

        // Gather questions from weakest chapters first
        var selected: [QuizQuestion] = []
        for chapterID in weakChapters {
            let chapterQuestions = allQuestions
                .filter { $0.chapterID == chapterID }
                .shuffled()
            selected.append(contentsOf: chapterQuestions)
            if selected.count >= count { break }
        }

        return Array(selected.prefix(count))
    }

    // MARK: - Private Helpers

    private func weightedSelection(
        from questions: [QuizQuestion],
        count: Int,
        performanceRecords: [PerformanceRecord]
    ) -> [QuizQuestion] {
        let accuracies = computeAccuracyByChapter(records: performanceRecords)

        // Assign weights: lower accuracy = higher weight
        // Chapters with no records get a neutral weight of 1.0
        let weighted: [(question: QuizQuestion, weight: Double)] = questions.map { q in
            let accuracy = accuracies[q.chapterID ?? ""] ?? 0.5
            // Invert accuracy so weaker chapters get higher weight
            // Accuracy 0.0 -> weight 2.0, accuracy 1.0 -> weight 0.5
            let weight = max(0.1, 2.0 - accuracy * 1.5)
            return (q, weight)
        }

        // Weighted random sampling without replacement
        var pool = weighted
        var selected: [QuizQuestion] = []

        while selected.count < count && !pool.isEmpty {
            let totalWeight = pool.reduce(0.0) { $0 + $1.weight }
            var random = Double.random(in: 0..<totalWeight)

            for (index, item) in pool.enumerated() {
                random -= item.weight
                if random <= 0 {
                    selected.append(item.question)
                    pool.remove(at: index)
                    break
                }
            }
        }

        return selected
    }

    private func computeAccuracyByChapter(records: [PerformanceRecord]) -> [String: Double] {
        var grouped: [String: (correct: Int, total: Int)] = [:]
        for record in records {
            let current = grouped[record.chapterID, default: (0, 0)]
            grouped[record.chapterID] = (
                correct: current.correct + (record.wasCorrect ? 1 : 0),
                total: current.total + 1
            )
        }
        return grouped.mapValues { $0.total > 0 ? Double($0.correct) / Double($0.total) : 0 }
    }
}
