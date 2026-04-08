import SwiftUI
import SwiftData

struct ChapterDetailView: View {
    let chapter: Chapter
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [UserBookmark]
    @Query private var allMaterials: [StudyMaterial]
    @State private var selectedSection: ChapterSection?

    private var chapterMaterials: [StudyMaterial] {
        allMaterials.filter { $0.linkedChapterIDs.contains(chapter.id) }
    }

    var body: some View {
        List {
            // Uploaded Materials
            if !chapterMaterials.isEmpty {
                Section("Your Materials (\(chapterMaterials.count))") {
                    ForEach(chapterMaterials) { material in
                        NavigationLink(destination: StudyMaterialDetailView(material: material)) {
                            HStack(spacing: 10) {
                                Image(systemName: material.materialType == "photo" ? "photo.fill" : material.materialType == "pdf" ? "doc.fill" : "doc.text.fill")
                                    .foregroundStyle(material.materialType == "pdf" ? .red : .blue)
                                VStack(alignment: .leading) {
                                    Text(material.title)
                                        .font(.subheadline)
                                    Text(MaterialCategory(rawValue: material.category)?.label ?? material.category)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // Quick Review
            Section("Quick Review") {
                NavigationLink(destination: QuickReviewView(chapter: chapter)) {
                    Label("Chapter Summary", systemImage: "doc.text.fill")
                }
            }

            // Sections
            Section("Sections") {
                ForEach(chapter.sections) { section in
                    NavigationLink(destination: SectionContentView(section: section, chapter: chapter)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if !section.objectives.isEmpty {
                                    Text("\(section.objectives.count) objectives")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if isBookmarked(section.id) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            // Glossary
            if !chapter.glossaryTerms.isEmpty {
                Section("Key Terms (\(chapter.glossaryTerms.count))") {
                    ForEach(chapter.glossaryTerms, id: \.term) { term in
                        VStack(alignment: .leading, spacing: 4) {
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

            // Practice
            Section("Practice") {
                NavigationLink(destination: QuizView(questions: chapter.sections.flatMap(\.reviewQuestions), chapterTitle: chapter.title)) {
                    Label("Practice Quiz (\(chapter.totalQuestions) questions)", systemImage: "checkmark.circle.fill")
                }
                NavigationLink(destination: FlashcardStudyView(chapterID: chapter.id)) {
                    Label("Flashcards", systemImage: "rectangle.on.rectangle.angled")
                }
            }
        }
        .navigationTitle("Ch. \(chapter.number): \(chapter.title)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isBookmarked(_ sectionID: String) -> Bool {
        bookmarks.contains { $0.sectionID == sectionID }
    }
}

// MARK: - Section Content View

struct SectionContentView: View {
    let section: ChapterSection
    let chapter: Chapter
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [UserBookmark]
    @State private var showObjectives = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Objectives
                if !section.objectives.isEmpty {
                    DisclosureGroup("Learning Objectives", isExpanded: $showObjectives) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(section.objectives, id: \.self) { objective in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                    Text(objective)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Content
                ForEach(Array(section.content.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.body)
                        .lineSpacing(4)
                }

                // Chapter Review
                if !section.chapterReview.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chapter Review")
                            .font(.headline)
                        Text(section.chapterReview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                }

                // Review Questions
                if !section.reviewQuestions.isEmpty {
                    Divider()
                    NavigationLink(destination: QuizView(questions: section.reviewQuestions, chapterTitle: "\(chapter.title) - \(section.title)")) {
                        Label("Practice \(section.reviewQuestions.count) Review Questions", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleBookmark()
                } label: {
                    Image(systemName: isSectionBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isSectionBookmarked ? .orange : .primary)
                }
            }
        }
        .onAppear {
            trackProgress()
        }
    }

    private var isSectionBookmarked: Bool {
        bookmarks.contains { $0.sectionID == section.id }
    }

    private func toggleBookmark() {
        if let existing = bookmarks.first(where: { $0.sectionID == section.id }) {
            modelContext.delete(existing)
        } else {
            let bookmark = UserBookmark(chapterID: chapter.id, sectionID: section.id)
            modelContext.insert(bookmark)
        }
    }

    private func trackProgress() {
        let existing = try? modelContext.fetch(FetchDescriptor<StudyProgress>(
            predicate: #Predicate { $0.chapterID == chapter.id && $0.sectionID == section.id }
        ))
        if let progress = existing?.first {
            progress.readPercentage = 1.0
            progress.lastReadDate = Date()
        } else {
            let progress = StudyProgress(chapterID: chapter.id, sectionID: section.id, readPercentage: 1.0)
            modelContext.insert(progress)
        }
    }
}

// MARK: - Quick Review

struct QuickReviewView: View {
    let chapter: Chapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(chapter.sections) { section in
                    if !section.chapterReview.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.headline)
                            Text(section.chapterReview)
                                .font(.body)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Quick Review: Ch. \(chapter.number)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
