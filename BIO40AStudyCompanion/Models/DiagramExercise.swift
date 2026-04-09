import Foundation

/// An interactive diagram labeling exercise.
/// Each exercise has an image and a set of label points that students must identify.
struct DiagramExercise: Codable, Identifiable {
    let id: String
    let title: String
    let imageName: String          // filename in app bundle
    let chapterID: String
    let sectionID: String?
    let labels: [DiagramLabel]
    let difficulty: String         // "beginner", "intermediate", "advanced"

    /// A single label point on a diagram
    struct DiagramLabel: Codable, Identifiable, Hashable {
        let id: String
        let name: String           // the correct label text
        let x: Double              // 0-1 relative position
        let y: Double              // 0-1 relative position
        let hint: String?          // optional hint for the student
    }
}
