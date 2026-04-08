import SwiftUI
import SwiftData
import Charts

struct WeakSpotsView: View {
    @Environment(ContentService.self) private var content
    @Query(sort: \PerformanceRecord.date) private var performanceRecords: [PerformanceRecord]
    @Query(sort: \QuizAttempt.date, order: .reverse) private var quizAttempts: [QuizAttempt]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if performanceRecords.isEmpty {
                    emptyState
                } else {
                    overallAccuracyCard
                    chapterHeatMap
                    weakestTopicsSection
                    recommendationsSection
                    trendSection
                }
            }
            .padding()
        }
        .navigationTitle("Weak Spots")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("No Data Yet")
                .font(.title3)
                .fontWeight(.bold)
            Text("Take some quizzes or practice with flashcards to see your weak spots")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }

    // MARK: - Overall Accuracy

    private var overallAccuracyCard: some View {
        let correct = performanceRecords.filter(\.wasCorrect).count
        let total = performanceRecords.count
        let accuracy = total > 0 ? Double(correct) / Double(total) : 0

        return VStack(spacing: 8) {
            Text("Overall Accuracy")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(Int(accuracy * 100))%")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(colorForAccuracy(accuracy))
            Text("\(correct)/\(total) correct answers")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Chapter Heat Map

    private var chapterHeatMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chapter Strength Map")
                .font(.headline)

            let analyses = chapterAnalyses()
            ForEach(analyses, id: \.chapterID) { analysis in
                HStack {
                    Text("Ch. \(analysis.chapterNumber)")
                        .font(.caption)
                        .frame(width: 40, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.gray.opacity(0.15))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorForAccuracy(analysis.accuracy))
                                .frame(width: geo.size.width * analysis.accuracy)
                        }
                    }
                    .frame(height: 24)
                    Text("\(Int(analysis.accuracy * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weakest Topics

    private var weakestTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weakest Topics")
                .font(.headline)

            let weak = weakTopics()
            if weak.isEmpty {
                Text("Looking good! No major weak spots detected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(weak, id: \.sectionID) { topic in
                    HStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorForAccuracy(topic.accuracy))
                            .frame(width: 4, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(topic.sectionTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(topic.chapterTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(Int(topic.accuracy * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(colorForAccuracy(topic.accuracy))
                            Text("\(topic.sampleSize) answers")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Recommendations")
                .font(.headline)

            let recs = generateRecommendations()
            ForEach(Array(recs.enumerated()), id: \.offset) { _, rec in
                HStack(alignment: .top) {
                    Image(systemName: rec.icon)
                        .foregroundStyle(rec.color)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rec.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(rec.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Trend

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiz Score Trend")
                .font(.headline)

            if quizAttempts.count >= 2 {
                Chart {
                    ForEach(Array(quizAttempts.reversed().enumerated()), id: \.offset) { index, attempt in
                        let pct = Double(attempt.score) / Double(max(attempt.totalQuestions, 1)) * 100
                        LineMark(
                            x: .value("Quiz", index + 1),
                            y: .value("Score %", pct)
                        )
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Quiz", index + 1),
                            y: .value("Score %", pct)
                        )
                    }
                }
                .frame(height: 150)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100])
                }
            } else {
                Text("Take at least 2 quizzes to see your trend")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private struct ChapterAnalysisData {
        let chapterID: String
        let chapterNumber: Int
        let accuracy: Double
        let total: Int
    }

    private func chapterAnalyses() -> [ChapterAnalysisData] {
        let grouped = Dictionary(grouping: performanceRecords, by: \.chapterID)
        return grouped.compactMap { chapterID, records in
            let accuracy = Double(records.filter(\.wasCorrect).count) / Double(records.count)
            let number = content.chapter(id: chapterID)?.number ?? 0
            return ChapterAnalysisData(chapterID: chapterID, chapterNumber: number, accuracy: accuracy, total: records.count)
        }
        .sorted { $0.chapterNumber < $1.chapterNumber }
    }

    private struct WeakTopic {
        let sectionID: String
        let sectionTitle: String
        let chapterTitle: String
        let accuracy: Double
        let sampleSize: Int
    }

    private func weakTopics() -> [WeakTopic] {
        let grouped = Dictionary(grouping: performanceRecords, by: \.sectionID)
        return grouped.compactMap { sectionID, records in
            guard records.count >= 2 else { return nil }
            let accuracy = Double(records.filter(\.wasCorrect).count) / Double(records.count)
            guard accuracy < 0.7 else { return nil }

            let chapterID = records.first?.chapterID ?? ""
            let chapter = content.chapter(id: chapterID)
            let sectionTitle = chapter?.sections.first { $0.id == sectionID }?.title ?? sectionID
            let chapterTitle = chapter?.title ?? chapterID

            return WeakTopic(sectionID: sectionID, sectionTitle: sectionTitle, chapterTitle: chapterTitle, accuracy: accuracy, sampleSize: records.count)
        }
        .sorted { $0.accuracy < $1.accuracy }
        .prefix(5)
        .map { $0 }
    }

    private struct Recommendation {
        let icon: String
        let title: String
        let message: String
        let color: Color
    }

    private func generateRecommendations() -> [Recommendation] {
        var recs: [Recommendation] = []
        let weak = weakTopics()

        if let weakest = weak.first {
            recs.append(Recommendation(
                icon: "exclamationmark.triangle.fill",
                title: "Focus on \(weakest.sectionTitle)",
                message: "Only \(Int(weakest.accuracy * 100))% accuracy — re-read this section and take practice questions",
                color: .red
            ))
        }

        let analyses = chapterAnalyses()
        if let weakChapter = analyses.min(by: { $0.accuracy < $1.accuracy }), weakChapter.accuracy < 0.7 {
            recs.append(Recommendation(
                icon: "book.fill",
                title: "Review Chapter \(weakChapter.chapterNumber)",
                message: "Your weakest chapter at \(Int(weakChapter.accuracy * 100))% — use flashcards for key terms",
                color: .orange
            ))
        }

        if quizAttempts.count < 3 {
            recs.append(Recommendation(
                icon: "checkmark.circle.fill",
                title: "Take More Practice Quizzes",
                message: "More data helps identify your weak spots accurately",
                color: .blue
            ))
        }

        if recs.isEmpty {
            recs.append(Recommendation(
                icon: "star.fill",
                title: "Great Job!",
                message: "Keep up the consistent studying",
                color: .green
            ))
        }

        return recs
    }

    private func colorForAccuracy(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.6 { return .yellow }
        return .red
    }
}
