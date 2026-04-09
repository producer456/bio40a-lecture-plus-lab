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
            // Background image – load from asset catalog using SwiftUI Image
            Image(exercise.imageName, bundle: nil)
                .resizable()
                .scaledToFit()
                .frame(width: imageWidth)
                .background {
                    // Placeholder shown underneath if the asset is missing
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

/// Contains all 33 diagram exercises with their label positions.
/// Label coordinates are relative (0-1) to the image dimensions.
struct DiagramDataStore {
    static let exercises: [DiagramExercise] = [

        // =====================================================================
        // CHAPTER 1: Introduction to the Human Body
        // =====================================================================

        // 1. Body Regions (Anterior)
        DiagramExercise(
            id: "ch01_body_regions",
            title: "Body Regions (Anterior View)",
            imageName: "Diagrams/diagram_body_regions",
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

        // 2. Body Planes
        DiagramExercise(
            id: "ch01_body_planes",
            title: "Anatomical Body Planes",
            imageName: "Diagrams/diagram_body_planes",
            chapterID: "ch01",
            sectionID: "ch01_s06",
            labels: [
                .init(id: "bp1", name: "Sagittal plane", x: 0.50, y: 0.30, hint: "Divides body into left and right"),
                .init(id: "bp2", name: "Frontal (coronal) plane", x: 0.75, y: 0.35, hint: "Divides body into anterior and posterior"),
                .init(id: "bp3", name: "Transverse plane", x: 0.50, y: 0.55, hint: "Divides body into superior and inferior"),
                .init(id: "bp4", name: "Superior", x: 0.50, y: 0.08, hint: "Toward the head"),
                .init(id: "bp5", name: "Inferior", x: 0.50, y: 0.92, hint: "Toward the feet"),
                .init(id: "bp6", name: "Anterior", x: 0.25, y: 0.50, hint: "Front of the body"),
                .init(id: "bp7", name: "Posterior", x: 0.78, y: 0.50, hint: "Back of the body"),
            ],
            difficulty: "beginner"
        ),

        // 3. Body Cavities
        DiagramExercise(
            id: "ch01_body_cavities",
            title: "Major Body Cavities",
            imageName: "Diagrams/diagram_body_cavities",
            chapterID: "ch01",
            sectionID: "ch01_s06",
            labels: [
                .init(id: "bc1", name: "Cranial cavity", x: 0.50, y: 0.08, hint: "Houses the brain"),
                .init(id: "bc2", name: "Spinal cavity", x: 0.60, y: 0.35, hint: "Contains the spinal cord"),
                .init(id: "bc3", name: "Thoracic cavity", x: 0.40, y: 0.28, hint: "Contains heart and lungs"),
                .init(id: "bc4", name: "Abdominal cavity", x: 0.38, y: 0.48, hint: "Contains digestive organs"),
                .init(id: "bc5", name: "Pelvic cavity", x: 0.42, y: 0.62, hint: "Contains bladder and reproductive organs"),
                .init(id: "bc6", name: "Diaphragm", x: 0.45, y: 0.38, hint: "Muscle separating thoracic and abdominal cavities"),
                .init(id: "bc7", name: "Mediastinum", x: 0.48, y: 0.25, hint: "Central compartment of thorax"),
            ],
            difficulty: "beginner"
        ),

        // =====================================================================
        // CHAPTER 2: Chemistry of Life
        // =====================================================================

        // 4. Atomic Structure
        DiagramExercise(
            id: "ch02_atomic_structure",
            title: "Structure of an Atom",
            imageName: "Diagrams/diagram_atomic_structure",
            chapterID: "ch02",
            sectionID: "ch02_s01",
            labels: [
                .init(id: "at1", name: "Proton", x: 0.48, y: 0.45, hint: "Positive charge, in nucleus"),
                .init(id: "at2", name: "Neutron", x: 0.55, y: 0.52, hint: "No charge, in nucleus"),
                .init(id: "at3", name: "Electron", x: 0.82, y: 0.30, hint: "Negative charge, orbits nucleus"),
                .init(id: "at4", name: "Nucleus", x: 0.50, y: 0.50, hint: "Center of the atom"),
                .init(id: "at5", name: "Electron shell", x: 0.75, y: 0.55, hint: "Energy level where electrons travel"),
            ],
            difficulty: "beginner"
        ),

        // 5. Electron Shells
        DiagramExercise(
            id: "ch02_electron_shells",
            title: "Electron Shell Configuration",
            imageName: "Diagrams/diagram_electron_shells",
            chapterID: "ch02",
            sectionID: "ch02_s01",
            labels: [
                .init(id: "es1", name: "First shell (K)", x: 0.50, y: 0.38, hint: "Holds up to 2 electrons"),
                .init(id: "es2", name: "Second shell (L)", x: 0.50, y: 0.25, hint: "Holds up to 8 electrons"),
                .init(id: "es3", name: "Third shell (M)", x: 0.50, y: 0.12, hint: "Holds up to 18 electrons"),
                .init(id: "es4", name: "Nucleus", x: 0.50, y: 0.50, hint: "Contains protons and neutrons"),
                .init(id: "es5", name: "Valence electrons", x: 0.82, y: 0.15, hint: "Electrons in the outermost shell"),
            ],
            difficulty: "beginner"
        ),

        // 6. Ionic Bonding
        DiagramExercise(
            id: "ch02_ionic_bonding",
            title: "Ionic Bonding (NaCl)",
            imageName: "Diagrams/diagram_ionic_bonding",
            chapterID: "ch02",
            sectionID: "ch02_s01",
            labels: [
                .init(id: "ib1", name: "Sodium atom (Na)", x: 0.22, y: 0.40, hint: "Loses one electron"),
                .init(id: "ib2", name: "Chlorine atom (Cl)", x: 0.78, y: 0.40, hint: "Gains one electron"),
                .init(id: "ib3", name: "Sodium ion (Na+)", x: 0.22, y: 0.75, hint: "Positive cation after electron loss"),
                .init(id: "ib4", name: "Chloride ion (Cl-)", x: 0.78, y: 0.75, hint: "Negative anion after electron gain"),
                .init(id: "ib5", name: "Electron transfer", x: 0.50, y: 0.40, hint: "Movement of electron from Na to Cl"),
                .init(id: "ib6", name: "Ionic bond", x: 0.50, y: 0.75, hint: "Electrostatic attraction between ions"),
            ],
            difficulty: "intermediate"
        ),

        // =====================================================================
        // CHAPTER 3: Cell Biology
        // =====================================================================

        // 7. Animal Cell
        DiagramExercise(
            id: "ch03_animal_cell",
            title: "Animal Cell and Organelles",
            imageName: "Diagrams/diagram_animal_cell",
            chapterID: "ch03",
            sectionID: "ch03_s01",
            labels: [
                .init(id: "cell1", name: "Nucleus", x: 0.50, y: 0.40, hint: "Contains DNA"),
                .init(id: "cell2", name: "Cell membrane", x: 0.90, y: 0.50, hint: "Outer boundary of the cell"),
                .init(id: "cell3", name: "Mitochondria", x: 0.30, y: 0.65, hint: "Powerhouse of the cell"),
                .init(id: "cell4", name: "Rough ER", x: 0.65, y: 0.30, hint: "Studded with ribosomes"),
                .init(id: "cell5", name: "Smooth ER", x: 0.70, y: 0.55, hint: "Lipid synthesis"),
                .init(id: "cell6", name: "Golgi apparatus", x: 0.35, y: 0.25, hint: "Packages and ships proteins"),
                .init(id: "cell7", name: "Lysosome", x: 0.25, y: 0.45, hint: "Digests cellular waste"),
                .init(id: "cell8", name: "Cytoplasm", x: 0.55, y: 0.70, hint: "Gel-like interior fluid"),
            ],
            difficulty: "beginner"
        ),

        // 8. Cell Membrane
        DiagramExercise(
            id: "ch03_cell_membrane",
            title: "Cell Membrane (Fluid Mosaic Model)",
            imageName: "Diagrams/diagram_cell_membrane",
            chapterID: "ch03",
            sectionID: "ch03_s01",
            labels: [
                .init(id: "cm1", name: "Phospholipid bilayer", x: 0.50, y: 0.50, hint: "Two layers of phospholipids"),
                .init(id: "cm2", name: "Integral protein", x: 0.35, y: 0.50, hint: "Spans the entire membrane"),
                .init(id: "cm3", name: "Peripheral protein", x: 0.70, y: 0.25, hint: "Attached to membrane surface"),
                .init(id: "cm4", name: "Cholesterol", x: 0.60, y: 0.55, hint: "Stabilizes membrane fluidity"),
                .init(id: "cm5", name: "Glycoprotein", x: 0.30, y: 0.18, hint: "Protein with carbohydrate chain"),
                .init(id: "cm6", name: "Hydrophilic head", x: 0.80, y: 0.28, hint: "Water-loving phospholipid end"),
                .init(id: "cm7", name: "Hydrophobic tail", x: 0.80, y: 0.50, hint: "Water-fearing fatty acid chains"),
                .init(id: "cm8", name: "Channel protein", x: 0.18, y: 0.45, hint: "Allows specific molecules to pass"),
            ],
            difficulty: "intermediate"
        ),

        // 9. Mitosis
        DiagramExercise(
            id: "ch03_mitosis",
            title: "Stages of Mitosis",
            imageName: "Diagrams/diagram_mitosis",
            chapterID: "ch03",
            sectionID: "ch03_s05",
            labels: [
                .init(id: "mit1", name: "Interphase", x: 0.12, y: 0.20, hint: "Cell prepares for division, DNA replicates"),
                .init(id: "mit2", name: "Prophase", x: 0.38, y: 0.20, hint: "Chromosomes condense, spindle forms"),
                .init(id: "mit3", name: "Metaphase", x: 0.62, y: 0.20, hint: "Chromosomes line up at cell equator"),
                .init(id: "mit4", name: "Anaphase", x: 0.88, y: 0.20, hint: "Sister chromatids pull apart"),
                .init(id: "mit5", name: "Telophase", x: 0.38, y: 0.75, hint: "Nuclear envelopes reform"),
                .init(id: "mit6", name: "Cytokinesis", x: 0.62, y: 0.75, hint: "Cytoplasm divides into two cells"),
                .init(id: "mit7", name: "Spindle fibers", x: 0.75, y: 0.35, hint: "Pull chromosomes apart"),
            ],
            difficulty: "intermediate"
        ),

        // =====================================================================
        // CHAPTER 4: Tissues
        // =====================================================================

        // 10. Epithelial Tissue Types
        DiagramExercise(
            id: "ch04_epithelial",
            title: "Epithelial Tissue Types",
            imageName: "Diagrams/diagram_epithelial",
            chapterID: "ch04",
            sectionID: "ch04_s02",
            labels: [
                .init(id: "epi1", name: "Simple squamous", x: 0.20, y: 0.15, hint: "Single layer, flat cells"),
                .init(id: "epi2", name: "Simple cuboidal", x: 0.50, y: 0.15, hint: "Single layer, cube-shaped"),
                .init(id: "epi3", name: "Simple columnar", x: 0.80, y: 0.15, hint: "Single layer, tall cells"),
                .init(id: "epi4", name: "Stratified squamous", x: 0.20, y: 0.55, hint: "Multiple layers, flat on top"),
                .init(id: "epi5", name: "Pseudostratified columnar", x: 0.50, y: 0.55, hint: "Appears layered but is single layer"),
                .init(id: "epi6", name: "Transitional", x: 0.80, y: 0.55, hint: "Stretchy, found in bladder"),
            ],
            difficulty: "intermediate"
        ),

        // 11. Connective Tissue
        DiagramExercise(
            id: "ch04_connective_tissue",
            title: "Connective Tissue Types",
            imageName: "Diagrams/diagram_connective_tissue",
            chapterID: "ch04",
            sectionID: "ch04_s03",
            labels: [
                .init(id: "ct1", name: "Areolar", x: 0.18, y: 0.18, hint: "Loose CT; cushions and supports"),
                .init(id: "ct2", name: "Adipose", x: 0.50, y: 0.18, hint: "Fat storage tissue"),
                .init(id: "ct3", name: "Dense regular", x: 0.82, y: 0.18, hint: "Parallel collagen fibers; tendons"),
                .init(id: "ct4", name: "Hyaline cartilage", x: 0.18, y: 0.55, hint: "Smooth, glassy cartilage at joints"),
                .init(id: "ct5", name: "Bone (osseous)", x: 0.50, y: 0.55, hint: "Hard mineralized connective tissue"),
                .init(id: "ct6", name: "Blood", x: 0.82, y: 0.55, hint: "Liquid connective tissue"),
                .init(id: "ct7", name: "Collagen fibers", x: 0.18, y: 0.35, hint: "Strong protein fibers in CT"),
            ],
            difficulty: "intermediate"
        ),

        // 12. Muscle Types
        DiagramExercise(
            id: "ch04_muscle_types",
            title: "Three Types of Muscle Tissue",
            imageName: "Diagrams/diagram_muscle_types",
            chapterID: "ch04",
            sectionID: "ch04_s04",
            labels: [
                .init(id: "mt1", name: "Skeletal muscle", x: 0.18, y: 0.35, hint: "Voluntary, striated, multinucleated"),
                .init(id: "mt2", name: "Cardiac muscle", x: 0.50, y: 0.35, hint: "Involuntary, striated, branched"),
                .init(id: "mt3", name: "Smooth muscle", x: 0.82, y: 0.35, hint: "Involuntary, non-striated, spindle-shaped"),
                .init(id: "mt4", name: "Striations", x: 0.18, y: 0.55, hint: "Visible bands in skeletal and cardiac muscle"),
                .init(id: "mt5", name: "Intercalated discs", x: 0.50, y: 0.55, hint: "Junctions unique to cardiac muscle"),
                .init(id: "mt6", name: "Nucleus", x: 0.82, y: 0.55, hint: "Single central nucleus in smooth muscle"),
            ],
            difficulty: "beginner"
        ),

        // =====================================================================
        // CHAPTER 5: Integumentary System
        // =====================================================================

        // 13. Skin Layers
        DiagramExercise(
            id: "ch05_skin_layers",
            title: "Layers of the Skin",
            imageName: "Diagrams/diagram_skin_layers",
            chapterID: "ch05",
            sectionID: "ch05_s01",
            labels: [
                .init(id: "skin1", name: "Epidermis", x: 0.50, y: 0.10, hint: "Outermost protective layer"),
                .init(id: "skin2", name: "Dermis", x: 0.50, y: 0.35, hint: "Middle layer with blood vessels"),
                .init(id: "skin3", name: "Hypodermis", x: 0.50, y: 0.70, hint: "Deepest layer, subcutaneous fat"),
                .init(id: "skin4", name: "Hair follicle", x: 0.30, y: 0.45, hint: "Where hair grows from"),
                .init(id: "skin5", name: "Sebaceous gland", x: 0.25, y: 0.30, hint: "Produces oil (sebum)"),
                .init(id: "skin6", name: "Sweat gland", x: 0.70, y: 0.55, hint: "Produces sweat for thermoregulation"),
                .init(id: "skin7", name: "Arrector pili muscle", x: 0.35, y: 0.35, hint: "Makes hair stand up (goosebumps)"),
                .init(id: "skin8", name: "Sensory nerve", x: 0.65, y: 0.40, hint: "Detects touch, pressure, pain"),
            ],
            difficulty: "intermediate"
        ),

        // 14. Epidermis Layers
        DiagramExercise(
            id: "ch05_epidermis",
            title: "Layers of the Epidermis",
            imageName: "Diagrams/diagram_epidermis",
            chapterID: "ch05",
            sectionID: "ch05_s01",
            labels: [
                .init(id: "epd1", name: "Stratum corneum", x: 0.50, y: 0.08, hint: "Outermost layer of dead keratinized cells"),
                .init(id: "epd2", name: "Stratum lucidum", x: 0.50, y: 0.22, hint: "Clear layer found in thick skin"),
                .init(id: "epd3", name: "Stratum granulosum", x: 0.50, y: 0.36, hint: "Granular layer, cells begin to die"),
                .init(id: "epd4", name: "Stratum spinosum", x: 0.50, y: 0.52, hint: "Spiny layer with keratinocytes"),
                .init(id: "epd5", name: "Stratum basale", x: 0.50, y: 0.68, hint: "Deepest layer, stem cells divide here"),
                .init(id: "epd6", name: "Melanocyte", x: 0.30, y: 0.72, hint: "Produces melanin pigment"),
                .init(id: "epd7", name: "Basement membrane", x: 0.50, y: 0.82, hint: "Anchors epidermis to dermis"),
                .init(id: "epd8", name: "Dermis", x: 0.50, y: 0.92, hint: "Layer beneath the epidermis"),
            ],
            difficulty: "advanced"
        ),

        // 15. Nail Structure
        DiagramExercise(
            id: "ch05_nail",
            title: "Structure of a Fingernail",
            imageName: "Diagrams/diagram_nail",
            chapterID: "ch05",
            sectionID: "ch05_s02",
            labels: [
                .init(id: "nail1", name: "Nail plate", x: 0.50, y: 0.35, hint: "Visible hard part of the nail"),
                .init(id: "nail2", name: "Nail bed", x: 0.50, y: 0.55, hint: "Skin beneath the nail plate"),
                .init(id: "nail3", name: "Nail root", x: 0.15, y: 0.45, hint: "Proximal hidden portion of nail"),
                .init(id: "nail4", name: "Lunula", x: 0.28, y: 0.35, hint: "White crescent at nail base"),
                .init(id: "nail5", name: "Cuticle (eponychium)", x: 0.20, y: 0.25, hint: "Skin fold covering nail root"),
                .init(id: "nail6", name: "Free edge", x: 0.85, y: 0.35, hint: "Distal end that extends past the finger"),
                .init(id: "nail7", name: "Nail matrix", x: 0.15, y: 0.55, hint: "Growth zone that produces the nail"),
            ],
            difficulty: "intermediate"
        ),

        // =====================================================================
        // CHAPTER 6: Bone Tissue
        // =====================================================================

        // 16. Long Bone Structure
        DiagramExercise(
            id: "ch06_long_bone",
            title: "Structure of a Long Bone",
            imageName: "Diagrams/diagram_long_bone",
            chapterID: "ch06",
            sectionID: "ch06_s03",
            labels: [
                .init(id: "bone1", name: "Epiphysis", x: 0.50, y: 0.08, hint: "Expanded end of the bone"),
                .init(id: "bone2", name: "Diaphysis", x: 0.50, y: 0.50, hint: "Shaft of the bone"),
                .init(id: "bone3", name: "Metaphysis", x: 0.50, y: 0.25, hint: "Region between shaft and end"),
                .init(id: "bone4", name: "Articular cartilage", x: 0.50, y: 0.03, hint: "Covers joint surface"),
                .init(id: "bone5", name: "Periosteum", x: 0.70, y: 0.50, hint: "Outer fibrous membrane"),
                .init(id: "bone6", name: "Compact bone", x: 0.60, y: 0.45, hint: "Dense outer bone layer"),
                .init(id: "bone7", name: "Spongy bone", x: 0.45, y: 0.12, hint: "Porous bone at the ends"),
                .init(id: "bone8", name: "Medullary cavity", x: 0.40, y: 0.50, hint: "Hollow center of the shaft"),
                .init(id: "bone9", name: "Endosteum", x: 0.45, y: 0.55, hint: "Thin membrane lining the cavity"),
            ],
            difficulty: "intermediate"
        ),

        // 17. Osteon (Haversian System)
        DiagramExercise(
            id: "ch06_osteon",
            title: "Structure of an Osteon",
            imageName: "Diagrams/diagram_osteon",
            chapterID: "ch06",
            sectionID: "ch06_s03",
            labels: [
                .init(id: "ost1", name: "Central (Haversian) canal", x: 0.50, y: 0.50, hint: "Contains blood vessels and nerves"),
                .init(id: "ost2", name: "Lamellae", x: 0.65, y: 0.35, hint: "Concentric rings of bone matrix"),
                .init(id: "ost3", name: "Lacunae", x: 0.55, y: 0.25, hint: "Small cavities holding osteocytes"),
                .init(id: "ost4", name: "Osteocytes", x: 0.60, y: 0.45, hint: "Mature bone cells in lacunae"),
                .init(id: "ost5", name: "Canaliculi", x: 0.70, y: 0.55, hint: "Tiny channels connecting lacunae"),
                .init(id: "ost6", name: "Perforating (Volkmann's) canal", x: 0.30, y: 0.70, hint: "Connects adjacent central canals"),
            ],
            difficulty: "advanced"
        ),

        // 18. Spongy Bone
        DiagramExercise(
            id: "ch06_spongy_bone",
            title: "Spongy Bone Structure",
            imageName: "Diagrams/diagram_spongy_bone",
            chapterID: "ch06",
            sectionID: "ch06_s03",
            labels: [
                .init(id: "sb1", name: "Trabeculae", x: 0.45, y: 0.40, hint: "Branching bony spicules"),
                .init(id: "sb2", name: "Red bone marrow", x: 0.55, y: 0.55, hint: "Produces blood cells"),
                .init(id: "sb3", name: "Osteocytes", x: 0.35, y: 0.30, hint: "Bone cells within trabeculae"),
                .init(id: "sb4", name: "Osteoblasts", x: 0.65, y: 0.45, hint: "Bone-forming cells on surface"),
                .init(id: "sb5", name: "Osteoclasts", x: 0.40, y: 0.65, hint: "Bone-resorbing cells"),
                .init(id: "sb6", name: "Periosteum", x: 0.85, y: 0.20, hint: "Outer membrane covering bone"),
            ],
            difficulty: "advanced"
        ),

        // =====================================================================
        // CHAPTER 7: Axial Skeleton
        // =====================================================================

        // 19. Skull Anterior View
        DiagramExercise(
            id: "ch07_skull_anterior",
            title: "Skull (Anterior View)",
            imageName: "Diagrams/diagram_skull_anterior",
            chapterID: "ch07",
            sectionID: "ch07_s02",
            labels: [
                .init(id: "ska1", name: "Frontal bone", x: 0.50, y: 0.12, hint: "Forms the forehead"),
                .init(id: "ska2", name: "Nasal bone", x: 0.50, y: 0.38, hint: "Bridge of the nose"),
                .init(id: "ska3", name: "Zygomatic bone", x: 0.28, y: 0.45, hint: "Cheekbone"),
                .init(id: "ska4", name: "Maxilla", x: 0.42, y: 0.58, hint: "Upper jawbone"),
                .init(id: "ska5", name: "Mandible", x: 0.50, y: 0.78, hint: "Lower jawbone, only movable skull bone"),
                .init(id: "ska6", name: "Orbit", x: 0.35, y: 0.35, hint: "Eye socket"),
                .init(id: "ska7", name: "Supraorbital foramen", x: 0.40, y: 0.28, hint: "Opening above the orbit"),
                .init(id: "ska8", name: "Infraorbital foramen", x: 0.38, y: 0.50, hint: "Opening below the orbit"),
                .init(id: "ska9", name: "Mental foramen", x: 0.40, y: 0.72, hint: "Opening on the mandible"),
            ],
            difficulty: "intermediate"
        ),

        // 20. Skull Lateral View
        DiagramExercise(
            id: "ch07_skull_lateral",
            title: "Skull (Lateral View)",
            imageName: "Diagrams/diagram_skull_lateral",
            chapterID: "ch07",
            sectionID: "ch07_s02",
            labels: [
                .init(id: "sk1", name: "Frontal bone", x: 0.35, y: 0.15, hint: "Forehead bone"),
                .init(id: "sk2", name: "Parietal bone", x: 0.55, y: 0.12, hint: "Top and side of skull"),
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

        // 21. Vertebral Column
        DiagramExercise(
            id: "ch07_vertebral_column",
            title: "Vertebral Column Regions",
            imageName: "Diagrams/diagram_vertebral_column",
            chapterID: "ch07",
            sectionID: "ch07_s03",
            labels: [
                .init(id: "vc1", name: "Cervical vertebrae (C1-C7)", x: 0.45, y: 0.10, hint: "7 neck vertebrae"),
                .init(id: "vc2", name: "Thoracic vertebrae (T1-T12)", x: 0.55, y: 0.32, hint: "12 vertebrae articulating with ribs"),
                .init(id: "vc3", name: "Lumbar vertebrae (L1-L5)", x: 0.45, y: 0.55, hint: "5 large lower-back vertebrae"),
                .init(id: "vc4", name: "Sacrum", x: 0.50, y: 0.72, hint: "5 fused vertebrae forming posterior pelvis"),
                .init(id: "vc5", name: "Coccyx", x: 0.50, y: 0.85, hint: "Tailbone, 3-5 fused vertebrae"),
                .init(id: "vc6", name: "Intervertebral disc", x: 0.65, y: 0.45, hint: "Fibrocartilage pad between vertebrae"),
                .init(id: "vc7", name: "Cervical curvature", x: 0.32, y: 0.10, hint: "Lordotic (concave posterior) curve"),
                .init(id: "vc8", name: "Thoracic curvature", x: 0.68, y: 0.32, hint: "Kyphotic (convex posterior) curve"),
            ],
            difficulty: "intermediate"
        ),

        // =====================================================================
        // CHAPTER 8: Appendicular Skeleton
        // =====================================================================

        // 22. Humerus
        DiagramExercise(
            id: "ch08_humerus",
            title: "Anatomy of the Humerus",
            imageName: "Diagrams/diagram_humerus",
            chapterID: "ch08",
            sectionID: "ch08_s02",
            labels: [
                .init(id: "hum1", name: "Head", x: 0.40, y: 0.08, hint: "Rounded proximal end, articulates with scapula"),
                .init(id: "hum2", name: "Greater tubercle", x: 0.58, y: 0.10, hint: "Lateral projection for rotator cuff"),
                .init(id: "hum3", name: "Lesser tubercle", x: 0.35, y: 0.14, hint: "Anterior projection for subscapularis"),
                .init(id: "hum4", name: "Deltoid tuberosity", x: 0.55, y: 0.38, hint: "Lateral roughening for deltoid attachment"),
                .init(id: "hum5", name: "Medial epicondyle", x: 0.38, y: 0.85, hint: "Medial projection at elbow"),
                .init(id: "hum6", name: "Lateral epicondyle", x: 0.62, y: 0.85, hint: "Lateral projection at elbow"),
                .init(id: "hum7", name: "Trochlea", x: 0.42, y: 0.92, hint: "Spool-shaped surface for ulna"),
                .init(id: "hum8", name: "Capitulum", x: 0.58, y: 0.92, hint: "Rounded surface for radius"),
            ],
            difficulty: "advanced"
        ),

        // 23. Femur
        DiagramExercise(
            id: "ch08_femur",
            title: "Anatomy of the Femur",
            imageName: "Diagrams/diagram_femur",
            chapterID: "ch08",
            sectionID: "ch08_s03",
            labels: [
                .init(id: "fem1", name: "Head", x: 0.35, y: 0.06, hint: "Rounded end that fits into acetabulum"),
                .init(id: "fem2", name: "Neck", x: 0.40, y: 0.12, hint: "Narrowed region below head"),
                .init(id: "fem3", name: "Greater trochanter", x: 0.60, y: 0.10, hint: "Large lateral projection for gluteal muscles"),
                .init(id: "fem4", name: "Lesser trochanter", x: 0.42, y: 0.18, hint: "Smaller medial projection for iliopsoas"),
                .init(id: "fem5", name: "Shaft", x: 0.50, y: 0.50, hint: "Long cylindrical body of bone"),
                .init(id: "fem6", name: "Medial condyle", x: 0.40, y: 0.92, hint: "Medial distal articular surface"),
                .init(id: "fem7", name: "Lateral condyle", x: 0.60, y: 0.92, hint: "Lateral distal articular surface"),
                .init(id: "fem8", name: "Linea aspera", x: 0.55, y: 0.45, hint: "Posterior ridge for muscle attachment"),
            ],
            difficulty: "advanced"
        ),

        // 24. Pelvis
        DiagramExercise(
            id: "ch08_pelvis",
            title: "Anatomy of the Pelvis",
            imageName: "Diagrams/diagram_pelvis",
            chapterID: "ch08",
            sectionID: "ch08_s03",
            labels: [
                .init(id: "pel1", name: "Ilium", x: 0.30, y: 0.18, hint: "Large fan-shaped superior portion"),
                .init(id: "pel2", name: "Ischium", x: 0.28, y: 0.72, hint: "Posterior-inferior portion; sit bone"),
                .init(id: "pel3", name: "Pubis", x: 0.38, y: 0.60, hint: "Anterior-inferior portion"),
                .init(id: "pel4", name: "Acetabulum", x: 0.30, y: 0.48, hint: "Hip socket for femoral head"),
                .init(id: "pel5", name: "Sacrum", x: 0.50, y: 0.30, hint: "Fused vertebrae between hip bones"),
                .init(id: "pel6", name: "Pubic symphysis", x: 0.50, y: 0.62, hint: "Cartilaginous joint between pubic bones"),
                .init(id: "pel7", name: "Iliac crest", x: 0.30, y: 0.10, hint: "Superior border of ilium"),
                .init(id: "pel8", name: "Obturator foramen", x: 0.32, y: 0.62, hint: "Large opening in hip bone"),
            ],
            difficulty: "advanced"
        ),

        // =====================================================================
        // CHAPTER 9: Joints
        // =====================================================================

        // 25. Synovial Joint
        DiagramExercise(
            id: "ch09_synovial_joint",
            title: "Structure of a Synovial Joint",
            imageName: "Diagrams/diagram_synovial_joint",
            chapterID: "ch09",
            sectionID: "ch09_s04",
            labels: [
                .init(id: "sj1", name: "Articular cartilage", x: 0.50, y: 0.20, hint: "Hyaline cartilage covering bone ends"),
                .init(id: "sj2", name: "Synovial membrane", x: 0.75, y: 0.40, hint: "Lines the joint capsule, secretes fluid"),
                .init(id: "sj3", name: "Joint capsule", x: 0.80, y: 0.50, hint: "Fibrous capsule enclosing the joint"),
                .init(id: "sj4", name: "Synovial fluid", x: 0.50, y: 0.50, hint: "Lubricating fluid in the joint cavity"),
                .init(id: "sj5", name: "Joint cavity", x: 0.45, y: 0.45, hint: "Space between articulating bones"),
                .init(id: "sj6", name: "Periosteum", x: 0.25, y: 0.30, hint: "Bone membrane outside the joint"),
            ],
            difficulty: "beginner"
        ),

        // 26. Joint Types
        DiagramExercise(
            id: "ch09_joint_types",
            title: "Types of Synovial Joints",
            imageName: "Diagrams/diagram_joint_types",
            chapterID: "ch09",
            sectionID: "ch09_s04",
            labels: [
                .init(id: "jt1", name: "Pivot joint", x: 0.18, y: 0.20, hint: "Rotation around a single axis (atlas/axis)"),
                .init(id: "jt2", name: "Hinge joint", x: 0.50, y: 0.20, hint: "Flexion/extension only (elbow, knee)"),
                .init(id: "jt3", name: "Saddle joint", x: 0.82, y: 0.20, hint: "Biaxial movement (thumb CMC)"),
                .init(id: "jt4", name: "Ball-and-socket joint", x: 0.18, y: 0.65, hint: "Multiaxial movement (shoulder, hip)"),
                .init(id: "jt5", name: "Condyloid joint", x: 0.50, y: 0.65, hint: "Biaxial oval surfaces (wrist)"),
                .init(id: "jt6", name: "Gliding (plane) joint", x: 0.82, y: 0.65, hint: "Flat surfaces slide (intercarpal)"),
            ],
            difficulty: "beginner"
        ),

        // 27. Knee Joint
        DiagramExercise(
            id: "ch09_knee",
            title: "Anatomy of the Knee Joint",
            imageName: "Diagrams/diagram_knee",
            chapterID: "ch09",
            sectionID: "ch09_s04",
            labels: [
                .init(id: "kn1", name: "Femur", x: 0.50, y: 0.10, hint: "Thigh bone"),
                .init(id: "kn2", name: "Tibia", x: 0.42, y: 0.85, hint: "Shin bone"),
                .init(id: "kn3", name: "Patella", x: 0.42, y: 0.42, hint: "Kneecap"),
                .init(id: "kn4", name: "Anterior cruciate ligament", x: 0.48, y: 0.55, hint: "ACL - prevents anterior tibial displacement"),
                .init(id: "kn5", name: "Posterior cruciate ligament", x: 0.55, y: 0.55, hint: "PCL - prevents posterior tibial displacement"),
                .init(id: "kn6", name: "Medial meniscus", x: 0.38, y: 0.62, hint: "C-shaped cartilage pad, medial side"),
                .init(id: "kn7", name: "Lateral meniscus", x: 0.58, y: 0.62, hint: "O-shaped cartilage pad, lateral side"),
                .init(id: "kn8", name: "Patellar ligament", x: 0.38, y: 0.48, hint: "Connects patella to tibia"),
            ],
            difficulty: "advanced"
        ),

        // =====================================================================
        // CHAPTER 10: Muscle Tissue
        // =====================================================================

        // 28. Muscle Fiber
        DiagramExercise(
            id: "ch10_muscle_fiber",
            title: "Skeletal Muscle Fiber Structure",
            imageName: "Diagrams/diagram_muscle_fiber",
            chapterID: "ch10",
            sectionID: "ch10_s02",
            labels: [
                .init(id: "mf1", name: "Sarcolemma", x: 0.85, y: 0.50, hint: "Plasma membrane of muscle fiber"),
                .init(id: "mf2", name: "Myofibril", x: 0.50, y: 0.35, hint: "Contractile rod within the fiber"),
                .init(id: "mf3", name: "Sarcoplasmic reticulum", x: 0.70, y: 0.30, hint: "Stores calcium ions"),
                .init(id: "mf4", name: "T-tubule", x: 0.60, y: 0.45, hint: "Carries action potential inward"),
                .init(id: "mf5", name: "Mitochondria", x: 0.30, y: 0.60, hint: "Provides ATP for contraction"),
                .init(id: "mf6", name: "Nucleus", x: 0.20, y: 0.20, hint: "Peripheral multinuclei in skeletal muscle"),
                .init(id: "mf7", name: "Sarcomere", x: 0.50, y: 0.55, hint: "Functional contractile unit"),
            ],
            difficulty: "intermediate"
        ),

        // 29. Sarcomere
        DiagramExercise(
            id: "ch10_sarcomere",
            title: "Structure of a Sarcomere",
            imageName: "Diagrams/diagram_sarcomere",
            chapterID: "ch10",
            sectionID: "ch10_s02",
            labels: [
                .init(id: "sar1", name: "Z-disc", x: 0.10, y: 0.50, hint: "Boundary of the sarcomere"),
                .init(id: "sar2", name: "A-band", x: 0.50, y: 0.20, hint: "Dark band, full length of thick filaments"),
                .init(id: "sar3", name: "I-band", x: 0.15, y: 0.20, hint: "Light band, thin filaments only"),
                .init(id: "sar4", name: "H-zone", x: 0.50, y: 0.80, hint: "Center area with thick filaments only"),
                .init(id: "sar5", name: "M-line", x: 0.50, y: 0.50, hint: "Center of the sarcomere"),
                .init(id: "sar6", name: "Thick filament (myosin)", x: 0.50, y: 0.60, hint: "Motor protein that pulls thin filaments"),
                .init(id: "sar7", name: "Thin filament (actin)", x: 0.30, y: 0.40, hint: "Protein filament that slides during contraction"),
            ],
            difficulty: "advanced"
        ),

        // 30. Neuromuscular Junction
        DiagramExercise(
            id: "ch10_nmj",
            title: "Neuromuscular Junction",
            imageName: "Diagrams/diagram_nmj",
            chapterID: "ch10",
            sectionID: "ch10_s03",
            labels: [
                .init(id: "nmj1", name: "Motor neuron axon", x: 0.30, y: 0.15, hint: "Nerve fiber carrying signal to muscle"),
                .init(id: "nmj2", name: "Axon terminal", x: 0.50, y: 0.30, hint: "End of the motor neuron"),
                .init(id: "nmj3", name: "Synaptic vesicles", x: 0.45, y: 0.38, hint: "Contain acetylcholine neurotransmitter"),
                .init(id: "nmj4", name: "Synaptic cleft", x: 0.50, y: 0.50, hint: "Gap between nerve and muscle"),
                .init(id: "nmj5", name: "Motor end plate", x: 0.50, y: 0.62, hint: "Specialized region of sarcolemma"),
                .init(id: "nmj6", name: "ACh receptors", x: 0.60, y: 0.58, hint: "Bind acetylcholine on muscle membrane"),
                .init(id: "nmj7", name: "Sarcolemma", x: 0.70, y: 0.70, hint: "Muscle fiber plasma membrane"),
                .init(id: "nmj8", name: "Mitochondria", x: 0.35, y: 0.28, hint: "Provide energy for neurotransmitter release"),
            ],
            difficulty: "advanced"
        ),

        // =====================================================================
        // CHAPTER 11: Muscular System
        // =====================================================================

        // 31. Muscles Anterior View
        DiagramExercise(
            id: "ch11_muscles_anterior",
            title: "Major Muscles (Anterior View)",
            imageName: "Diagrams/diagram_muscles_anterior",
            chapterID: "ch11",
            sectionID: "ch11_s01",
            labels: [
                .init(id: "ma1", name: "Deltoid", x: 0.25, y: 0.18, hint: "Shoulder cap muscle"),
                .init(id: "ma2", name: "Pectoralis major", x: 0.40, y: 0.22, hint: "Large chest muscle"),
                .init(id: "ma3", name: "Biceps brachii", x: 0.22, y: 0.32, hint: "Front of upper arm, flexes elbow"),
                .init(id: "ma4", name: "Rectus abdominis", x: 0.48, y: 0.40, hint: "\"Six-pack\" muscle"),
                .init(id: "ma5", name: "External oblique", x: 0.35, y: 0.38, hint: "Lateral abdominal muscle"),
                .init(id: "ma6", name: "Quadriceps femoris", x: 0.40, y: 0.58, hint: "Front of thigh, extends knee"),
                .init(id: "ma7", name: "Tibialis anterior", x: 0.42, y: 0.78, hint: "Front of shin, dorsiflexes foot"),
                .init(id: "ma8", name: "Sternocleidomastoid", x: 0.42, y: 0.12, hint: "Side of neck, rotates head"),
                .init(id: "ma9", name: "Trapezius", x: 0.55, y: 0.15, hint: "Upper back and neck"),
            ],
            difficulty: "intermediate"
        ),

        // 32. Shoulder Muscles
        DiagramExercise(
            id: "ch11_shoulder_muscles",
            title: "Muscles of the Shoulder",
            imageName: "Diagrams/diagram_shoulder_muscles",
            chapterID: "ch11",
            sectionID: "ch11_s03",
            labels: [
                .init(id: "sh1", name: "Deltoid", x: 0.50, y: 0.25, hint: "Abducts the arm to 90 degrees"),
                .init(id: "sh2", name: "Supraspinatus", x: 0.55, y: 0.15, hint: "Initiates arm abduction, rotator cuff"),
                .init(id: "sh3", name: "Infraspinatus", x: 0.65, y: 0.40, hint: "External rotation, rotator cuff"),
                .init(id: "sh4", name: "Teres minor", x: 0.68, y: 0.52, hint: "External rotation, rotator cuff"),
                .init(id: "sh5", name: "Subscapularis", x: 0.35, y: 0.40, hint: "Internal rotation, rotator cuff"),
                .init(id: "sh6", name: "Trapezius", x: 0.55, y: 0.08, hint: "Elevates and retracts scapula"),
                .init(id: "sh7", name: "Pectoralis major", x: 0.25, y: 0.45, hint: "Flexes and adducts arm"),
                .init(id: "sh8", name: "Latissimus dorsi", x: 0.72, y: 0.65, hint: "Extends and adducts arm"),
            ],
            difficulty: "advanced"
        ),

        // 33. Gluteal Muscles
        DiagramExercise(
            id: "ch11_gluteal_muscles",
            title: "Gluteal and Hip Muscles",
            imageName: "Diagrams/diagram_gluteal_muscles",
            chapterID: "ch11",
            sectionID: "ch11_s05",
            labels: [
                .init(id: "gl1", name: "Gluteus maximus", x: 0.50, y: 0.50, hint: "Largest gluteal muscle, extends hip"),
                .init(id: "gl2", name: "Gluteus medius", x: 0.50, y: 0.25, hint: "Abducts thigh, under maximus"),
                .init(id: "gl3", name: "Gluteus minimus", x: 0.45, y: 0.35, hint: "Smallest gluteal, deep abductor"),
                .init(id: "gl4", name: "Piriformis", x: 0.55, y: 0.42, hint: "Deep lateral rotator of hip"),
                .init(id: "gl5", name: "Tensor fasciae latae", x: 0.25, y: 0.30, hint: "Tenses iliotibial band"),
                .init(id: "gl6", name: "Iliotibial band", x: 0.22, y: 0.60, hint: "Thick lateral band from hip to knee"),
                .init(id: "gl7", name: "Hamstrings", x: 0.50, y: 0.75, hint: "Posterior thigh muscles, flex knee"),
            ],
            difficulty: "intermediate"
        ),
    ]
}
