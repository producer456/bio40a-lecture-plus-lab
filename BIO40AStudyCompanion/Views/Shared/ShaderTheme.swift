import SwiftUI

// MARK: - Theme Manager

class ShaderThemeManager: ObservableObject {
    @AppStorage("shaderThemeEnabled") var isEnabled: Bool = false
}

// MARK: - View Modifiers — apply shaders directly to content pixels (no overlays)

struct ShaderCardModifier: ViewModifier {
    let system: BodySystem
    @EnvironmentObject var themeManager: ShaderThemeManager
    let startDate = Date()

    func body(content: Content) -> some View {
        if themeManager.isEnabled {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let time = Float(context.date.timeIntervalSince(startDate))
                content
                    .colorEffect(
                        ShaderLibrary.organicGlow(
                            .float2(300, 200),
                            .float(time),
                            .color(system.accentColor)
                        )
                    )
            }
        } else {
            content
        }
    }
}

struct ShaderBannerModifier: ViewModifier {
    let system: BodySystem
    @EnvironmentObject var themeManager: ShaderThemeManager
    let startDate = Date()

    func body(content: Content) -> some View {
        if themeManager.isEnabled {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let time = Float(context.date.timeIntervalSince(startDate))
                content
                    .colorEffect(
                        ShaderLibrary.cellMembrane(
                            .float2(400, 200),
                            .float(time),
                            .color(system.primaryColor),
                            .color(system.accentColor)
                        )
                    )
            }
        } else {
            content
        }
    }
}

struct ShaderNeuralPulseModifier: ViewModifier {
    let system: BodySystem
    @EnvironmentObject var themeManager: ShaderThemeManager
    let startDate = Date()

    func body(content: Content) -> some View {
        if themeManager.isEnabled {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let time = Float(context.date.timeIntervalSince(startDate))
                content
                    .colorEffect(
                        ShaderLibrary.neuralPulse(
                            .float2(400, 300),
                            .float(time),
                            .color(system.accentColor)
                        )
                    )
            }
        } else {
            content
        }
    }
}

struct ShaderBloodFlowModifier: ViewModifier {
    let system: BodySystem
    @EnvironmentObject var themeManager: ShaderThemeManager
    let startDate = Date()

    func body(content: Content) -> some View {
        if themeManager.isEnabled {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let time = Float(context.date.timeIntervalSince(startDate))
                content
                    .colorEffect(
                        ShaderLibrary.bloodFlow(
                            .float2(400, 200),
                            .float(time),
                            .color(system.primaryColor)
                        )
                    )
            }
        } else {
            content
        }
    }
}

struct ShaderDNAHelixModifier: ViewModifier {
    let system: BodySystem
    @EnvironmentObject var themeManager: ShaderThemeManager
    let startDate = Date()

    func body(content: Content) -> some View {
        if themeManager.isEnabled {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let time = Float(context.date.timeIntervalSince(startDate))
                content
                    .colorEffect(
                        ShaderLibrary.dnaHelix(
                            .float2(400, 300),
                            .float(time),
                            .color(system.primaryColor),
                            .color(system.accentColor)
                        )
                    )
            }
        } else {
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    func shaderCard(system: BodySystem) -> some View {
        modifier(ShaderCardModifier(system: system))
    }

    func shaderBanner(system: BodySystem) -> some View {
        modifier(ShaderBannerModifier(system: system))
    }

    func shaderNeuralPulse(system: BodySystem) -> some View {
        modifier(ShaderNeuralPulseModifier(system: system))
    }

    func shaderBloodFlow(system: BodySystem) -> some View {
        modifier(ShaderBloodFlowModifier(system: system))
    }

    func shaderDNAHelix(system: BodySystem) -> some View {
        modifier(ShaderDNAHelixModifier(system: system))
    }
}
