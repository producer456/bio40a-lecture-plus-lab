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
        ScrollView {
            VStack(spacing: 20) {
                // Hero banner
                BioHeroBanner(
                    system: .skeletal,
                    title: "Lessons",
                    subtitle: "\(content.chapters.count) chapters of anatomy & physiology",
                    badge: "LESSONS",
                    height: 120
                )

                Picker("View", selection: $selectedView) {
                    ForEach(LessonViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                // Interactive Learning prominent card
                NavigationLink(destination: InteractiveLearningListView()) {
                    BioCard(system: .muscular) {
                        HStack(spacing: 14) {
                            Image(systemName: "hand.tap.fill")
                                .font(.title2)
                                .foregroundStyle(BodySystem.muscular.primaryColor)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Learning Through Interaction")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Text("Read lessons with inline quizzes & challenges")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                switch selectedView {
                case .byWeek:
                    weekView
                case .byChapter:
                    chapterView
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Lessons")
    }

    // MARK: - Week View

    @ViewBuilder
    private var weekView: some View {
        if let syllabus = content.syllabus {
            ForEach(syllabus.lectureSchedule, id: \.week) { week in
                VStack(alignment: .leading, spacing: 12) {
                    BioSectionHeader(title: "Week \(week.week): \(week.topic)", icon: "calendar", system: .skeletal)

                    ForEach(week.chapters ?? [], id: \.self) { chapterID in
                        if let chapter = content.chapter(id: chapterID) {
                            NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                                chapterCard(chapter)
                            }
                        }
                    }

                    if let labWeek = syllabus.labSchedule.first(where: { $0.week == week.week }) {
                        BioCard(system: .organ) {
                            HStack(spacing: 12) {
                                Image(systemName: "flask.fill")
                                    .font(.title3)
                                    .foregroundStyle(BodySystem.organ.primaryColor)
                                    .frame(width: 36, height: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Lab")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(labWeek.topic)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                }
                                Spacer(minLength: 0)
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
            NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                chapterCard(chapter)
            }
        }
    }

    private func chapterCard(_ chapter: Chapter) -> some View {
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
                    Text(chapter.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text("\(chapter.sections.count) sections \u{2022} \(chapter.totalQuestions) questions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        BloodFlowProgress(value: chapterProgress(chapter.id), system: .skeletal)
                        Text("\(Int(chapterProgress(chapter.id) * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(BodySystem.skeletal.primaryColor)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func chapterProgress(_ chapterID: String) -> Double {
        let chapterSections = studyProgress.filter { $0.chapterID == chapterID }
        let totalSections = content.chapter(id: chapterID)?.sections.count ?? 1
        guard totalSections > 0 else { return 0 }
        return chapterSections.reduce(0) { $0 + $1.readPercentage } / Double(totalSections)
    }
}
