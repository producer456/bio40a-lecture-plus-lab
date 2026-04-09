import SwiftUI

// MARK: - 3D Shape Types

enum Shape3D {
    case sphere(radius: Float)
    case capsule(radius: Float, height: Float)
    case box(width: Float, height: Float, depth: Float)
    case cylinder(radius: Float, height: Float)
    case torus(ringRadius: Float, pipeRadius: Float)
}

struct Vec3 {
    let x: Float, y: Float, z: Float
    static let zero = Vec3(x: 0, y: 0, z: 0)
}

// MARK: - Body Part 3D

struct BodyPart3D {
    let name: String
    let shape: Shape3D
    let position: Vec3
    let rotation: Vec3
    let color: Color
    let opacity: Float
}

// MARK: - Body Part Data

struct BodyPartData {
    static let allParts: [BodyPartInfo] = {
        var parts: [BodyPartInfo] = []
        for layer in BodyLayer.allCases {
            for p in BodyPartData.parts(for: layer) {
                let info = infoForPart(p.name, layer: layer)
                parts.append(info)
            }
        }
        return parts
    }()

    static func infoForPart(_ name: String, layer: BodyLayer) -> BodyPartInfo {
        let descriptions: [String: (String, String)] = [
            // Skeleton
            "Skull": ("The bony structure of the head that protects the brain and supports the face. Composed of 22 bones.", "Ch 7"),
            "Mandible": ("The lower jawbone — the only movable bone of the skull. Forms the chin.", "Ch 7"),
            "Cervical Spine": ("7 vertebrae (C1-C7) in the neck region. Supports the head and allows neck movement.", "Ch 7"),
            "Clavicle L": ("Left collarbone — connects the arm to the trunk. Commonly fractured bone.", "Ch 8"),
            "Clavicle R": ("Right collarbone — connects the arm to the trunk.", "Ch 8"),
            "Scapula L": ("Left shoulder blade — flat triangular bone on the posterior thorax.", "Ch 8"),
            "Scapula R": ("Right shoulder blade.", "Ch 8"),
            "Sternum": ("The breastbone — flat bone at the center of the chest. Protects the heart.", "Ch 7"),
            "Rib Cage": ("12 pairs of ribs that protect thoracic organs. True ribs (1-7), false ribs (8-12).", "Ch 7"),
            "Thoracic Spine": ("12 vertebrae (T1-T12) in the upper/mid back. Articulate with the ribs.", "Ch 7"),
            "Lumbar Spine": ("5 vertebrae (L1-L5) in the lower back. Largest, weight-bearing vertebrae.", "Ch 7"),
            "Pelvis": ("Formed by hip bones, sacrum, and coccyx. Supports the trunk and protects pelvic organs.", "Ch 8"),
            "Sacrum": ("Triangular bone at base of spine, formed by 5 fused vertebrae.", "Ch 7"),
            "Humerus L": ("Left upper arm bone — largest bone of the upper limb.", "Ch 8"),
            "Humerus R": ("Right upper arm bone.", "Ch 8"),
            "Radius L": ("Left forearm bone on the thumb side (lateral).", "Ch 8"),
            "Radius R": ("Right forearm bone on the thumb side.", "Ch 8"),
            "Ulna L": ("Left forearm bone on the pinky side (medial). Forms the elbow point.", "Ch 8"),
            "Ulna R": ("Right forearm bone on the pinky side.", "Ch 8"),
            "Femur L": ("Left thigh bone — the longest, heaviest, and strongest bone in the body.", "Ch 8"),
            "Femur R": ("Right thigh bone.", "Ch 8"),
            "Tibia L": ("Left shinbone — the larger, weight-bearing bone of the lower leg.", "Ch 8"),
            "Tibia R": ("Right shinbone.", "Ch 8"),
            "Fibula L": ("Left calf bone — the thinner bone of the lower leg (lateral).", "Ch 8"),
            "Fibula R": ("Right calf bone.", "Ch 8"),
            // Muscles
            "Trapezius": ("Large diamond-shaped muscle of the upper back. Moves the scapula and supports the arm.", "Ch 11"),
            "Deltoid L": ("Left shoulder muscle — abducts the arm. Triangular shape.", "Ch 11"),
            "Deltoid R": ("Right shoulder muscle.", "Ch 11"),
            "Pectoralis Major L": ("Left chest muscle — flexes and adducts the arm.", "Ch 11"),
            "Pectoralis Major R": ("Right chest muscle.", "Ch 11"),
            "Biceps L": ("Left anterior upper arm — flexes the elbow and supinates the forearm.", "Ch 11"),
            "Biceps R": ("Right anterior upper arm.", "Ch 11"),
            "Rectus Abdominis": ("'Six-pack' muscle — flexes the trunk. Runs vertically along the anterior abdomen.", "Ch 11"),
            "External Obliques": ("Side abdominal muscles — rotate and flex the trunk laterally.", "Ch 11"),
            "Quadriceps L": ("Left anterior thigh — 4 muscles that extend the knee. Key for walking/standing.", "Ch 11"),
            "Quadriceps R": ("Right anterior thigh.", "Ch 11"),
            "Gluteus Maximus L": ("Left buttock muscle — largest muscle in the body. Extends the hip.", "Ch 11"),
            "Gluteus Maximus R": ("Right buttock muscle.", "Ch 11"),
            "Gastrocnemius L": ("Left calf muscle — plantar flexes the foot (standing on tiptoes).", "Ch 11"),
            "Gastrocnemius R": ("Right calf muscle.", "Ch 11"),
            "Latissimus Dorsi": ("Large flat muscle of the lower back — adducts and extends the arm.", "Ch 11"),
            // Regions
            "Cephalic": ("Head region. Contains the brain and major sense organs.", "Ch 1"),
            "Cervical": ("Neck region. Contains the cervical spine and major blood vessels.", "Ch 1"),
            "Thoracic": ("Chest region. Contains the heart, lungs, and great vessels.", "Ch 1"),
            "Abdominal": ("Belly region. Contains digestive organs, kidneys.", "Ch 1"),
            "Pelvic": ("Hip region. Contains reproductive organs, bladder.", "Ch 1"),
            "Upper Limb L": ("Left arm — brachial (upper arm), antebrachial (forearm), manual (hand).", "Ch 1"),
            "Upper Limb R": ("Right arm.", "Ch 1"),
            "Lower Limb L": ("Left leg — femoral (thigh), crural (leg), pedal (foot).", "Ch 1"),
            "Lower Limb R": ("Right leg.", "Ch 1"),
        ]

        let (desc, chapter) = descriptions[name] ?? ("", "")
        return BodyPartInfo(name: name, description: desc, category: layer.displayName, chapter: chapter)
    }

    // MARK: - Parts by Layer

    static func parts(for layer: BodyLayer) -> [BodyPart3D] {
        switch layer {
        case .skeleton: return skeletonParts
        case .muscles: return muscleParts
        case .organs: return regionParts
        case .regions: return regionParts
        }
    }

    // MARK: - Skeleton

    static let skeletonParts: [BodyPart3D] = [
        // Skull
        BodyPart3D(name: "Skull", shape: .sphere(radius: 0.22), position: Vec3(x: 0, y: 1.55, z: 0), rotation: .zero, color: .init(white: 0.92), opacity: 1.0),
        BodyPart3D(name: "Mandible", shape: .box(width: 0.16, height: 0.06, depth: 0.12), position: Vec3(x: 0, y: 1.30, z: 0.04), rotation: .zero, color: .init(white: 0.88), opacity: 1.0),

        // Spine
        BodyPart3D(name: "Cervical Spine", shape: .capsule(radius: 0.04, height: 0.2), position: Vec3(x: 0, y: 1.2, z: -0.02), rotation: .zero, color: .init(white: 0.85), opacity: 1.0),
        BodyPart3D(name: "Thoracic Spine", shape: .capsule(radius: 0.05, height: 0.45), position: Vec3(x: 0, y: 0.85, z: -0.04), rotation: .zero, color: .init(white: 0.85), opacity: 1.0),
        BodyPart3D(name: "Lumbar Spine", shape: .capsule(radius: 0.055, height: 0.22), position: Vec3(x: 0, y: 0.5, z: -0.03), rotation: .zero, color: .init(white: 0.85), opacity: 1.0),
        BodyPart3D(name: "Sacrum", shape: .box(width: 0.1, height: 0.12, depth: 0.06), position: Vec3(x: 0, y: 0.33, z: -0.02), rotation: .zero, color: .init(white: 0.83), opacity: 1.0),

        // Thorax
        BodyPart3D(name: "Sternum", shape: .box(width: 0.06, height: 0.22, depth: 0.03), position: Vec3(x: 0, y: 0.92, z: 0.1), rotation: .zero, color: .init(white: 0.90), opacity: 1.0),
        BodyPart3D(name: "Rib Cage", shape: .box(width: 0.34, height: 0.35, depth: 0.22), position: Vec3(x: 0, y: 0.85, z: 0.02), rotation: .zero, color: .init(white: 0.87), opacity: 0.5),

        // Shoulder girdle
        BodyPart3D(name: "Clavicle L", shape: .capsule(radius: 0.02, height: 0.18), position: Vec3(x: -0.15, y: 1.08, z: 0.06), rotation: Vec3(x: 0, y: 0, z: 0.3), color: .init(white: 0.90), opacity: 1.0),
        BodyPart3D(name: "Clavicle R", shape: .capsule(radius: 0.02, height: 0.18), position: Vec3(x: 0.15, y: 1.08, z: 0.06), rotation: Vec3(x: 0, y: 0, z: -0.3), color: .init(white: 0.90), opacity: 1.0),
        BodyPart3D(name: "Scapula L", shape: .box(width: 0.12, height: 0.16, depth: 0.02), position: Vec3(x: -0.18, y: 0.95, z: -0.08), rotation: .zero, color: .init(white: 0.87), opacity: 0.9),
        BodyPart3D(name: "Scapula R", shape: .box(width: 0.12, height: 0.16, depth: 0.02), position: Vec3(x: 0.18, y: 0.95, z: -0.08), rotation: .zero, color: .init(white: 0.87), opacity: 0.9),

        // Pelvis
        BodyPart3D(name: "Pelvis", shape: .box(width: 0.32, height: 0.18, depth: 0.18), position: Vec3(x: 0, y: 0.28, z: 0), rotation: .zero, color: .init(white: 0.88), opacity: 0.8),

        // Upper limbs
        BodyPart3D(name: "Humerus L", shape: .capsule(radius: 0.035, height: 0.32), position: Vec3(x: -0.30, y: 0.85, z: 0), rotation: Vec3(x: 0, y: 0, z: 0.1), color: .init(white: 0.90), opacity: 1.0),
        BodyPart3D(name: "Humerus R", shape: .capsule(radius: 0.035, height: 0.32), position: Vec3(x: 0.30, y: 0.85, z: 0), rotation: Vec3(x: 0, y: 0, z: -0.1), color: .init(white: 0.90), opacity: 1.0),
        BodyPart3D(name: "Radius L", shape: .capsule(radius: 0.025, height: 0.28), position: Vec3(x: -0.33, y: 0.52, z: 0.02), rotation: Vec3(x: 0, y: 0, z: 0.05), color: .init(white: 0.88), opacity: 1.0),
        BodyPart3D(name: "Radius R", shape: .capsule(radius: 0.025, height: 0.28), position: Vec3(x: 0.33, y: 0.52, z: 0.02), rotation: Vec3(x: 0, y: 0, z: -0.05), color: .init(white: 0.88), opacity: 1.0),
        BodyPart3D(name: "Ulna L", shape: .capsule(radius: 0.022, height: 0.30), position: Vec3(x: -0.28, y: 0.51, z: -0.01), rotation: Vec3(x: 0, y: 0, z: 0.05), color: .init(white: 0.86), opacity: 1.0),
        BodyPart3D(name: "Ulna R", shape: .capsule(radius: 0.022, height: 0.30), position: Vec3(x: 0.28, y: 0.51, z: -0.01), rotation: Vec3(x: 0, y: 0, z: -0.05), color: .init(white: 0.86), opacity: 1.0),

        // Lower limbs
        BodyPart3D(name: "Femur L", shape: .capsule(radius: 0.045, height: 0.45), position: Vec3(x: -0.11, y: -0.05, z: 0), rotation: Vec3(x: 0, y: 0, z: 0.03), color: .init(white: 0.90), opacity: 1.0),
        BodyPart3D(name: "Femur R", shape: .capsule(radius: 0.045, height: 0.45), position: Vec3(x: 0.11, y: -0.05, z: 0), rotation: Vec3(x: 0, y: 0, z: -0.03), color: .init(white: 0.90), opacity: 1.0),
        BodyPart3D(name: "Tibia L", shape: .capsule(radius: 0.035, height: 0.40), position: Vec3(x: -0.11, y: -0.52, z: 0.01), rotation: .zero, color: .init(white: 0.88), opacity: 1.0),
        BodyPart3D(name: "Tibia R", shape: .capsule(radius: 0.035, height: 0.40), position: Vec3(x: 0.11, y: -0.52, z: 0.01), rotation: .zero, color: .init(white: 0.88), opacity: 1.0),
        BodyPart3D(name: "Fibula L", shape: .capsule(radius: 0.02, height: 0.38), position: Vec3(x: -0.16, y: -0.52, z: -0.01), rotation: .zero, color: .init(white: 0.85), opacity: 1.0),
        BodyPart3D(name: "Fibula R", shape: .capsule(radius: 0.02, height: 0.38), position: Vec3(x: 0.16, y: -0.52, z: -0.01), rotation: .zero, color: .init(white: 0.85), opacity: 1.0),
    ]

    // MARK: - Muscles

    static let muscleParts: [BodyPart3D] = [
        // Head/Neck
        BodyPart3D(name: "Trapezius", shape: .box(width: 0.36, height: 0.28, depth: 0.04), position: Vec3(x: 0, y: 1.0, z: -0.08), rotation: .zero, color: Color(red: 0.8, green: 0.25, blue: 0.25), opacity: 0.85),

        // Shoulders
        BodyPart3D(name: "Deltoid L", shape: .sphere(radius: 0.08), position: Vec3(x: -0.26, y: 1.02, z: 0), rotation: .zero, color: Color(red: 0.9, green: 0.3, blue: 0.3), opacity: 0.9),
        BodyPart3D(name: "Deltoid R", shape: .sphere(radius: 0.08), position: Vec3(x: 0.26, y: 1.02, z: 0), rotation: .zero, color: Color(red: 0.9, green: 0.3, blue: 0.3), opacity: 0.9),

        // Chest
        BodyPart3D(name: "Pectoralis Major L", shape: .box(width: 0.14, height: 0.16, depth: 0.05), position: Vec3(x: -0.10, y: 0.92, z: 0.08), rotation: .zero, color: Color(red: 0.85, green: 0.28, blue: 0.28), opacity: 0.9),
        BodyPart3D(name: "Pectoralis Major R", shape: .box(width: 0.14, height: 0.16, depth: 0.05), position: Vec3(x: 0.10, y: 0.92, z: 0.08), rotation: .zero, color: Color(red: 0.85, green: 0.28, blue: 0.28), opacity: 0.9),

        // Arms
        BodyPart3D(name: "Biceps L", shape: .capsule(radius: 0.04, height: 0.2), position: Vec3(x: -0.30, y: 0.82, z: 0.03), rotation: .zero, color: Color(red: 0.9, green: 0.35, blue: 0.3), opacity: 0.9),
        BodyPart3D(name: "Biceps R", shape: .capsule(radius: 0.04, height: 0.2), position: Vec3(x: 0.30, y: 0.82, z: 0.03), rotation: .zero, color: Color(red: 0.9, green: 0.35, blue: 0.3), opacity: 0.9),

        // Core
        BodyPart3D(name: "Rectus Abdominis", shape: .box(width: 0.14, height: 0.30, depth: 0.04), position: Vec3(x: 0, y: 0.55, z: 0.1), rotation: .zero, color: Color(red: 0.85, green: 0.3, blue: 0.25), opacity: 0.9),
        BodyPart3D(name: "External Obliques", shape: .box(width: 0.30, height: 0.22, depth: 0.04), position: Vec3(x: 0, y: 0.55, z: 0.06), rotation: .zero, color: Color(red: 0.75, green: 0.25, blue: 0.25), opacity: 0.6),

        // Back
        BodyPart3D(name: "Latissimus Dorsi", shape: .box(width: 0.34, height: 0.30, depth: 0.04), position: Vec3(x: 0, y: 0.65, z: -0.1), rotation: .zero, color: Color(red: 0.7, green: 0.22, blue: 0.22), opacity: 0.8),

        // Glutes
        BodyPart3D(name: "Gluteus Maximus L", shape: .sphere(radius: 0.10), position: Vec3(x: -0.10, y: 0.22, z: -0.06), rotation: .zero, color: Color(red: 0.8, green: 0.25, blue: 0.25), opacity: 0.9),
        BodyPart3D(name: "Gluteus Maximus R", shape: .sphere(radius: 0.10), position: Vec3(x: 0.10, y: 0.22, z: -0.06), rotation: .zero, color: Color(red: 0.8, green: 0.25, blue: 0.25), opacity: 0.9),

        // Legs
        BodyPart3D(name: "Quadriceps L", shape: .capsule(radius: 0.06, height: 0.35), position: Vec3(x: -0.11, y: -0.03, z: 0.04), rotation: .zero, color: Color(red: 0.85, green: 0.3, blue: 0.28), opacity: 0.9),
        BodyPart3D(name: "Quadriceps R", shape: .capsule(radius: 0.06, height: 0.35), position: Vec3(x: 0.11, y: -0.03, z: 0.04), rotation: .zero, color: Color(red: 0.85, green: 0.3, blue: 0.28), opacity: 0.9),
        BodyPart3D(name: "Gastrocnemius L", shape: .capsule(radius: 0.04, height: 0.25), position: Vec3(x: -0.11, y: -0.48, z: -0.03), rotation: .zero, color: Color(red: 0.8, green: 0.28, blue: 0.25), opacity: 0.9),
        BodyPart3D(name: "Gastrocnemius R", shape: .capsule(radius: 0.04, height: 0.25), position: Vec3(x: 0.11, y: -0.48, z: -0.03), rotation: .zero, color: Color(red: 0.8, green: 0.28, blue: 0.25), opacity: 0.9),
    ]

    // MARK: - Body Regions

    static let regionParts: [BodyPart3D] = [
        BodyPart3D(name: "Cephalic", shape: .sphere(radius: 0.20), position: Vec3(x: 0, y: 1.55, z: 0), rotation: .zero, color: .blue, opacity: 0.5),
        BodyPart3D(name: "Cervical", shape: .capsule(radius: 0.06, height: 0.15), position: Vec3(x: 0, y: 1.22, z: 0), rotation: .zero, color: .teal, opacity: 0.5),
        BodyPart3D(name: "Thoracic", shape: .box(width: 0.34, height: 0.35, depth: 0.22), position: Vec3(x: 0, y: 0.88, z: 0), rotation: .zero, color: .green, opacity: 0.4),
        BodyPart3D(name: "Abdominal", shape: .box(width: 0.30, height: 0.22, depth: 0.20), position: Vec3(x: 0, y: 0.55, z: 0), rotation: .zero, color: .yellow, opacity: 0.4),
        BodyPart3D(name: "Pelvic", shape: .box(width: 0.30, height: 0.15, depth: 0.20), position: Vec3(x: 0, y: 0.30, z: 0), rotation: .zero, color: .orange, opacity: 0.4),
        BodyPart3D(name: "Upper Limb L", shape: .capsule(radius: 0.04, height: 0.65), position: Vec3(x: -0.30, y: 0.7, z: 0), rotation: .zero, color: .purple, opacity: 0.4),
        BodyPart3D(name: "Upper Limb R", shape: .capsule(radius: 0.04, height: 0.65), position: Vec3(x: 0.30, y: 0.7, z: 0), rotation: .zero, color: .purple, opacity: 0.4),
        BodyPart3D(name: "Lower Limb L", shape: .capsule(radius: 0.05, height: 0.85), position: Vec3(x: -0.11, y: -0.30, z: 0), rotation: .zero, color: .red, opacity: 0.4),
        BodyPart3D(name: "Lower Limb R", shape: .capsule(radius: 0.05, height: 0.85), position: Vec3(x: 0.11, y: -0.30, z: 0), rotation: .zero, color: .red, opacity: 0.4),
    ]
}
