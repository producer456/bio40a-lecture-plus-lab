import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ContentService.self) private var content
    @Query(sort: \QuizAttempt.date, order: .reverse) private var quizAttempts: [QuizAttempt]
    @Query private var studyProgress: [StudyProgress]
    @Query(sort: \PerformanceRecord.date, order: .reverse) private var performanceRecords: [PerformanceRecord]
    @Query(sort: \FlashcardProgress.nextReviewDate) private var flashcardProgress: [FlashcardProgress]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                upcomingDueDatesSection
                continueStudyingSection
                weeklyOverviewSection
                weakSpotsPreviewSection
                quickActionsSection
            }
            .padding()
        }
        .navigationTitle("BIO 40A")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.title2)
                .fontWeight(.bold)

            if let week = currentWeek {
                Text("Week \(week) \u{2022} \(currentWeekTopic)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var currentWeek: Int? {
        let today = Date()
        return content.syllabus?.lectureSchedule.first { entry in
            guard let start = dateFromString(entry.startDate) else { return false }
            let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
            return today >= start && today < end
        }?.week
    }

    private var currentWeekTopic: String {
        guard let week = currentWeek else { return "" }
        return content.syllabus?.lectureSchedule.first { $0.week == week }?.topic ?? ""
    }

    // MARK: - Upcoming Due Dates

    private var upcomingDueDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upcoming Due Dates", systemImage: "clock.fill")
                .font(.headline)

            let upcoming = upcomingAssignments
            if upcoming.isEmpty {
                Text("No upcoming assignments")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(upcoming.prefix(5), id: \.name) { assignment in
                    HStack {
                        Circle()
                            .fill(colorForType(assignment.type))
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading) {
                            Text(assignment.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let due = ISO8601DateFormatter().date(from: assignment.dueDate.replacingOccurrences(of: "-07:00", with: "-0700").replacingOccurrences(of: "-08:00", with: "-0800")) {
                                Text(due, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(assignment.type.rawValue.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorForType(assignment.type).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var upcomingAssignments: [Assignment] {
        guard let syllabus = content.syllabus else { return [] }
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return syllabus.lectureSchedule
            .flatMap { $0.assignments ?? [] }
            .filter { assignment in
                if let date = parseDueDate(assignment.dueDate) {
                    return date > now
                }
                return false
            }
            .sorted { a, b in
                (parseDueDate(a.dueDate) ?? .distantFuture) < (parseDueDate(b.dueDate) ?? .distantFuture)
            }
    }

    // MARK: - Continue Studying

    private var continueStudyingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Continue Studying", systemImage: "book.fill")
                .font(.headline)

            let chaptersInProgress = studyProgress
                .filter { $0.readPercentage > 0 && $0.readPercentage < 1.0 }
                .prefix(3)

            if chaptersInProgress.isEmpty {
                if let firstChapter = content.chapters.first {
                    NavigationLink(destination: ChapterDetailView(chapter: firstChapter)) {
                        studyCard(title: firstChapter.title, subtitle: "Start reading", progress: 0, chapter: firstChapter)
                    }
                }
            } else {
                ForEach(Array(chaptersInProgress), id: \.chapterID) { progress in
                    if let chapter = content.chapter(id: progress.chapterID) {
                        NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                            studyCard(title: chapter.title, subtitle: "Continue reading", progress: progress.readPercentage, chapter: chapter)
                        }
                    }
                }
            }
        }
    }

    private func studyCard(title: String, subtitle: String, progress: Double, chapter: Chapter) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ch. \(chapter.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            CircularProgressView(progress: progress)
                .frame(width: 44, height: 44)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Overview

    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This Week", systemImage: "calendar")
                .font(.headline)

            HStack(spacing: 16) {
                statCard(title: "Flashcards Due", value: "\(flashcardsDueCount)", icon: "rectangle.on.rectangle.angled", color: .orange)
                statCard(title: "Quiz Avg", value: quizAverage, icon: "checkmark.circle", color: .green)
                statCard(title: "Chapters Read", value: "\(chaptersCompleted)/\(content.chapters.count)", icon: "book.closed", color: .blue)
            }
        }
    }

    private var flashcardsDueCount: Int {
        flashcardProgress.filter { $0.nextReviewDate <= Date() }.count
    }

    private var quizAverage: String {
        let recent = quizAttempts.prefix(5)
        guard !recent.isEmpty else { return "--" }
        let avg = Double(recent.reduce(0) { $0 + $1.score }) / Double(recent.reduce(0) { $0 + $1.totalQuestions })
        return "\(Int(avg * 100))%"
    }

    private var chaptersCompleted: Int {
        Set(studyProgress.filter { $0.readPercentage >= 1.0 }.map { $0.chapterID }).count
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weak Spots Preview

    private var weakSpotsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Weak Spots", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    WeakSpotsView()
                }
                .font(.subheadline)
            }

            let weakChapters = getWeakChapters()
            if weakChapters.isEmpty {
                Text("Take some quizzes to see your weak spots")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(weakChapters.prefix(3), id: \.chapterID) { weak in
                    HStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(weak.accuracy < 0.6 ? .red : .yellow)
                            .frame(width: 4, height: 30)
                        VStack(alignment: .leading) {
                            Text(weak.chapterTitle)
                                .font(.subheadline)
                            Text("\(Int(weak.accuracy * 100))% accuracy")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ProgressView(value: weak.accuracy)
                            .frame(width: 60)
                            .tint(weak.accuracy < 0.6 ? .red : .yellow)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func getWeakChapters() -> [(chapterID: String, chapterTitle: String, accuracy: Double)] {
        let grouped = Dictionary(grouping: performanceRecords, by: \.chapterID)
        return grouped.compactMap { chapterID, records in
            guard records.count >= 3 else { return nil }
            let accuracy = Double(records.filter(\.wasCorrect).count) / Double(records.count)
            guard accuracy < 0.8 else { return nil }
            let title = content.chapter(id: chapterID)?.title ?? chapterID
            return (chapterID: chapterID, chapterTitle: title, accuracy: accuracy)
        }
        .sorted { $0.accuracy < $1.accuracy }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: FlashcardDeckView()) {
                    quickActionCard(title: "Flashcards", icon: "rectangle.on.rectangle.angled", color: .orange)
                }
                NavigationLink(destination: QuizSetupView()) {
                    quickActionCard(title: "Practice Quiz", icon: "checkmark.circle.fill", color: .green)
                }
                NavigationLink(destination: GlossaryView()) {
                    quickActionCard(title: "Glossary", icon: "character.book.closed.fill", color: .purple)
                }
                NavigationLink(destination: SearchContentView()) {
                    quickActionCard(title: "Search", icon: "magnifyingglass", color: .blue)
                }
            }
        }
    }

    private func quickActionCard(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func parseDueDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        // Try with timezone offset
        if let date = formatter.date(from: string) { return date }
        // Try fixing format
        let cleaned = string.replacingOccurrences(of: "-07:00", with: "-0700")
            .replacingOccurrences(of: "-08:00", with: "-0800")
        return formatter.date(from: cleaned)
    }

    private func colorForType(_ type: AssignmentType) -> Color {
        switch type {
        case .quiz: return .blue
        case .midterm: return .red
        case .final: return .red
        case .homework: return .green
        case .preLecture: return .orange
        case .labReport: return .purple
        case .labAssessment: return .purple
        }
    }

    private func dateFromString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}
