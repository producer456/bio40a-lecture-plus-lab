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
    var subtitle: String? = nil
    var badge: String? = nil
    var height: CGFloat = 200
    @EnvironmentObject var themeManager: ShaderThemeManager

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background with parallax
            Image(system.heroImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()
                .shaderBanner(system: system)

            // Multi-layer gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: system.bannerColor.opacity(0.3), location: 0.4),
                    .init(color: system.bannerColor.opacity(0.85), location: 0.85),
                    .init(color: system.bannerColor, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Radial glow from bottom-left
            RadialGradient(
                colors: [system.accentColor.opacity(0.3), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 250
            )

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Section badge (custom label, or hidden if nil)
                if let badgeText = badge {
                Text(badgeText.uppercased())
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .tracking(2.0)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(system.accentColor.opacity(0.5), lineWidth: 0.5))
                }

                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(20)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Bio Card (themed card with optional background image)

struct BioCard<Content: View>: View {
    let system: BodySystem
    var backgroundImage: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                        .shaderCard(system: system)

                    if let img = backgroundImage {
                        Image(img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(0.06)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    // Colored top accent line
                    VStack {
                        LinearGradient(
                            colors: [system.primaryColor, system.accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 2)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(system.primaryColor.opacity(0.1), lineWidth: 0.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: system.primaryColor.opacity(0.12), radius: 10, y: 4)
    }
}

// MARK: - Animation: Heartbeat Pulse

struct HeartbeatPulse: ViewModifier {
    var color: Color = .red
    var intensity: CGFloat = 1.0

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = t.truncatingRemainder(dividingBy: 2.4)
            let (scale, glow) = heartbeatValues(phase: phase)

            content
                .scaleEffect(scale)
                // Bold outer glow
                .shadow(color: color.opacity(glow * 0.9), radius: 20 * intensity)
                .shadow(color: color.opacity(glow * 0.5), radius: 6 * intensity)
                // Strong color overlay wash
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(glow * 0.35))
                        .allowsHitTesting(false)
                )
                // Border pulse
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(glow * 0.6), lineWidth: 2 * intensity)
                        .allowsHitTesting(false)
                )
        }
    }

    private func heartbeatValues(phase: Double) -> (CGFloat, CGFloat) {
        let bump1: CGFloat = 0.06 * intensity
        let bump2: CGFloat = 0.04 * intensity

        switch phase {
        case 0..<0.14:
            // First beat — BIG
            let p = phase / 0.14
            return (1.0 + bump1 * ease(p), ease(p))
        case 0.14..<0.28:
            let p = (phase - 0.14) / 0.14
            return (1.0 + bump1 * (1.0 - ease(p)), 1.0 - ease(p) * 0.7)
        case 0.32..<0.46:
            // Second beat — smaller
            let p = (phase - 0.32) / 0.14
            return (1.0 + bump2 * ease(p), ease(p) * 0.8)
        case 0.46..<0.65:
            let p = (phase - 0.46) / 0.19
            return (1.0 + bump2 * (1.0 - ease(p)), 0.8 * (1.0 - ease(p)))
        default:
            // Rest
            return (1.0, 0)
        }
    }

    private func ease(_ t: Double) -> CGFloat {
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

// MARK: - Section Header

struct BioSectionHeader: View {
    let title: String
    let icon: String
    let system: BodySystem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(system.accentColor)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Stat Badge

struct BioStatBadge: View {
    let value: String
    let label: String
    let system: BodySystem

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(system.accentColor)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
