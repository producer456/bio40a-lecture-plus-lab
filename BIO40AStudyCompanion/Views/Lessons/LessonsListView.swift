import SwiftUI
import SwiftData

struct LessonsListView: View {
    @Environment(ContentService.self) private var content
    @Query private var studyProgress: [StudyProgress]
    @State private var selectedView: LessonViewMode = .byWeek

    enum LessonViewMode: String, CaseIterable {
        case byWeek = "By Week"
        case byChapter = "By Chapter"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedView) {
                ForEach(LessonViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                switch selectedView {
                case .byWeek:
                    weekView
                case .byChapter:
                    chapterView
                }
            }
        }
        .navigationTitle("Lessons")
    }

    // MARK: - Week View

    @ViewBuilder
    private var weekView: some View {
        if let syllabus = content.syllabus {
            ForEach(syllabus.lectureSchedule, id: \.week) { week in
                Section("Week \(week.week): \(week.topic)") {
                    ForEach(week.chapters ?? [], id: \.self) { chapterID in
                        if let chapter = content.chapter(id: chapterID) {
                            chapterRow(chapter)
                        }
                    }

                    if let labWeek = syllabus.labSchedule.first(where: { $0.week == week.week }) {
                        HStack {
                            Image(systemName: "flask.fill")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading) {
                                Text("Lab")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(labWeek.topic)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Chapter View

    @ViewBuilder
    private var chapterView: some View {
        ForEach(content.chapters) { chapter in
            chapterRow(chapter)
        }
    }

    private func chapterRow(_ chapter: Chapter) -> some View {
        NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chapter \(chapter.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(chapter.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(chapter.sections.count) sections \u{2022} \(chapter.totalQuestions) questions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                CircularProgressView(progress: chapterProgress(chapter.id))
                    .frame(width: 40, height: 40)
            }
            .padding(.vertical, 4)
        }
    }

    private func chapterProgress(_ chapterID: String) -> Double {
        let chapterSections = studyProgress.filter { $0.chapterID == chapterID }
        let totalSections = content.chapter(id: chapterID)?.sections.count ?? 1
        guard totalSections > 0 else { return 0 }
        return chapterSections.reduce(0) { $0 + $1.readPercentage } / Double(totalSections)
    }
}
