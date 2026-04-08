import SwiftUI

struct ScheduleView: View {
    @Environment(ContentService.self) private var content
    @State private var selectedView: ScheduleViewMode = .lecture

    enum ScheduleViewMode: String, CaseIterable {
        case lecture = "Lecture"
        case lab = "Lab"
        case all = "All Due Dates"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedView) {
                ForEach(ScheduleViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                switch selectedView {
                case .lecture: lectureSchedule
                case .lab: labSchedule
                case .all: allDueDates
                }
            }
        }
        .navigationTitle("Schedule")
    }

    @ViewBuilder
    private var lectureSchedule: some View {
        if let syllabus = content.syllabus {
            ForEach(syllabus.lectureSchedule, id: \.week) { week in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(week.topic)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Starting \(week.startDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let assignments = week.assignments, !assignments.isEmpty {
                            Divider()
                            ForEach(assignments, id: \.name) { assignment in
                                HStack {
                                    Circle()
                                        .fill(colorForType(assignment.type))
                                        .frame(width: 8, height: 8)
                                    Text(assignment.name)
                                        .font(.caption)
                                    Spacer()
                                    Text(formatDueDate(assignment.dueDate))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Week \(week.week)")
                        Spacer()
                        if isCurrentWeek(week.startDate) {
                            Text("CURRENT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.blue, in: Capsule())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var labSchedule: some View {
        if let syllabus = content.syllabus {
            ForEach(syllabus.labSchedule, id: \.week) { week in
                Section("Week \(week.week)") {
                    HStack {
                        Image(systemName: "flask.fill")
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(week.topic)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let chapters = week.chapters, !chapters.isEmpty {
                                Text("Chapters: \(chapters.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var allDueDates: some View {
        let assignments = allAssignmentsSorted()
        let now = Date()

        Section("Upcoming") {
            ForEach(assignments.filter { parseDueDate($0.dueDate) ?? .distantPast > now }, id: \.name) { a in
                assignmentRow(a)
            }
        }
        Section("Past") {
            ForEach(assignments.filter { parseDueDate($0.dueDate) ?? .distantPast <= now }, id: \.name) { a in
                assignmentRow(a)
                    .opacity(0.6)
            }
        }
    }

    private func assignmentRow(_ assignment: Assignment) -> some View {
        HStack {
            Circle()
                .fill(colorForType(assignment.type))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(assignment.name)
                    .font(.subheadline)
                Text(formatDueDate(assignment.dueDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(assignment.type.rawValue.capitalized)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorForType(assignment.type).opacity(0.15), in: Capsule())
        }
    }

    private func allAssignmentsSorted() -> [Assignment] {
        guard let syllabus = content.syllabus else { return [] }
        return syllabus.lectureSchedule
            .flatMap { $0.assignments ?? [] }
            .sorted { (parseDueDate($0.dueDate) ?? .distantFuture) < (parseDueDate($1.dueDate) ?? .distantFuture) }
    }

    private func formatDueDate(_ string: String) -> String {
        guard let date = parseDueDate(string) else { return string }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func parseDueDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private func isCurrentWeek(_ startDate: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let start = formatter.date(from: startDate),
              let end = Calendar.current.date(byAdding: .day, value: 7, to: start) else { return false }
        return Date() >= start && Date() < end
    }

    private func colorForType(_ type: AssignmentType) -> Color {
        switch type {
        case .quiz: return .blue
        case .midterm, .final: return .red
        case .homework: return .green
        case .preLecture: return .orange
        case .labReport, .labAssessment: return .purple
        }
    }
}
