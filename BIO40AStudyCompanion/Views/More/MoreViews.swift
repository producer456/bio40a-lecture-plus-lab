import SwiftUI
import SwiftData
import Charts

// MARK: - More Tab

struct MoreView: View {
    var body: some View {
        List {
            Section("Study") {
                NavigationLink(destination: GlossaryView()) {
                    Label("Glossary", systemImage: "character.book.closed.fill")
                }
                NavigationLink(destination: LabPrepListView()) {
                    Label("Lab Prep", systemImage: "flask.fill")
                }
                NavigationLink(destination: SearchContentView()) {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }
            Section("Class") {
                NavigationLink(destination: AssignmentLogListView()) {
                    Label("Assignment Log", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink(destination: StudyMaterialLibraryView()) {
                    Label("Study Materials", systemImage: "folder.fill")
                }
            }
            Section("Progress") {
                NavigationLink(destination: WeakSpotsView()) {
                    Label("Weak Spots", systemImage: "exclamationmark.triangle.fill")
                }
                NavigationLink(destination: ProgressDashboardView()) {
                    Label("Progress Dashboard", systemImage: "chart.bar.fill")
                }
                NavigationLink(destination: BookmarksView()) {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                }
            }
            Section {
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
        .navigationTitle("More")
    }
}

// MARK: - Glossary

struct GlossaryView: View {
    @Environment(ContentService.self) private var content
    @State private var searchText = ""

    private var filteredTerms: [GlossaryTerm] {
        if searchText.isEmpty { return content.glossaryTerms }
        return content.glossaryTerms.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredTerms, id: \.term) { term in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(term.term)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        if let chID = term.chapterID, let ch = content.chapter(id: chID) {
                            Text("Ch. \(ch.number)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    Text(term.definition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .searchable(text: $searchText, prompt: "Search terms...")
        .navigationTitle("Glossary (\(content.glossaryTerms.count))")
    }
}

// MARK: - Lab Prep

struct LabPrepListView: View {
    @Environment(ContentService.self) private var content

    var body: some View {
        List {
            if let syllabus = content.syllabus {
                ForEach(syllabus.labSchedule, id: \.week) { week in
                    NavigationLink(destination: LabPrepDetailView(week: week)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Week \(week.week)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(week.topic)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            if let chapters = week.chapters, !chapters.isEmpty {
                                Text("\(chapters.count) ch.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Lab Prep")
    }
}

struct LabPrepDetailView: View {
    let week: WeekEntry
    @Environment(ContentService.self) private var content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Lab Info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Lab Week \(week.week)", systemImage: "flask.fill")
                        .font(.headline)
                    Text(week.topic)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Starting \(week.startDate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Related Chapters
                if let chapters = week.chapters, !chapters.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prep Reading")
                            .font(.headline)

                        ForEach(chapters, id: \.self) { chapterID in
                            if let chapter = content.chapter(id: chapterID) {
                                NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundStyle(.blue)
                                        VStack(alignment: .leading) {
                                            Text("Ch. \(chapter.number): \(chapter.title)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("\(chapter.sections.count) sections")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    // Key Terms for Lab
                    let labTerms = chapters.flatMap { content.glossaryForChapter($0) }
                    if !labTerms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Terms to Know (\(labTerms.count))")
                                .font(.headline)
                            ForEach(labTerms, id: \.term) { term in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(term.term)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(term.definition)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Lab Week \(week.week)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Search

struct SearchContentView: View {
    @Environment(ContentService.self) private var content
    @State private var searchText = ""

    var body: some View {
        List {
            if searchText.isEmpty {
                Section {
                    Text("Search across all chapters, glossary terms, and questions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                let results = content.searchContent(query: searchText)
                if results.isEmpty {
                    Text("No results for \"\(searchText)\"")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                        Group {
                            if let chapter = content.chapter(id: result.chapterID),
                               let sectionID = result.sectionID,
                               let section = chapter.sections.first(where: { $0.id == sectionID }) {
                                NavigationLink(destination: SectionContentView(section: section, chapter: chapter)) {
                                    searchResultRow(result)
                                }
                            } else if let chapter = content.chapter(id: result.chapterID) {
                                NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                                    searchResultRow(result)
                                }
                            } else {
                                searchResultRow(result)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search content...")
        .navigationTitle("Search")
    }

    private func searchResultRow(_ result: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForMatchType(result.matchType))
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text(result.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Text(result.snippet)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            if let ch = content.chapter(id: result.chapterID) {
                Text("Ch. \(ch.number): \(ch.title)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconForMatchType(_ type: SearchResult.MatchType) -> String {
        switch type {
        case .content: return "doc.text"
        case .glossary: return "character.book.closed"
        case .question: return "questionmark.circle"
        }
    }
}

// MARK: - Progress Dashboard

struct ProgressDashboardView: View {
    @Environment(ContentService.self) private var content
    @Query private var studyProgress: [StudyProgress]
    @Query(sort: \QuizAttempt.date, order: .reverse) private var quizAttempts: [QuizAttempt]
    @Query private var performanceRecords: [PerformanceRecord]
    @Query private var flashcardProgress: [FlashcardProgress]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Reading Progress
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reading Progress")
                        .font(.headline)

                    ForEach(content.chapters) { chapter in
                        let progress = chapterReadProgress(chapter.id)
                        HStack {
                            Text("Ch. \(chapter.number)")
                                .font(.caption)
                                .frame(width: 40)
                            ProgressView(value: progress)
                                .tint(progress >= 1.0 ? .green : .blue)
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .frame(width: 35)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Quiz History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Quizzes")
                        .font(.headline)

                    if quizAttempts.isEmpty {
                        Text("No quizzes taken yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(quizAttempts.prefix(10)) { attempt in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(attempt.score)/\(attempt.totalQuestions)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(attempt.date, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                let pct = Double(attempt.score) / Double(max(attempt.totalQuestions, 1))
                                Text("\(Int(pct * 100))%")
                                    .font(.subheadline)
                                    .foregroundStyle(pct >= 0.7 ? .green : .red)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Flashcard Mastery
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flashcard Mastery")
                        .font(.headline)

                    let total = content.flashcardDecks.flatMap(\.cards).count
                    let mastered = flashcardProgress.filter { $0.repetitions >= 3 }.count
                    let learning = flashcardProgress.filter { $0.repetitions > 0 && $0.repetitions < 3 }.count
                    let unseen = max(0, total - flashcardProgress.count)

                    HStack(spacing: 20) {
                        masteryStatView(label: "Mastered", count: mastered, color: .green)
                        masteryStatView(label: "Learning", count: learning, color: .orange)
                        masteryStatView(label: "Unseen", count: unseen, color: .gray)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle("Progress")
    }

    private func chapterReadProgress(_ chapterID: String) -> Double {
        let sections = studyProgress.filter { $0.chapterID == chapterID }
        let totalSections = content.chapter(id: chapterID)?.sections.count ?? 1
        guard totalSections > 0 else { return 0 }
        return Double(sections.filter { $0.readPercentage >= 1.0 }.count) / Double(totalSections)
    }

    private func masteryStatView(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bookmarks

struct BookmarksView: View {
    @Environment(ContentService.self) private var content
    @Query(sort: \UserBookmark.createdDate, order: .reverse) private var bookmarks: [UserBookmark]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if bookmarks.isEmpty {
                Text("No bookmarks yet. Bookmark sections while reading to save them here.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(bookmarks) { bookmark in
                    if let chapter = content.chapter(id: bookmark.chapterID),
                       let section = chapter.sections.first(where: { $0.id == bookmark.sectionID }) {
                        NavigationLink(destination: SectionContentView(section: section, chapter: chapter)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Ch. \(chapter.number): \(chapter.title)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let note = bookmark.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(bookmarks[index])
                    }
                }
            }
        }
        .navigationTitle("Bookmarks")
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(ContentService.self) private var content
    @AppStorage("userName") private var userName = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("dailyFlashcardGoal") private var dailyFlashcardGoal = 20

    var body: some View {
        List {
            Section("Profile") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $userName)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notifications") {
                Toggle("Due Date Reminders", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, enabled in
                        if enabled {
                            NotificationService.shared.requestPermission()
                            if let syllabus = content.syllabus {
                                NotificationService.shared.scheduleAssignmentNotifications(syllabus: syllabus)
                            }
                        } else {
                            NotificationService.shared.cancelAll()
                        }
                    }
            }

            Section("Study Goals") {
                Stepper("Daily Flashcard Goal: \(dailyFlashcardGoal)", value: $dailyFlashcardGoal, in: 5...100, step: 5)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Textbook")
                    Spacer()
                    Text("OpenStax A&P 2e")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Course")
                    Spacer()
                    Text("BIO 40A - Spring 2026")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
