import Foundation
import SwiftUI

// MARK: - Analysis Types

enum StrengthLevel: String, Codable, Sendable {
    case strong
    case moderate
    case weak
}

enum PerformanceTrend: String, Codable, Sendable {
    case improving
    case declining
    case stable
}

struct ChapterAnalysis: Identifiable, Sendable {
    var id: String { chapterID }
    let chapterID: String
    let chapterTitle: String
    let accuracy: Double
    let totalAnswered: Int
    let trend: PerformanceTrend
}

struct TopicWeakness: Identifiable, Sendable {
    let id = UUID()
    let chapterID: String
    let sectionID: String
    let sectionTitle: String
    let accuracy: Double
    let sampleSize: Int
}

struct StudyRecommendation: Identifiable, Sendable {
    let id = UUID()
    let message: String
    let chapterID: String?
    let sectionID: String?
    let priority: StudyPriority
}

struct WeakSpotReport: Sendable {
    let overallAccuracy: Double
    let chapterAnalyses: [ChapterAnalysis]
    let weakestTopics: [TopicWeakness]
    let recommendations: [StudyRecommendation]
}

// MARK: - Weak Spot Analyzer
// NOTE: This class is currently unused. WeakSpotsView contains inline analysis logic.
// Available for future refactoring to centralize weak-spot analysis.

@Observable
final class WeakSpotAnalyzer {

    func analyzePerformance(records: [PerformanceRecord], chapters: [Chapter]) -> WeakSpotReport {
        guard !records.isEmpty else {
            return WeakSpotReport(
                overallAccuracy: 0,
                chapterAnalyses: [],
                weakestTopics: [],
                recommendations: [
                    StudyRecommendation(
                        message: "Start taking quizzes to track your progress!",
                        chapterID: nil,
                        sectionID: nil,
                        priority: .high
                    )
                ]
            )
        }

        let overallAccuracy = computeOverallAccuracy(records: records)
        let chapterAnalyses = buildChapterAnalyses(records: records, chapters: chapters)
        let weakestTopics = buildTopicWeaknesses(records: records, chapters: chapters)
        let recommendations = generateRecommendations(
            chapterAnalyses: chapterAnalyses,
            weakestTopics: weakestTopics,
            overallAccuracy: overallAccuracy
        )

        return WeakSpotReport(
            overallAccuracy: overallAccuracy,
            chapterAnalyses: chapterAnalyses,
            weakestTopics: weakestTopics,
            recommendations: recommendations
        )
    }

    func strengthLevel(accuracy: Double) -> StrengthLevel {
        if accuracy > 0.8 {
            return .strong
        } else if accuracy >= 0.6 {
            return .moderate
        } else {
            return .weak
        }
    }

    func colorForStrength(_ level: StrengthLevel) -> Color {
        switch level {
        case .strong: return .green
        case .moderate: return .yellow
        case .weak: return .red
        }
    }

    // MARK: - Private Helpers

    private func computeOverallAccuracy(records: [PerformanceRecord]) -> Double {
        let correct = records.filter(\.wasCorrect).count
        return Double(correct) / Double(records.count)
    }

    private func buildChapterAnalyses(records: [PerformanceRecord], chapters: [Chapter]) -> [ChapterAnalysis] {
        // Group records by chapter
        let grouped = Dictionary(grouping: records, by: \.chapterID)

        return grouped.compactMap { chapterID, chapterRecords in
            let chapterTitle = chapters.first(where: { $0.id == chapterID })?.title ?? chapterID
            let correct = chapterRecords.filter(\.wasCorrect).count
            let accuracy = Double(correct) / Double(chapterRecords.count)
            let trend = computeTrend(records: chapterRecords)

            return ChapterAnalysis(
                chapterID: chapterID,
                chapterTitle: chapterTitle,
                accuracy: accuracy,
                totalAnswered: chapterRecords.count,
                trend: trend
            )
        }
        .sorted { $0.accuracy < $1.accuracy } // Weakest first
    }

    private func buildTopicWeaknesses(records: [PerformanceRecord], chapters: [Chapter]) -> [TopicWeakness] {
        // Group records by (chapterID, sectionID)
        var sectionGroups: [String: [PerformanceRecord]] = [:]
        for record in records {
            let key = "\(record.chapterID)|\(record.sectionID)"
            sectionGroups[key, default: []].append(record)
        }

        let weaknesses: [TopicWeakness] = sectionGroups.compactMap { key, sectionRecords in
            let parts = key.split(separator: "|")
            guard parts.count == 2 else { return nil }
            let chapterID = String(parts[0])
            let sectionID = String(parts[1])

            let correct = sectionRecords.filter(\.wasCorrect).count
            let accuracy = Double(correct) / Double(sectionRecords.count)

            // Only include weak topics
            guard accuracy < 0.7 else { return nil }

            let sectionTitle = chapters
                .first(where: { $0.id == chapterID })?
                .sections.first(where: { $0.id == sectionID })?
                .title ?? sectionID

            return TopicWeakness(
                chapterID: chapterID,
                sectionID: sectionID,
                sectionTitle: sectionTitle,
                accuracy: accuracy,
                sampleSize: sectionRecords.count
            )
        }

        return weaknesses.sorted { $0.accuracy < $1.accuracy }
    }

    private func computeTrend(records: [PerformanceRecord]) -> PerformanceTrend {
        guard records.count >= 4 else { return .stable }

        // Sort by date, compare first half vs second half accuracy
        let sorted = records.sorted { $0.date < $1.date }
        let midpoint = sorted.count / 2
        let firstHalf = Array(sorted.prefix(midpoint))
        let secondHalf = Array(sorted.suffix(from: midpoint))

        let firstAccuracy = Double(firstHalf.filter(\.wasCorrect).count) / Double(firstHalf.count)
        let secondAccuracy = Double(secondHalf.filter(\.wasCorrect).count) / Double(secondHalf.count)

        let delta = secondAccuracy - firstAccuracy
        if delta > 0.1 {
            return .improving
        } else if delta < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    private func generateRecommendations(
        chapterAnalyses: [ChapterAnalysis],
        weakestTopics: [TopicWeakness],
        overallAccuracy: Double
    ) -> [StudyRecommendation] {
        var recommendations: [StudyRecommendation] = []

        // Recommend review for weak chapters
        for analysis in chapterAnalyses where strengthLevel(accuracy: analysis.accuracy) == .weak {
            recommendations.append(StudyRecommendation(
                message: "Review \(analysis.chapterTitle) - your accuracy is \(Int(analysis.accuracy * 100))%.",
                chapterID: analysis.chapterID,
                sectionID: nil,
                priority: .high
            ))
        }

        // Recommend focus on weakest specific topics
        for topic in weakestTopics.prefix(5) {
            recommendations.append(StudyRecommendation(
                message: "Focus on \"\(topic.sectionTitle)\" - accuracy is \(Int(topic.accuracy * 100))% across \(topic.sampleSize) questions.",
                chapterID: topic.chapterID,
                sectionID: topic.sectionID,
                priority: topic.accuracy < 0.4 ? .high : .medium
            ))
        }

        // Declining chapters
        for analysis in chapterAnalyses where analysis.trend == .declining {
            recommendations.append(StudyRecommendation(
                message: "\(analysis.chapterTitle) scores are declining. Consider revisiting this material.",
                chapterID: analysis.chapterID,
                sectionID: nil,
                priority: .medium
            ))
        }

        // General encouragement if doing well
        if overallAccuracy > 0.8 && recommendations.isEmpty {
            recommendations.append(StudyRecommendation(
                message: "Great work! Keep reviewing to maintain your strong performance.",
                chapterID: nil,
                sectionID: nil,
                priority: .low
            ))
        }

        return recommendations.sorted { $0.priority < $1.priority }
    }
}
