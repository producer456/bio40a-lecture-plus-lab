import SwiftUI
import SwiftData

// MARK: - Assignment Log List

struct AssignmentLogListView: View {
    @Environment(ContentService.self) private var content
    @Query(sort: \AssignmentReflection.date, order: .reverse) private var reflections: [AssignmentReflection]
    @State private var showingNewReflection = false

    var body: some View {
        List {
            // Summary stats
            if !reflections.isEmpty {
                Section {
                    HStack(spacing: 20) {
                        statBubble(label: "Logged", value: "\(reflections.count)", color: .blue)
                        statBubble(label: "Avg Score", value: averageScore, color: scoreColor)
                        statBubble(label: "Struggled", value: "\(totalStruggledTopics)", color: .orange)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Logged assignments
            if reflections.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No assignments logged yet")
                            .font(.headline)
                        Text("After completing a class assignment, log it here to track what topics appeared and what you struggled with. This improves your study recommendations.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                // Group by week
                let grouped = Dictionary(grouping: reflections, by: \.week)
                ForEach(grouped.keys.sorted().reversed(), id: \.self) { week in
                    Section("Week \(week)") {
                        ForEach(grouped[week] ?? []) { reflection in
                            NavigationLink(destination: AssignmentReflectionDetailView(reflection: reflection)) {
                                reflectionRow(reflection)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Assignment Log")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewReflection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewReflection) {
            NavigationStack {
                NewAssignmentReflectionView()
            }
        }
    }

    private func reflectionRow(_ reflection: AssignmentReflection) -> some View {
        HStack {
            Circle()
                .fill(colorForType(reflection.assignmentType))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(reflection.assignmentName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(reflection.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let pct = reflection.scorePercentage {
                        Text("\(Int(pct * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(pct >= 0.7 ? .green : .red)
                    }
                    if !reflection.topicsStruggled.isEmpty {
                        Label("\(reflection.topicsStruggled.count) struggled", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private func statBubble(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var averageScore: String {
        let scored = reflections.compactMap(\.scorePercentage)
        guard !scored.isEmpty else { return "--" }
        let avg = scored.reduce(0, +) / Double(scored.count)
        return "\(Int(avg * 100))%"
    }

    private var scoreColor: Color {
        let scored = reflections.compactMap(\.scorePercentage)
        guard !scored.isEmpty else { return .secondary }
        let avg = scored.reduce(0, +) / Double(scored.count)
        return avg >= 0.7 ? .green : .red
    }

    private var totalStruggledTopics: Int {
        Set(reflections.flatMap(\.topicsStruggled)).count
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "quiz": return .blue
        case "midterm", "final": return .red
        case "homework": return .green
        case "preLecture": return .orange
        case "labReport", "labAssessment": return .purple
        default: return .gray
        }
    }
}

// MARK: - New Assignment Reflection

struct NewAssignmentReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ContentService.self) private var content

    // Assignment info
    @State private var selectedAssignment: Assignment?
    @State private var customName = ""
    @State private var customType: AssignmentType = .homework
    @State private var isCustom = false
    @State private var selectedWeek = 1

    // Score
    @State private var hasScore = false
    @State private var pointsEarned = ""
    @State private var pointsPossible = ""

    // Topics
    @State private var topicsCovered: Set<String> = []
    @State private var topicsStruggled: Set<String> = []
    @State private var instructorEmphasis: Set<String> = []

    // Notes
    @State private var notes = ""

    // UI state
    @State private var currentStep = 0

    var body: some View {
        TabView(selection: $currentStep) {
            step1AssignmentSelection.tag(0)
            step2Score.tag(1)
            step3Topics.tag(2)
            step4Notes.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentStep)
        .navigationTitle("Log Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Step 1: Select Assignment

    private var step1AssignmentSelection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(number: 1, title: "Which assignment?", subtitle: "Select from your syllabus or create a custom entry")

                if !isCustom {
                    // Syllabus assignments grouped by week
                    if let syllabus = content.syllabus {
                        ForEach(syllabus.lectureSchedule, id: \.week) { week in
                            if let assignments = week.assignments, !assignments.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Week \(week.week): \(week.topic)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    ForEach(assignments) { assignment in
                                        Button {
                                            selectedAssignment = assignment
                                            selectedWeek = week.week
                                        } label: {
                                            HStack {
                                                Circle()
                                                    .fill(selectedAssignment?.code == assignment.code ? .blue : .gray.opacity(0.3))
                                                    .frame(width: 20, height: 20)
                                                    .overlay {
                                                        if selectedAssignment?.code == assignment.code {
                                                            Image(systemName: "checkmark")
                                                                .font(.caption2)
                                                                .foregroundStyle(.white)
                                                        }
                                                    }
                                                Text(assignment.name)
                                                    .font(.subheadline)
                                                Spacer()
                                                Text(assignment.code)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .tint(.primary)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    Button("Or log a custom assignment...") {
                        isCustom = true
                        selectedAssignment = nil
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                } else {
                    // Custom assignment entry
                    VStack(spacing: 16) {
                        TextField("Assignment name", text: $customName)
                            .textFieldStyle(.roundedBorder)

                        Picker("Type", selection: $customType) {
                            Text("Pre-Lecture").tag(AssignmentType.preLecture)
                            Text("Homework").tag(AssignmentType.homework)
                            Text("Quiz").tag(AssignmentType.quiz)
                            Text("Midterm").tag(AssignmentType.midterm)
                            Text("Lab Report").tag(AssignmentType.labReport)
                            Text("Lab Assessment").tag(AssignmentType.labAssessment)
                        }

                        Stepper("Week \(selectedWeek)", value: $selectedWeek, in: 1...12)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Button("Select from syllabus instead...") {
                        isCustom = false
                    }
                    .font(.subheadline)
                }

                nextButton(enabled: selectedAssignment != nil || (!customName.isEmpty && isCustom))
            }
            .padding()
        }
    }

    // MARK: - Step 2: Score

    private var step2Score: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(number: 2, title: "How did you do?", subtitle: "Enter your score if you have it, or skip for now")

                Toggle("I have my score", isOn: $hasScore)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                if hasScore {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Points earned")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0", text: $pointsEarned)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }
                        VStack(alignment: .leading) {
                            Text("Points possible")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0", text: $pointsPossible)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    if let earned = Double(pointsEarned), let possible = Double(pointsPossible), possible > 0 {
                        let pct = earned / possible
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(pct >= 0.7 ? .green : .red)
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack {
                    backButton
                    nextButton(enabled: true)
                }
            }
            .padding()
        }
    }

    // MARK: - Step 3: Topics

    private var step3Topics: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(number: 3, title: "What topics appeared?", subtitle: "Select topics that were on the assignment, and mark any you struggled with")

                // Get relevant chapters for the selected week
                let relevantChapters = chaptersForWeek(selectedWeek)

                ForEach(relevantChapters) { chapter in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ch. \(chapter.number): \(chapter.title)")
                            .font(.subheadline)
                            .fontWeight(.bold)

                        ForEach(chapter.sections) { section in
                            HStack {
                                // Covered toggle
                                Button {
                                    toggleSet(&topicsCovered, section.id)
                                } label: {
                                    Image(systemName: topicsCovered.contains(section.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(topicsCovered.contains(section.id) ? .blue : .gray)
                                }

                                Text(section.title)
                                    .font(.caption)
                                    .lineLimit(2)

                                Spacer()

                                if topicsCovered.contains(section.id) {
                                    // Struggled button
                                    Button {
                                        toggleSet(&topicsStruggled, section.id)
                                    } label: {
                                        Image(systemName: topicsStruggled.contains(section.id) ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                            .font(.caption)
                                            .foregroundStyle(topicsStruggled.contains(section.id) ? .red : .gray)
                                    }

                                    // Emphasis button
                                    Button {
                                        toggleSet(&instructorEmphasis, section.id)
                                    } label: {
                                        Image(systemName: instructorEmphasis.contains(section.id) ? "star.fill" : "star")
                                            .font(.caption)
                                            .foregroundStyle(instructorEmphasis.contains(section.id) ? .yellow : .gray)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Show all chapters option
                if relevantChapters.count < content.chapters.count {
                    DisclosureGroup("Show all chapters") {
                        ForEach(content.chapters.filter { ch in !relevantChapters.contains(where: { $0.id == ch.id }) }) { chapter in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ch. \(chapter.number): \(chapter.title)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)

                                ForEach(chapter.sections) { section in
                                    HStack {
                                        Button {
                                            toggleSet(&topicsCovered, section.id)
                                        } label: {
                                            Image(systemName: topicsCovered.contains(section.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(topicsCovered.contains(section.id) ? .blue : .gray)
                                        }
                                        Text(section.title)
                                            .font(.caption2)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.vertical, 1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .font(.subheadline)
                }

                // Legend
                HStack(spacing: 16) {
                    Label("Covered", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Label("Struggled", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Label("Emphasized", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

                HStack {
                    backButton
                    nextButton(enabled: true)
                }
            }
            .padding()
        }
    }

    // MARK: - Step 4: Notes & Save

    private var step4Notes: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(number: 4, title: "Any notes?", subtitle: "Jot down anything you want to remember about this assignment")

                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(assignmentDisplayName)
                        .font(.caption)
                    if let pct = computedScorePercentage {
                        Text("Score: \(Int(pct * 100))%")
                            .font(.caption)
                    }
                    Text("\(topicsCovered.count) topics covered, \(topicsStruggled.count) struggled, \(instructorEmphasis.count) emphasized")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                HStack {
                    backButton

                    Button {
                        saveReflection()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func stepHeader(number: Int, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Step \(number) of 4")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView(value: Double(number), total: 4)
                    .frame(width: 80)
            }
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func nextButton(enabled: Bool) -> some View {
        Button {
            withAnimation { currentStep += 1 }
        } label: {
            Text("Next")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(enabled ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
        }
        .disabled(!enabled)
    }

    private var backButton: some View {
        Button {
            withAnimation { currentStep -= 1 }
        } label: {
            Text("Back")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func toggleSet(_ set: inout Set<String>, _ value: String) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }

    private var assignmentDisplayName: String {
        if let assignment = selectedAssignment {
            return assignment.name
        }
        return customName
    }

    private var computedScorePercentage: Double? {
        guard hasScore,
              let earned = Double(pointsEarned),
              let possible = Double(pointsPossible),
              possible > 0 else { return nil }
        return earned / possible
    }

    private func chaptersForWeek(_ week: Int) -> [Chapter] {
        guard let syllabus = content.syllabus else { return content.chapters }
        let lectureChapters = syllabus.lectureSchedule
            .first { $0.week == week }?.chapters ?? []
        let labChapters = syllabus.labSchedule
            .first { $0.week == week }?.chapters ?? []
        let allChapterIDs = Set(lectureChapters + labChapters)
        return content.chapters.filter { allChapterIDs.contains($0.id) }
    }

    private func saveReflection() {
        let reflection = AssignmentReflection(
            assignmentCode: selectedAssignment?.code ?? customName,
            assignmentName: assignmentDisplayName,
            assignmentType: selectedAssignment?.type.rawValue ?? customType.rawValue,
            pointsEarned: hasScore ? Double(pointsEarned) : nil,
            pointsPossible: hasScore ? Double(pointsPossible) : nil,
            topicsCovered: Array(topicsCovered),
            topicsStruggled: Array(topicsStruggled),
            instructorEmphasis: Array(instructorEmphasis),
            notes: notes,
            week: selectedWeek
        )
        modelContext.insert(reflection)

        // Also create PerformanceRecords for struggled topics
        // so they feed into the weak spot analysis
        for sectionID in topicsStruggled {
            let chapterID = sectionID.components(separatedBy: "_s").first ?? ""
            let record = PerformanceRecord(
                questionID: "reflection_\(reflection.id.uuidString)_\(sectionID)",
                chapterID: chapterID,
                sectionID: sectionID,
                wasCorrect: false,
                quizType: "classAssignment"
            )
            modelContext.insert(record)
        }

        // Create positive records for covered-but-not-struggled topics
        for sectionID in topicsCovered where !topicsStruggled.contains(sectionID) {
            let chapterID = sectionID.components(separatedBy: "_s").first ?? ""
            let record = PerformanceRecord(
                questionID: "reflection_\(reflection.id.uuidString)_\(sectionID)",
                chapterID: chapterID,
                sectionID: sectionID,
                wasCorrect: true,
                quizType: "classAssignment"
            )
            modelContext.insert(record)
        }

        dismiss()
    }
}

// MARK: - Reflection Detail View

struct AssignmentReflectionDetailView: View {
    let reflection: AssignmentReflection
    @Environment(ContentService.self) private var content
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(reflection.assignmentName)
                        .font(.title2)
                        .fontWeight(.bold)
                    HStack {
                        Text("Week \(reflection.week)")
                        Text("\u{2022}")
                        Text(reflection.date, style: .date)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let pct = reflection.scorePercentage {
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(pct >= 0.7 ? .green : .red)
                    }
                }

                // Topics Covered
                if !reflection.topicsCovered.isEmpty {
                    topicSection(title: "Topics Covered", icon: "checkmark.circle.fill", color: .blue, sectionIDs: reflection.topicsCovered)
                }

                // Struggled
                if !reflection.topicsStruggled.isEmpty {
                    topicSection(title: "Struggled With", icon: "exclamationmark.triangle.fill", color: .red, sectionIDs: reflection.topicsStruggled)
                }

                // Instructor Emphasis
                if !reflection.instructorEmphasis.isEmpty {
                    topicSection(title: "Instructor Emphasized", icon: "star.fill", color: .yellow, sectionIDs: reflection.instructorEmphasis)
                }

                // Notes
                if !reflection.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(reflection.notes)
                            .font(.body)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Study action
                if !reflection.topicsStruggled.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Review")
                            .font(.headline)
                        ForEach(reflection.topicsStruggled, id: \.self) { sectionID in
                            if let (chapter, section) = findSection(sectionID) {
                                NavigationLink(destination: SectionContentView(section: section, chapter: chapter)) {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundStyle(.blue)
                                        Text("Review: \(section.title)")
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle(reflection.assignmentCode)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func topicSection(title: String, icon: String, color: Color, sectionIDs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            ForEach(sectionIDs, id: \.self) { sectionID in
                if let (chapter, section) = findSection(sectionID) {
                    HStack {
                        Text("Ch. \(chapter.number)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 35)
                        Text(section.title)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func findSection(_ sectionID: String) -> (Chapter, ChapterSection)? {
        for chapter in content.chapters {
            if let section = chapter.sections.first(where: { $0.id == sectionID }) {
                return (chapter, section)
            }
        }
        return nil
    }
}
