import SwiftUI
import SwiftData

// MARK: - Diagram Exercise List (per chapter)

struct DiagramExerciseListView: View {
    let chapterID: String
    @Environment(ContentService.self) private var content

    private var exercises: [DiagramExercise] {
        DiagramDataStore.exercises.filter { $0.chapterID == chapterID }
    }

    var body: some View {
        if exercises.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No diagram exercises for this chapter yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            ForEach(exercises) { exercise in
                NavigationLink(destination: DiagramLabelingExerciseView(exercise: exercise)) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(exercise.labels.count) labels \u{2022} \(exercise.difficulty.capitalized)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Diagram Labeling Exercise

struct DiagramLabelingExerciseView: View {
    let exercise: DiagramExercise
    @Environment(\.modelContext) private var modelContext
    @AppStorage("userName") private var userName = ""

    @State private var placedLabels: [String: String] = [:]  // labelID -> userAnswer
    @State private var revealedLabels: Set<String> = []
    @State private var selectedLabelID: String? = nil
    @State private var showResults = false
    @State private var mode: LabelMode = .quiz

    enum LabelMode {
        case quiz      // tap points to identify
        case study     // all labels shown for learning
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode picker
            Picker("Mode", selection: $mode) {
                Text("Quiz Mode").tag(LabelMode.quiz)
                Text("Study Mode").tag(LabelMode.study)
            }
            .pickerStyle(.segmented)
            .padding()

            if showResults {
                resultsView
            } else {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Diagram with label points
                            diagramView(size: geo.size)

                            if mode == .quiz {
                                quizControls
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Diagram View

    private func diagramView(size: CGSize) -> some View {
        let imageWidth = min(size.width - 32, 600)
        let imageHeight = imageWidth * 0.75  // approximate aspect ratio

        return ZStack(alignment: .topLeading) {
            // Background image
            if let uiImage = UIImage(named: exercise.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth)
            } else {
                // Placeholder if image not found
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.1))
                    .frame(width: imageWidth, height: imageHeight)
                    .overlay {
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text(exercise.imageName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
            }

            // Label points
            ForEach(exercise.labels) { label in
                labelPoint(label, containerWidth: imageWidth, containerHeight: imageHeight)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func labelPoint(_ label: DiagramExercise.DiagramLabel, containerWidth: CGFloat, containerHeight: CGFloat) -> some View {
        let x = label.x * containerWidth
        let y = label.y * containerHeight

        let isRevealed = mode == .study || revealedLabels.contains(label.id)
        let isSelected = selectedLabelID == label.id
        let isCorrect = placedLabels[label.id]?.lowercased() == label.name.lowercased()
        let hasAnswer = placedLabels[label.id] != nil

        Button {
            if mode == .quiz {
                selectedLabelID = label.id
            }
        } label: {
            VStack(spacing: 2) {
                // Pin dot
                Circle()
                    .fill(pinColor(isRevealed: isRevealed, isCorrect: isCorrect, hasAnswer: hasAnswer, isSelected: isSelected))
                    .frame(width: isSelected ? 16 : 12, height: isSelected ? 16 : 12)
                    .shadow(color: .black.opacity(0.3), radius: 2)

                // Label text
                if isRevealed || (hasAnswer && showResults) {
                    Text(label.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (isCorrect || mode == .study) ? Color.green : Color.red,
                            in: Capsule()
                        )
                } else if hasAnswer {
                    Text(placedLabels[label.id] ?? "")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue, in: Capsule())
                } else if isSelected {
                    Text("?")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange, in: Capsule())
                }
            }
        }
        .position(x: x, y: y)
        .disabled(mode == .study)
    }

    private func pinColor(isRevealed: Bool, isCorrect: Bool, hasAnswer: Bool, isSelected: Bool) -> Color {
        if isRevealed { return .green }
        if showResults && hasAnswer { return isCorrect ? .green : .red }
        if hasAnswer { return .blue }
        if isSelected { return .orange }
        return .red
    }

    // MARK: - Quiz Controls

    private var quizControls: some View {
        VStack(spacing: 12) {
            if let selectedID = selectedLabelID {
                let label = exercise.labels.first { $0.id == selectedID }

                VStack(spacing: 8) {
                    Text("What structure is at this point?")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let hint = label?.hint, !hint.isEmpty {
                        Text("Hint: \(hint)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    // Answer options (show 4 choices including the correct one)
                    let options = generateOptions(for: label)
                    ForEach(options, id: \.self) { option in
                        Button {
                            placedLabels[selectedID] = option
                            // Move to next unanswered label
                            advanceToNext()
                        } label: {
                            Text(option)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(
                                    placedLabels[selectedID] == option ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                        }
                        .tint(.primary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            } else {
                Text("Tap a point on the diagram to identify it")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress
            let answered = placedLabels.count
            let total = exercise.labels.count
            HStack {
                Text("\(answered)/\(total) labeled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if answered == total {
                    Button("Check Answers") {
                        withAnimation { showResults = true }
                        recordPerformance()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)

            // Hint / Reveal button
            if let selectedID = selectedLabelID, !revealedLabels.contains(selectedID) {
                Button("Reveal This Label") {
                    revealedLabels.insert(selectedID)
                    let label = exercise.labels.first { $0.id == selectedID }
                    placedLabels[selectedID] = label?.name ?? ""
                    advanceToNext()
                }
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .padding()
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                let correct = exercise.labels.filter { placedLabels[$0.id]?.lowercased() == $0.name.lowercased() }.count
                let total = exercise.labels.count
                let revealed = revealedLabels.count

                Image(systemName: correct == total ? "star.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(correct == total ? .yellow : .green)

                Text(userName.isEmpty ? "Results" : "\(userName)'s Results")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(correct)/\(total) correct")
                    .font(.title3)

                if revealed > 0 {
                    Text("\(revealed) labels revealed (hints used)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                // Review each label
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review")
                        .font(.headline)

                    ForEach(exercise.labels) { label in
                        let userAnswer = placedLabels[label.id] ?? "Not answered"
                        let isCorrect = userAnswer.lowercased() == label.name.lowercased()
                        HStack {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isCorrect ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(label.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if !isCorrect {
                                    Text("You said: \(userAnswer)")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                Button("Try Again") {
                    placedLabels = [:]
                    revealedLabels = []
                    selectedLabelID = nil
                    showResults = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func generateOptions(for label: DiagramExercise.DiagramLabel?) -> [String] {
        guard let label else { return [] }
        var options = [label.name]
        // Add wrong options from other labels in this exercise
        let otherLabels = exercise.labels.filter { $0.id != label.id }.shuffled()
        for other in otherLabels.prefix(3) {
            options.append(other.name)
        }
        // If we still need more, add from other exercises in same chapter
        if options.count < 4 {
            let otherExercises = DiagramDataStore.exercises.filter { $0.chapterID == exercise.chapterID && $0.id != exercise.id }
            for ex in otherExercises {
                for l in ex.labels.shuffled() {
                    if options.count >= 4 { break }
                    if !options.contains(l.name) {
                        options.append(l.name)
                    }
                }
            }
        }
        return options.shuffled()
    }

    private func advanceToNext() {
        let unanswered = exercise.labels.filter { placedLabels[$0.id] == nil }
        selectedLabelID = unanswered.first?.id
    }

    private func recordPerformance() {
        for label in exercise.labels {
            let isCorrect = placedLabels[label.id]?.lowercased() == label.name.lowercased()
            let record = PerformanceRecord(
                questionID: "diagram_\(exercise.id)_\(label.id)",
                chapterID: exercise.chapterID,
                sectionID: exercise.sectionID ?? "",
                wasCorrect: isCorrect,
                quizType: "diagramLabeling"
            )
            modelContext.insert(record)
        }
    }
}

// MARK: - Diagram Data Store

/// Contains all diagram exercises with their label positions.
/// Label coordinates are relative (0-1) to the image dimensions.
struct DiagramDataStore {
    static let exercises: [DiagramExercise] = [
        // Chapter 1: Body Regions & Cavities
        DiagramExercise(
            id: "ch01_body_regions",
            title: "Body Regions (Anterior)",
            imageName: "diagram_body_regions",
            chapterID: "ch01",
            sectionID: "ch01_s06",
            labels: [
                .init(id: "cr1", name: "Cephalic", x: 0.50, y: 0.06, hint: "Head region"),
                .init(id: "cr2", name: "Cervical", x: 0.50, y: 0.13, hint: "Neck region"),
                .init(id: "cr3", name: "Thoracic", x: 0.50, y: 0.25, hint: "Chest region"),
                .init(id: "cr4", name: "Abdominal", x: 0.50, y: 0.38, hint: "Belly region"),
                .init(id: "cr5", name: "Pelvic", x: 0.50, y: 0.48, hint: "Hip region"),
                .init(id: "cr6", name: "Brachial", x: 0.25, y: 0.30, hint: "Upper arm"),
                .init(id: "cr7", name: "Antebrachial", x: 0.22, y: 0.42, hint: "Forearm"),
                .init(id: "cr8", name: "Femoral", x: 0.40, y: 0.60, hint: "Thigh region"),
                .init(id: "cr9", name: "Patellar", x: 0.42, y: 0.72, hint: "Knee region"),
                .init(id: "cr10", name: "Crural", x: 0.43, y: 0.82, hint: "Leg (below knee)"),
            ],
            difficulty: "beginner"
        ),

        // Chapter 3: Cell Structure
        DiagramExercise(
            id: "ch03_cell_structure",
            title: "Animal Cell and Organelles",
            imageName: "diagram_animal_cell",
            chapterID: "ch03",
            sectionID: "ch03_s01",
            labels: [
                .init(id: "cell1", name: "Nucleus", x: 0.50, y: 0.40, hint: "Contains DNA"),
                .init(id: "cell2", name: "Cell membrane", x: 0.90, y: 0.50, hint: "Outer boundary"),
                .init(id: "cell3", name: "Mitochondria", x: 0.30, y: 0.65, hint: "Powerhouse of the cell"),
                .init(id: "cell4", name: "Rough ER", x: 0.65, y: 0.30, hint: "Studded with ribosomes"),
                .init(id: "cell5", name: "Smooth ER", x: 0.70, y: 0.55, hint: "Lipid synthesis"),
                .init(id: "cell6", name: "Golgi apparatus", x: 0.35, y: 0.25, hint: "Packages proteins"),
                .init(id: "cell7", name: "Lysosome", x: 0.25, y: 0.45, hint: "Digests waste"),
                .init(id: "cell8", name: "Cytoplasm", x: 0.55, y: 0.70, hint: "Gel-like interior"),
            ],
            difficulty: "beginner"
        ),

        // Chapter 4: Tissue Types
        DiagramExercise(
            id: "ch04_epithelial",
            title: "Epithelial Tissue Types",
            imageName: "diagram_epithelial",
            chapterID: "ch04",
            sectionID: "ch04_s02",
            labels: [
                .init(id: "epi1", name: "Simple squamous", x: 0.20, y: 0.15, hint: "Single layer, flat cells"),
                .init(id: "epi2", name: "Simple cuboidal", x: 0.50, y: 0.15, hint: "Single layer, cube-shaped"),
                .init(id: "epi3", name: "Simple columnar", x: 0.80, y: 0.15, hint: "Single layer, tall cells"),
                .init(id: "epi4", name: "Stratified squamous", x: 0.20, y: 0.55, hint: "Multiple layers, flat on top"),
                .init(id: "epi5", name: "Pseudostratified columnar", x: 0.50, y: 0.55, hint: "Appears layered but isn't"),
                .init(id: "epi6", name: "Transitional", x: 0.80, y: 0.55, hint: "Stretchy, found in bladder"),
            ],
            difficulty: "intermediate"
        ),

        // Chapter 5: Skin Layers
        DiagramExercise(
            id: "ch05_skin_layers",
            title: "Layers of the Skin",
            imageName: "diagram_skin_layers",
            chapterID: "ch05",
            sectionID: "ch05_s01",
            labels: [
                .init(id: "skin1", name: "Epidermis", x: 0.50, y: 0.10, hint: "Outermost layer"),
                .init(id: "skin2", name: "Dermis", x: 0.50, y: 0.35, hint: "Middle layer with blood vessels"),
                .init(id: "skin3", name: "Hypodermis", x: 0.50, y: 0.70, hint: "Deepest layer, subcutaneous fat"),
                .init(id: "skin4", name: "Hair follicle", x: 0.30, y: 0.45, hint: "Where hair grows from"),
                .init(id: "skin5", name: "Sebaceous gland", x: 0.25, y: 0.30, hint: "Produces oil"),
                .init(id: "skin6", name: "Sweat gland", x: 0.70, y: 0.55, hint: "Produces sweat for cooling"),
                .init(id: "skin7", name: "Arrector pili muscle", x: 0.35, y: 0.35, hint: "Makes hair stand up"),
                .init(id: "skin8", name: "Sensory nerve", x: 0.65, y: 0.40, hint: "Detects touch/pressure"),
            ],
            difficulty: "intermediate"
        ),

        // Chapter 6: Bone Structure
        DiagramExercise(
            id: "ch06_long_bone",
            title: "Structure of a Long Bone",
            imageName: "diagram_long_bone",
            chapterID: "ch06",
            sectionID: "ch06_s03",
            labels: [
                .init(id: "bone1", name: "Epiphysis", x: 0.50, y: 0.08, hint: "End of the bone"),
                .init(id: "bone2", name: "Diaphysis", x: 0.50, y: 0.50, hint: "Shaft of the bone"),
                .init(id: "bone3", name: "Metaphysis", x: 0.50, y: 0.25, hint: "Between shaft and end"),
                .init(id: "bone4", name: "Articular cartilage", x: 0.50, y: 0.03, hint: "Covers joint surface"),
                .init(id: "bone5", name: "Periosteum", x: 0.70, y: 0.50, hint: "Outer membrane"),
                .init(id: "bone6", name: "Compact bone", x: 0.60, y: 0.45, hint: "Dense outer layer"),
                .init(id: "bone7", name: "Spongy bone", x: 0.45, y: 0.12, hint: "Porous interior at ends"),
                .init(id: "bone8", name: "Medullary cavity", x: 0.40, y: 0.50, hint: "Hollow center of shaft"),
                .init(id: "bone9", name: "Endosteum", x: 0.45, y: 0.55, hint: "Lines the medullary cavity"),
            ],
            difficulty: "intermediate"
        ),

        // Chapter 6: Osteon
        DiagramExercise(
            id: "ch06_osteon",
            title: "Structure of an Osteon",
            imageName: "diagram_osteon",
            chapterID: "ch06",
            sectionID: "ch06_s03",
            labels: [
                .init(id: "ost1", name: "Central canal", x: 0.50, y: 0.50, hint: "Contains blood vessels"),
                .init(id: "ost2", name: "Lamellae", x: 0.65, y: 0.35, hint: "Concentric rings of bone matrix"),
                .init(id: "ost3", name: "Lacunae", x: 0.55, y: 0.25, hint: "Small spaces holding osteocytes"),
                .init(id: "ost4", name: "Osteocytes", x: 0.60, y: 0.45, hint: "Mature bone cells"),
                .init(id: "ost5", name: "Canaliculi", x: 0.70, y: 0.55, hint: "Tiny channels connecting lacunae"),
                .init(id: "ost6", name: "Perforating canal", x: 0.30, y: 0.70, hint: "Connects central canals"),
            ],
            difficulty: "advanced"
        ),

        // Chapter 7: Skull
        DiagramExercise(
            id: "ch07_skull_lateral",
            title: "Skull (Lateral View)",
            imageName: "diagram_skull_lateral",
            chapterID: "ch07",
            sectionID: "ch07_s02",
            labels: [
                .init(id: "sk1", name: "Frontal bone", x: 0.35, y: 0.15, hint: "Forehead bone"),
                .init(id: "sk2", name: "Parietal bone", x: 0.55, y: 0.12, hint: "Top/side of skull"),
                .init(id: "sk3", name: "Temporal bone", x: 0.65, y: 0.35, hint: "Side of skull, near ear"),
                .init(id: "sk4", name: "Occipital bone", x: 0.80, y: 0.30, hint: "Back of skull"),
                .init(id: "sk5", name: "Sphenoid bone", x: 0.45, y: 0.40, hint: "Butterfly-shaped, behind eyes"),
                .init(id: "sk6", name: "Zygomatic bone", x: 0.40, y: 0.48, hint: "Cheekbone"),
                .init(id: "sk7", name: "Maxilla", x: 0.30, y: 0.60, hint: "Upper jaw"),
                .init(id: "sk8", name: "Mandible", x: 0.40, y: 0.75, hint: "Lower jaw"),
                .init(id: "sk9", name: "Nasal bone", x: 0.22, y: 0.45, hint: "Bridge of the nose"),
            ],
            difficulty: "intermediate"
        ),

        // Chapter 9: Synovial Joint
        DiagramExercise(
            id: "ch09_synovial_joint",
            title: "Structure of a Synovial Joint",
            imageName: "diagram_synovial_joint",
            chapterID: "ch09",
            sectionID: "ch09_s04",
            labels: [
                .init(id: "sj1", name: "Articular cartilage", x: 0.50, y: 0.20, hint: "Covers bone ends"),
                .init(id: "sj2", name: "Synovial membrane", x: 0.75, y: 0.40, hint: "Lines the joint capsule"),
                .init(id: "sj3", name: "Joint capsule", x: 0.80, y: 0.50, hint: "Encloses the joint"),
                .init(id: "sj4", name: "Synovial fluid", x: 0.50, y: 0.50, hint: "Lubricates the joint"),
                .init(id: "sj5", name: "Joint cavity", x: 0.45, y: 0.45, hint: "Space between bones"),
                .init(id: "sj6", name: "Periosteum", x: 0.25, y: 0.30, hint: "Bone covering outside joint"),
            ],
            difficulty: "beginner"
        ),

        // Chapter 10: Sarcomere
        DiagramExercise(
            id: "ch10_sarcomere",
            title: "Structure of a Sarcomere",
            imageName: "diagram_sarcomere",
            chapterID: "ch10",
            sectionID: "ch10_s02",
            labels: [
                .init(id: "sar1", name: "Z-disc", x: 0.10, y: 0.50, hint: "Boundary of the sarcomere"),
                .init(id: "sar2", name: "A-band", x: 0.50, y: 0.20, hint: "Dark band, full length of thick filaments"),
                .init(id: "sar3", name: "I-band", x: 0.15, y: 0.20, hint: "Light band, thin filaments only"),
                .init(id: "sar4", name: "H-zone", x: 0.50, y: 0.80, hint: "Center area, thick filaments only"),
                .init(id: "sar5", name: "M-line", x: 0.50, y: 0.50, hint: "Center of the sarcomere"),
                .init(id: "sar6", name: "Thick filament (myosin)", x: 0.50, y: 0.60, hint: "Protein that pulls thin filaments"),
                .init(id: "sar7", name: "Thin filament (actin)", x: 0.30, y: 0.40, hint: "Protein that slides during contraction"),
            ],
            difficulty: "advanced"
        ),

        // Chapter 11: Anterior Muscles
        DiagramExercise(
            id: "ch11_muscles_anterior",
            title: "Major Muscles (Anterior View)",
            imageName: "diagram_muscles_anterior",
            chapterID: "ch11",
            sectionID: "ch11_s01",
            labels: [
                .init(id: "ma1", name: "Deltoid", x: 0.25, y: 0.18, hint: "Shoulder muscle"),
                .init(id: "ma2", name: "Pectoralis major", x: 0.40, y: 0.22, hint: "Chest muscle"),
                .init(id: "ma3", name: "Biceps brachii", x: 0.22, y: 0.32, hint: "Front of upper arm"),
                .init(id: "ma4", name: "Rectus abdominis", x: 0.48, y: 0.40, hint: "\"Six-pack\" muscle"),
                .init(id: "ma5", name: "External oblique", x: 0.35, y: 0.38, hint: "Side of abdomen"),
                .init(id: "ma6", name: "Quadriceps femoris", x: 0.40, y: 0.58, hint: "Front of thigh"),
                .init(id: "ma7", name: "Tibialis anterior", x: 0.42, y: 0.78, hint: "Front of shin"),
                .init(id: "ma8", name: "Sternocleidomastoid", x: 0.42, y: 0.12, hint: "Side of neck"),
                .init(id: "ma9", name: "Trapezius", x: 0.55, y: 0.15, hint: "Upper back/neck"),
            ],
            difficulty: "intermediate"
        ),
    ]
}
