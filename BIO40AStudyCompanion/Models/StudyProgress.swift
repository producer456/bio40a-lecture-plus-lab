import Foundation
import SwiftData

@Model
final class StudyProgress {
    @Attribute(.unique) var compositeKey: String
    var chapterID: String
    var sectionID: String
    var readPercentage: Double
    var lastReadDate: Date

    init(chapterID: String, sectionID: String, readPercentage: Double = 0.0, lastReadDate: Date = .now) {
        self.compositeKey = "\(chapterID)_\(sectionID)"
        self.chapterID = chapterID
        self.sectionID = sectionID
        self.readPercentage = readPercentage
        self.lastReadDate = lastReadDate
    }
}
