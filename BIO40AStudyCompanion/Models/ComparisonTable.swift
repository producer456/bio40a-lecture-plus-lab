import Foundation

// MARK: - Comparison Data Models

struct ComparisonSection: Codable, Identifiable, Hashable {
    let sectionID: String
    let sectionTitle: String
    let chapterGroup: String
    let tables: [ComparisonTable]

    var id: String { sectionID }
}

struct ComparisonTable: Codable, Identifiable, Hashable {
    let id: String
    let terms: [String]
    let unique: [[String]]
    let shared: [String]

    /// Short label for pill display, e.g. "Anabolism vs Catabolism"
    var pillLabel: String {
        terms.joined(separator: " vs ")
    }
}
