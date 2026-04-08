import Foundation
import SwiftData

@Model
final class UserBookmark {
    @Attribute(.unique) var id: UUID
    var chapterID: String
    var sectionID: String
    var createdDate: Date
    var note: String?

    init(
        id: UUID = UUID(),
        chapterID: String,
        sectionID: String,
        createdDate: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.chapterID = chapterID
        self.sectionID = sectionID
        self.createdDate = createdDate
        self.note = note
    }
}
