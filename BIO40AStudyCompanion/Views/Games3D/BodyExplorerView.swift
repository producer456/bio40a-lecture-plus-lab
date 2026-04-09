import SwiftUI
import SceneKit
import SwiftData

// MARK: - Body Explorer Entry

struct BodyExplorerView: View {
    @State private var selectedLayer: BodyLayer = .skeleton
    @State private var mode: ExplorerMode = .explore
    @State private var quizTarget: String? = nil
    @State private var quizScore = 0
    @State private var quizTotal = 0
    @State private var selectedPart: BodyPartInfo? = nil
    @State private var showPartDetail = false
    @State private var quizComplete = false
    @AppStorage("userName") private var userName = ""

    enum ExplorerMode: String, CaseIterable {
        case explore = "Explore"
        case quiz = "Quiz"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Controls
            HStack {
                Picker("Mode", selection: $mode) {
                    ForEach(ExplorerMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Spacer()

                Picker("Layer", selection: $selectedLayer) {
                    ForEach(BodyLayer.allCases, id: \.self) { layer in
                        Label(layer.displayName, systemImage: layer.icon).tag(layer)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Quiz prompt
            if mode == .quiz {
                quizBar
            }

            // 3D Scene
            BodySceneView(
                layer: selectedLayer,
                quizTarget: mode == .quiz ? quizTarget : nil,
                onPartTapped: handlePartTapped
            )
            .ignoresSafeArea(edges: .bottom)

            // Part detail sheet
            if let part = selectedPart, mode == .explore {
                partInfoBar(part)
            }
        }
        .navigationTitle("3D Body Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: mode) { _, newMode in
            if newMode == .quiz { startQuiz() }
            selectedPart = nil
        }
        .onChange(of: selectedLayer) { _, _ in
            if mode == .quiz { startQuiz() }
            selectedPart = nil
        }
        .sheet(isPresented: $quizComplete) {
            quizResults
        }
    }

    // MARK: - Quiz Bar

    private var quizBar: some View {
        HStack {
            if let target = quizTarget {
                Image(systemName: "target")
                    .foregroundStyle(.red)
                Text("Find: **\(target)**")
                    .font(.subheadline)
            }
            Spacer()
            Text("\(quizScore)/\(quizTotal)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(quizScore == quizTotal && quizTotal > 0 ? .green : .primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.yellow.opacity(0.1))
    }

    // MARK: - Part Info Bar

    private func partInfoBar(_ part: BodyPartInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(part.name)
                    .font(.headline)
                Spacer()
                Button {
                    selectedPart = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            if !part.description.isEmpty {
                Text(part.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !part.chapter.isEmpty {
                Text("Chapter: \(part.chapter)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Quiz Logic

    private func startQuiz() {
        quizScore = 0
        quizTotal = 0
        quizComplete = false
        nextQuizTarget()
    }

    private func nextQuizTarget() {
        let parts = BodyPartData.parts(for: selectedLayer)
        if quizTotal >= min(parts.count, 10) {
            quizComplete = true
            quizTarget = nil
            return
        }
        let remaining = parts.filter { p in
            true // simplified — in production, track which were already asked
        }
        quizTarget = remaining.randomElement()?.name
    }

    private func handlePartTapped(_ partName: String) {
        if mode == .explore {
            selectedPart = BodyPartData.allParts.first { $0.name == partName }
        } else if mode == .quiz {
            quizTotal += 1
            if partName == quizTarget {
                quizScore += 1
                selectedPart = BodyPartData.allParts.first { $0.name == partName }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    selectedPart = nil
                    nextQuizTarget()
                }
            } else {
                // Wrong — flash red feedback
                selectedPart = BodyPartInfo(name: partName, description: "That's not \(quizTarget ?? "the target"). Try again!", category: "", chapter: "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    selectedPart = nil
                }
            }
        }
    }

    // MARK: - Quiz Results

    private var quizResults: some View {
        VStack(spacing: 20) {
            Image(systemName: quizScore >= 7 ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(quizScore >= 7 ? .yellow : .green)
            Text(userName.isEmpty ? "Quiz Complete!" : "Nice work, \(userName)!")
                .font(.title2)
                .fontWeight(.bold)
            Text("\(quizScore)/\(quizTotal) correct")
                .font(.title3)
            Text("\(selectedLayer.displayName) layer")
                .foregroundStyle(.secondary)
            Button("Try Again") {
                quizComplete = false
                startQuiz()
            }
            .buttonStyle(.borderedProminent)
            Button("Done") {
                quizComplete = false
                mode = .explore
            }
            .font(.subheadline)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

// MARK: - Body Layers

enum BodyLayer: String, CaseIterable {
    case skeleton
    case muscles
    case organs
    case regions

    var displayName: String {
        switch self {
        case .skeleton: return "Skeleton"
        case .muscles: return "Muscles"
        case .organs: return "Regions"
        case .regions: return "Body Regions"
        }
    }

    var icon: String {
        switch self {
        case .skeleton: return "figure.stand"
        case .muscles: return "figure.strengthtraining.traditional"
        case .organs: return "heart.fill"
        case .regions: return "person.fill"
        }
    }
}

// MARK: - Body Part Info

struct BodyPartInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: String
    let chapter: String
}
