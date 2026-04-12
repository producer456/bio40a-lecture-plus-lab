import Foundation

// MARK: - Comparison Data Models

struct ComparisonSection: Codable, Identifiable, Hashable {
    let sectionID: String
    let sectionTitle: String
    let tables: [ComparisonTable]

    var id: String { sectionID }
}

struct ComparisonTable: Codable, Identifiable, Hashable {
    let id: String
    let terms: [String]
    let rows: [ComparisonRow]
}

struct ComparisonRow: Codable, Hashable {
    let feature: String
    let values: [String]
}
