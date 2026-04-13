import SwiftUI

// MARK: - Body System Colors

enum BodySystem: String, CaseIterable {
    case nervous    // Home — command center
    case skeletal   // Lessons — structural framework
    case muscular   // Interactive Learning — active work
    case cardiovascular // Practice — pumping energy
    case integumentary  // Games — layers
    case endocrine  // Schedule — timing/regulation
    case organ      // Comparisons — organ systems overview

    var primaryColor: Color {
        switch self {
        case .nervous:       return Color(red: 0.35, green: 0.50, blue: 0.72)  // slate blue
        case .skeletal:      return Color(red: 0.60, green: 0.50, blue: 0.38)  // darker bone (readable on white)
        case .muscular:      return Color(red: 0.75, green: 0.22, blue: 0.22)  // deep red
        case .cardiovascular: return Color(red: 0.85, green: 0.25, blue: 0.30) // arterial red
        case .integumentary: return Color(red: 0.65, green: 0.50, blue: 0.35)  // darker tan (readable)
        case .endocrine:     return Color(red: 0.75, green: 0.58, blue: 0.15)  // darker amber
        case .organ:         return Color(red: 0.25, green: 0.60, blue: 0.58)  // teal
        }
    }

    var accentColor: Color {
        switch self {
        case .nervous:       return Color(red: 0.55, green: 0.75, blue: 1.0)
        case .skeletal:      return Color(red: 0.85, green: 0.78, blue: 0.65)
        case .muscular:      return Color(red: 1.0, green: 0.40, blue: 0.40)
        case .cardiovascular: return Color(red: 1.0, green: 0.45, blue: 0.45)
        case .integumentary: return Color(red: 0.90, green: 0.78, blue: 0.60)
        case .endocrine:     return Color(red: 1.0, green: 0.85, blue: 0.40)
        case .organ:         return Color(red: 0.40, green: 0.80, blue: 0.75)
        }
    }

    /// Lighter version for banner overlays (keeps the original warm tones)
    var bannerColor: Color {
        switch self {
        case .skeletal:      return Color(red: 0.82, green: 0.75, blue: 0.62)
        case .integumentary: return Color(red: 0.80, green: 0.65, blue: 0.48)
        case .endocrine:     return Color(red: 0.85, green: 0.68, blue: 0.25)
        default:             return primaryColor
        }
    }

    var gradientColors: [Color] {
        [primaryColor, primaryColor.opacity(0.6)]
    }

    var heroImage: String {
        switch self {
        case .nervous:       return "415_Neuron"
        case .skeletal:      return "601_Bone_Classification"
        case .muscular:      return "1105_Anterior_and_Posterior_Views_of_Muscles"
        case .cardiovascular: return "1020_Cardiac_Muscle"
        case .integumentary: return "501_Structure_of_the_skin"
        case .endocrine:     return "0312_Animal_Cell_and_Components"
        case .organ:         return "102_Organ_Systems_of_Body_Page1_"
        }
    }

    var tabIcon: String {
        switch self {
        case .nervous:       return "brain.head.profile"
        case .skeletal:      return "figure.stand"
        case .muscular:      return "hand.tap.fill"
        case .cardiovascular: return "heart.fill"
        case .integumentary: return "gamecontroller.fill"
        case .endocrine:     return "calendar"
        case .organ:         return "ellipsis.circle"
        }
    }

    var displayName: String {
        switch self {
        case .nervous:       return "Nervous System"
        case .skeletal:      return "Skeletal System"
        case .muscular:      return "Muscular System"
        case .cardiovascular: return "Cardiovascular System"
        case .integumentary: return "Integumentary System"
        case .endocrine:     return "Endocrine System"
        case .organ:         return "Organ Systems"
        }
    }
}

// MARK: - Hero Banner

struct BioHeroBanner: View {
    let system: BodySystem
    let title: String
    let subtitle: String?
    var height: CGFloat = 160

    init(system: BodySystem, title: String, subtitle: String? = nil, height: CGFloat = 160) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
        self.height = height
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background: gradient fallback if image missing
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: system.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Background image (overlay on gradient fallback)
            Image(system.heroImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [system.bannerColor.opacity(0.85), system.bannerColor.opacity(0.5), .clear],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(system.displayName.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.7))
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding()
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Bio Card (themed card with optional background image)

struct BioCard<Content: View>: View {
    let system: BodySystem
    var backgroundImage: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                    if let img = backgroundImage {
                        Image(img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(0.08)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(system.primaryColor.opacity(0.15), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Animation: Heartbeat Pulse

struct HeartbeatPulse: ViewModifier {
    var color: Color = .red
    var intensity: CGFloat = 1.0

    // Heartbeat cycle: 1.3 seconds total
    // 0.00-0.12: first bump up
    // 0.12-0.24: back down
    // 0.28-0.40: second bump up
    // 0.40-0.55: back down
    // 0.55-1.30: rest

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = t.truncatingRemainder(dividingBy: 1.3)
            let (scale, glow) = heartbeatValues(phase: phase)

            content
                .scaleEffect(scale)
                .shadow(color: color.opacity(glow * 0.8), radius: 12 * intensity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(glow * 0.15))
                        .allowsHitTesting(false)
                )
        }
    }

    private func heartbeatValues(phase: Double) -> (CGFloat, CGFloat) {
        let bump1: CGFloat = 0.12 * intensity
        let bump2: CGFloat = 0.08 * intensity

        switch phase {
        case 0..<0.12:
            let p = phase / 0.12
            return (1.0 + bump1 * ease(p), ease(p))
        case 0.12..<0.24:
            let p = (phase - 0.12) / 0.12
            return (1.0 + bump1 * (1.0 - ease(p)), 1.0 - ease(p) * 0.8)
        case 0.28..<0.40:
            let p = (phase - 0.28) / 0.12
            return (1.0 + bump2 * ease(p), ease(p) * 0.7)
        case 0.40..<0.55:
            let p = (phase - 0.40) / 0.15
            return (1.0 + bump2 * (1.0 - ease(p)), 0.7 * (1.0 - ease(p)))
        default:
            return (1.0, 0)
        }
    }

    private func ease(_ t: Double) -> CGFloat {
        // Smooth ease in-out
        CGFloat(t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2)
    }
}

// MARK: - Animation: Breathing (opacity-based, no layout shift)

struct BreathingModifier: ViewModifier {
    @State private var breathing = false
    var intensity: CGFloat = 0.015

    func body(content: Content) -> some View {
        content
            .opacity(breathing ? 1.0 : 1.0 - Double(intensity) * 3)
            .animation(
                .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                value: breathing
            )
            .onAppear { breathing = true }
    }
}

// MARK: - Animation: Neural Flash (counter-based, fires every increment)

struct NeuralFlashModifier: ViewModifier {
    let trigger: Int
    @State private var flash = false
    @State private var lastTrigger = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(flash ? 0.3 : 0))
                    .allowsHitTesting(false)
            )
            .onChange(of: trigger) { _, newValue in
                guard newValue > lastTrigger else { return }
                lastTrigger = newValue
                withAnimation(.easeIn(duration: 0.08)) { flash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeOut(duration: 0.35)) { flash = false }
                }
            }
    }
}

// MARK: - Animation: Muscle Contraction Button Style

struct MuscleButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.interpolatingSpring(stiffness: 400, damping: 10), value: configuration.isPressed)
    }
}

struct MuscleContractButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void

    init(_ title: String, icon: String? = nil, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        }
        .buttonStyle(MuscleButtonStyle(color: color))
    }
}

// MARK: - Animation: Blood Flow Progress

struct BloodFlowProgress: View {
    let value: Double
    let system: BodySystem
    @State private var waveOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(system.primaryColor.opacity(0.15))

                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [system.primaryColor, system.accentColor, system.primaryColor],
                            startPoint: UnitPoint(x: waveOffset - 0.5, y: 0.5),
                            endPoint: UnitPoint(x: waveOffset + 0.5, y: 0.5)
                        )
                    )
                    .frame(width: geo.size.width * max(0.02, value))
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                waveOffset = 2.0
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func heartbeatPulse(color: Color = .red, intensity: CGFloat = 1.0) -> some View {
        modifier(HeartbeatPulse(color: color, intensity: intensity))
    }

    func breathing(intensity: CGFloat = 0.015) -> some View {
        modifier(BreathingModifier(intensity: intensity))
    }

    func neuralFlash(trigger: Int) -> some View {
        modifier(NeuralFlashModifier(trigger: trigger))
    }
}
