import Foundation

struct GlossaryTerm: Codable, Hashable {
    let term: String
    let definition: String
    var chapterID: String?
    var sectionID: String?
}
