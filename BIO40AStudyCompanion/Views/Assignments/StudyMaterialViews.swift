import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Material Library

struct StudyMaterialLibraryView: View {
    @Environment(ContentService.self) private var content
    @Query(sort: \StudyMaterial.createdDate, order: .reverse) private var materials: [StudyMaterial]
    @State private var showingImport = false
    @State private var filterWeek: Int? = nil
    @State private var filterCategory: String? = nil

    private var filteredMaterials: [StudyMaterial] {
        materials.filter { mat in
            if let week = filterWeek, mat.week != week { return false }
            if let cat = filterCategory, mat.category != cat { return false }
            return true
        }
    }

    var body: some View {
        List {
            // Filters
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", active: filterWeek == nil && filterCategory == nil) {
                            filterWeek = nil
                            filterCategory = nil
                        }
                        ForEach(MaterialCategory.allCases, id: \.self) { cat in
                            filterChip(cat.label, active: filterCategory == cat.rawValue) {
                                filterCategory = filterCategory == cat.rawValue ? nil : cat.rawValue
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if filteredMaterials.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No materials yet")
                            .font(.headline)
                        Text("Upload photos of handouts, PDFs from Canvas, or paste text from assignments to keep everything in one place.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                // Group by week
                let grouped = Dictionary(grouping: filteredMaterials, by: \.week)
                ForEach(grouped.keys.sorted().reversed(), id: \.self) { week in
                    Section("Week \(week)") {
                        ForEach(grouped[week] ?? []) { material in
                            NavigationLink(destination: StudyMaterialDetailView(material: material)) {
                                materialRow(material)
                            }
                        }
                        .onDelete { indexSet in
                            deleteMaterials(week: week, at: indexSet, from: grouped)
                        }
                    }
                }
            }
        }
        .navigationTitle("Study Materials")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingImport = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingImport) {
            NavigationStack {
                ImportStudyMaterialView()
            }
        }
    }

    private func materialRow(_ material: StudyMaterial) -> some View {
        HStack(spacing: 12) {
            materialIcon(material)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(material.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(MaterialCategory(rawValue: material.category)?.label ?? material.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: Capsule())
                    if !material.linkedChapterIDs.isEmpty {
                        Text(material.linkedChapterIDs.compactMap { content.chapter(id: $0)?.number }.map { "Ch.\($0)" }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(material.createdDate, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private func materialIcon(_ material: StudyMaterial) -> some View {
        switch material.materialType {
        case "photo":
            if let data = material.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "photo.fill")
                    .foregroundStyle(.blue)
            }
        case "pdf":
            Image(systemName: "doc.fill")
                .font(.title3)
                .foregroundStyle(.red)
        default:
            Image(systemName: "doc.text.fill")
                .font(.title3)
                .foregroundStyle(.green)
        }
    }

    private func filterChip(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(active ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? Color.blue : Color.gray.opacity(0.15), in: Capsule())
                .foregroundStyle(active ? .white : .primary)
        }
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteMaterials(week: Int, at offsets: IndexSet, from grouped: [Int: [StudyMaterial]]) {
        guard let weekMaterials = grouped[week] else { return }
        for index in offsets {
            modelContext.delete(weekMaterials[index])
        }
    }
}

// MARK: - Import View

struct ImportStudyMaterialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ContentService.self) private var content

    @State private var importType: ImportType = .photo
    @State private var title = ""
    @State private var category: MaterialCategory = .other
    @State private var selectedWeek = 1
    @State private var linkedChapters: Set<String> = []
    @State private var notes = ""

    // Photo
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImageData: Data?
    @State private var showCamera = false

    // PDF
    @State private var showFilePicker = false
    @State private var pdfData: Data?
    @State private var pdfFileName = ""

    // Text
    @State private var textContent = ""

    enum ImportType: String, CaseIterable {
        case photo = "Photo"
        case pdf = "PDF"
        case text = "Text"

        var icon: String {
            switch self {
            case .photo: return "camera.fill"
            case .pdf: return "doc.fill"
            case .text: return "doc.text.fill"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Import type selector
                HStack(spacing: 12) {
                    ForEach(ImportType.allCases, id: \.self) { type in
                        Button {
                            importType = type
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.title3)
                                Text(type.rawValue)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(importType == type ? Color.blue : Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(importType == type ? .white : .primary)
                        }
                    }
                }

                // Content input
                switch importType {
                case .photo:
                    photoInput
                case .pdf:
                    pdfInput
                case .text:
                    textInput
                }

                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Lab 3 Handout, Midterm 1 Review", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                // Category
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Category", selection: $category) {
                        ForEach(MaterialCategory.allCases, id: \.self) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Week
                Stepper("Week \(selectedWeek)", value: $selectedWeek, in: 1...12)

                // Link to chapters
                VStack(alignment: .leading, spacing: 8) {
                    Text("Related Chapters")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let weekChapters = chaptersForWeek(selectedWeek)
                    ForEach(content.chapters) { chapter in
                        Button {
                            if linkedChapters.contains(chapter.id) {
                                linkedChapters.remove(chapter.id)
                            } else {
                                linkedChapters.insert(chapter.id)
                            }
                        } label: {
                            HStack {
                                Image(systemName: linkedChapters.contains(chapter.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(linkedChapters.contains(chapter.id) ? .blue : .gray)
                                Text("Ch. \(chapter.number): \(chapter.title)")
                                    .font(.caption)
                                if weekChapters.contains(where: { $0.id == chapter.id }) {
                                    Text("this week")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Any notes about this material...", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                // Save
                Button {
                    saveMaterial()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Save Material")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSave ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(!canSave)
            }
            .padding()
        }
        .navigationTitle("Add Material")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    capturedImageData = data
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        pdfData = data
                        pdfFileName = url.lastPathComponent
                    }
                }
            case .failure:
                break
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $capturedImageData)
        }
        .onAppear {
            // Auto-select chapters for the current week
            let weekChs = chaptersForWeek(selectedWeek)
            linkedChapters = Set(weekChs.map(\.id))
        }
    }

    // MARK: - Photo Input

    private var photoInput: some View {
        VStack(spacing: 12) {
            if let data = capturedImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Remove") {
                    capturedImageData = nil
                    selectedPhotoItem = nil
                }
                .font(.caption)
                .foregroundStyle(.red)
            } else {
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            Text("Photo Library")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Take Photo")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .tint(.primary)
                }
            }
        }
    }

    // MARK: - PDF Input

    private var pdfInput: some View {
        VStack(spacing: 12) {
            if pdfData != nil {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.red)
                    Text(pdfFileName)
                        .font(.subheadline)
                    Spacer()
                    Button("Remove") {
                        pdfData = nil
                        pdfFileName = ""
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    showFilePicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                        Text("Select PDF")
                            .font(.subheadline)
                        Text("From Files, Canvas downloads, etc.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .tint(.primary)
            }
        }
    }

    // MARK: - Text Input

    private var textInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste or type assignment content")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $textContent)
                .frame(minHeight: 150)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        guard !title.isEmpty else { return false }
        switch importType {
        case .photo: return capturedImageData != nil
        case .pdf: return pdfData != nil
        case .text: return !textContent.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func chaptersForWeek(_ week: Int) -> [Chapter] {
        guard let syllabus = content.syllabus else { return [] }
        let lectureChapters = syllabus.lectureSchedule.first { $0.week == week }?.chapters ?? []
        let labChapters = syllabus.labSchedule.first { $0.week == week }?.chapters ?? []
        return content.chapters.filter { Set(lectureChapters + labChapters).contains($0.id) }
    }

    private func saveMaterial() {
        let material = StudyMaterial(
            title: title,
            materialType: importType.rawValue.lowercased(),
            textContent: importType == .text ? textContent : nil,
            imageData: importType == .photo ? capturedImageData : nil,
            pdfData: importType == .pdf ? pdfData : nil,
            linkedChapterIDs: Array(linkedChapters),
            week: selectedWeek,
            category: category.rawValue,
            notes: notes
        )
        modelContext.insert(material)
        dismiss()
    }
}

// MARK: - Material Detail View

struct StudyMaterialDetailView: View {
    let material: StudyMaterial
    @Environment(ContentService.self) private var content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(MaterialCategory(rawValue: material.category)?.label ?? material.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1), in: Capsule())
                        Text("Week \(material.week)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(material.createdDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(material.title)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // Content
                switch material.materialType {
                case "photo":
                    if let data = material.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                case "pdf":
                    if material.pdfData != nil {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.red)
                            Text("PDF Document")
                                .font(.subheadline)
                            Text("Tap to open in viewer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                default:
                    if let text = material.textContent, !text.isEmpty {
                        Text(text)
                            .font(.body)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Linked chapters
                if !material.linkedChapterIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Chapters")
                            .font(.headline)
                        ForEach(material.linkedChapterIDs, id: \.self) { chapterID in
                            if let chapter = content.chapter(id: chapterID) {
                                NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundStyle(.blue)
                                        Text("Ch. \(chapter.number): \(chapter.title)")
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Notes
                if !material.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(material.notes)
                            .font(.body)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle(material.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Camera View (UIKit wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Material Category

enum MaterialCategory: String, CaseIterable {
    case lectureSlides = "lectureSlides"
    case labHandout = "labHandout"
    case returnedExam = "returnedExam"
    case notes = "notes"
    case worksheet = "worksheet"
    case other = "other"

    var label: String {
        switch self {
        case .lectureSlides: return "Lecture Slides"
        case .labHandout: return "Lab Handout"
        case .returnedExam: return "Returned Exam"
        case .notes: return "Notes"
        case .worksheet: return "Worksheet"
        case .other: return "Other"
        }
    }
}
