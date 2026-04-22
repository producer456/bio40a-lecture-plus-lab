import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ContentService.self) private var content
    @Query(sort: \QuizAttempt.date, order: .reverse) private var quizAttempts: [QuizAttempt]
    @Query private var studyProgress: [StudyProgress]
    @Query(sort: \PerformanceRecord.date, order: .reverse) private var performanceRecords: [PerformanceRecord]
    @Query(sort: \FlashcardProgress.nextReviewDate) private var flashcardProgress: [FlashcardProgress]
    @AppStorage("userName") private var userName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero banner
                BioHeroBanner(
                    system: .nervous,
                    title: greetingText,
                    subtitle: currentWeek != nil ? "Week \(currentWeek!) \u{2022} \(currentWeekTopic)" : nil,
                    height: 180
                )

                upcomingDueDatesSection
                continueStudyingSection
                weeklyOverviewSection
                weakSpotsPreviewSection
                quickActionsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("BIO 40A")
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        if hour < 12 { greeting = "Good morning" }
        else if hour < 17 { greeting = "Good afternoon" }
        else { greeting = "Good evening" }
        return userName.isEmpty ? greeting : "\(greeting), \(userName)"
    }

    private var currentWeek: Int? {
        let today = Date()
        return content.syllabus?.lectureSchedule.first { entry in
            guard let start = dateFromString(entry.startDate),
                  let end = Calendar.current.date(byAdding: .day, value: 7, to: start) else { return false }
            return today >= start && today < end
        }?.week
    }

    private var currentWeekTopic: String {
        guard let week = currentWeek else { return "" }
        return content.syllabus?.lectureSchedule.first { $0.week == week }?.topic ?? ""
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String, system: BodySystem, trailing: AnyView? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(system.accentColor)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            if let trailing {
                trailing
            }
        }
    }

    // MARK: - Upcoming Due Dates

    private var upcomingDueDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Upcoming Due Dates", icon: "clock.badge.exclamationmark", system: .endocrine)

            let upcoming = upcomingAssignments
            if upcoming.isEmpty {
                Text("No upcoming assignments")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(upcoming.prefix(5), id: \.name) { assignment in
                    dueDateRow(assignment)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(BodySystem.endocrine.primaryColor.opacity(0.15), lineWidth: 1))
        )
    }

    private func dueDateRow(_ assignment: Assignment) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(colorForType(assignment.type))
                .frame(width: 8, height: 8)

            Text(assignment.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            if let due = parseDueDate(assignment.dueDate) {
                urgencyBadge(for: due)
            }
        }
        .padding(.vertical, 4)
    }

    private func urgencyBadge(for date: Date) -> some View {
        let interval = date.timeIntervalSince(Date())
        let days = interval / 86400
        let color: Color = days < 1 ? .red : (days < 3 ? .orange : .green)
        let text: String
        if days < 1 {
            let hours = max(0, Int(interval / 3600))
            text = "\(hours)h left"
        } else {
            text = "\(Int(days))d left"
        }
        return Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var upcomingAssignments: [Assignment] {
        guard let syllabus = content.syllabus else { return [] }
        let now = Date()

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
            sectionHeader("Continue Studying", icon: "book.fill", system: .skeletal)

            let chaptersInProgress = studyProgress
                .filter { $0.readPercentage > 0 && $0.readPercentage < 1.0 }
                .prefix(3)

            if chaptersInProgress.isEmpty {
                if let firstChapter = content.chapters.first {
                    NavigationLink(destination: ChapterDetailView(chapter: firstChapter)) {
                        studyCard(title: firstChapter.title, progress: 0, chapter: firstChapter)
                    }
                }
            } else {
                ForEach(Array(chaptersInProgress), id: \.chapterID) { progress in
                    if let chapter = content.chapter(id: progress.chapterID) {
                        NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                            studyCard(title: chapter.title, progress: progress.readPercentage, chapter: chapter)
                        }
                    }
                }
            }
        }
    }

    private func studyCard(title: String, progress: Double, chapter: Chapter) -> some View {
        BioCard(system: .skeletal) {
            HStack(spacing: 12) {
                // Chapter number circle
                Text("\(chapter.number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(BodySystem.skeletal.primaryColor, in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(BodySystem.skeletal.primaryColor)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(BodySystem.skeletal.primaryColor)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Weekly Overview

    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("This Week", icon: "calendar", system: .cardiovascular)

            HStack(spacing: 12) {
                BioStatBadge(value: "\(flashcardsDueCount)", label: "Flashcards", system: .endocrine)
                BioStatBadge(value: quizAverage, label: "Quiz Avg", system: .cardiovascular)
                BioStatBadge(value: "\(chaptersCompleted)/\(content.chapters.count)", label: "Chapters", system: .skeletal)
            }
        }
    }

    private var flashcardsDueCount: Int {
        flashcardProgress.filter { $0.nextReviewDate <= Date() }.count
    }

    private var quizAverage: String {
        let recent = quizAttempts.prefix(5)
        guard !recent.isEmpty else { return "--" }
        let totalQuestions = recent.reduce(0) { $0 + $1.totalQuestions }
        guard totalQuestions > 0 else { return "--" }
        let avg = Double(recent.reduce(0) { $0 + $1.score }) / Double(totalQuestions)
        return "\(Int(avg * 100))%"
    }

    private var chaptersCompleted: Int {
        Set(studyProgress.filter { $0.readPercentage >= 1.0 }.map { $0.chapterID }).count
    }

    // MARK: - Weak Spots Preview

    private var weakSpotsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "Weak Spots",
                icon: "exclamationmark.triangle.fill",
                system: .muscular,
                trailing: AnyView(
                    NavigationLink("See All") {
                        WeakSpotsView()
                    }
                    .font(.subheadline)
                )
            )

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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(BodySystem.muscular.primaryColor.opacity(0.15), lineWidth: 1))
        )
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
            sectionHeader("Quick Actions", icon: "bolt.fill", system: .nervous)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                NavigationLink(destination: FlashcardDeckView()) {
                    quickActionCard(title: "Flashcards", icon: "rectangle.on.rectangle.angled", system: .endocrine)
                }
                NavigationLink(destination: QuizSetupView()) {
                    quickActionCard(title: "Practice Quiz", icon: "checkmark.circle.fill", system: .cardiovascular)
                }
                NavigationLink(destination: GlossaryView()) {
                    quickActionCard(title: "Glossary", icon: "character.book.closed.fill", system: .organ)
                }
                NavigationLink(destination: SearchContentView()) {
                    quickActionCard(title: "Search", icon: "magnifyingglass", system: .nervous)
                }
            }
        }
    }

    private func quickActionCard(title: String, icon: String, system: BodySystem) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(system.primaryColor)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(system.primaryColor.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(system.primaryColor.opacity(0.15), lineWidth: 1)
                )
        )
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
