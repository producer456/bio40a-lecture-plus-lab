import Foundation
import SwiftData

/// User-uploaded study material (photos, PDFs, text notes) linked to specific
/// chapters and weeks. Stored locally so users can review class handouts,
/// returned exams, and lecture slides alongside textbook content.
@Model
final class StudyMaterial {
    @Attribute(.unique) var id: UUID
    var title: String
    var materialType: String       // "photo", "pdf", "text"
    var textContent: String?       // for text type
    @Attribute(.externalStorage) var imageData: Data?  // for photo type
    @Attribute(.externalStorage) var pdfData: Data?    // for pdf type
    var linkedChapterIDs: [String] // which chapters this relates to
    var linkedSectionIDs: [String] // optional: specific sections
    var week: Int                  // syllabus week
    var category: String           // "lectureSlides", "labHandout", "returnedExam", "notes", "other"
    var tags: [String]             // user-defined tags
    var createdDate: Date
    var notes: String              // user notes about this material

    init(
        id: UUID = UUID(),
        title: String,
        materialType: String,
        textContent: String? = nil,
        imageData: Data? = nil,
        pdfData: Data? = nil,
        linkedChapterIDs: [String] = [],
        linkedSectionIDs: [String] = [],
        week: Int = 0,
        category: String = "other",
        tags: [String] = [],
        createdDate: Date = .now,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.materialType = materialType
        self.textContent = textContent
        self.imageData = imageData
        self.pdfData = pdfData
        self.linkedChapterIDs = linkedChapterIDs
        self.linkedSectionIDs = linkedSectionIDs
        self.week = week
        self.category = category
        self.tags = tags
        self.createdDate = createdDate
        self.notes = notes
    }
}
