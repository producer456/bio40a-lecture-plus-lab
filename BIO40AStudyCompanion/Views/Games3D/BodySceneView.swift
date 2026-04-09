import SwiftUI
import SceneKit

// MARK: - SceneKit Wrapper

struct BodySceneView: UIViewRepresentable {
    let layer: BodyLayer
    let quizTarget: String?
    let onPartTapped: (String) -> Void

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.systemBackground
        scnView.antialiasingMode = .multisampling4X

        let scene = SCNScene()
        scnView.scene = scene

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 0, 4)
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Directional light
        let dirLight = SCNNode()
        dirLight.light = SCNLight()
        dirLight.light?.type = .directional
        dirLight.light?.intensity = 800
        dirLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(dirLight)

        // Tap gesture
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)

        // Build body
        buildBody(in: scene, layer: layer)

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }

        // Remove old body parts
        scene.rootNode.childNodes.filter { $0.name?.hasPrefix("part_") == true }.forEach { $0.removeFromParentNode() }

        // Rebuild for current layer
        buildBody(in: scene, layer: layer)

        // Highlight quiz target
        if let target = quizTarget {
            // Pulse the target subtly (but don't give away position)
        }

        context.coordinator.onPartTapped = onPartTapped
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPartTapped: onPartTapped)
    }

    // MARK: - Build Body

    private func buildBody(in scene: SCNScene, layer: BodyLayer) {
        let parts = BodyPartData.parts(for: layer)

        for part in parts {
            let node = createPartNode(part)
            node.name = "part_\(part.name)"
            scene.rootNode.addChildNode(node)
        }
    }

    private func createPartNode(_ part: BodyPart3D) -> SCNNode {
        let geometry: SCNGeometry

        switch part.shape {
        case .sphere(let radius):
            geometry = SCNSphere(radius: CGFloat(radius))
        case .capsule(let radius, let height):
            geometry = SCNCapsule(capRadius: CGFloat(radius), height: CGFloat(height))
        case .box(let w, let h, let d):
            geometry = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0.02)
        case .cylinder(let radius, let height):
            geometry = SCNCylinder(radius: CGFloat(radius), height: CGFloat(height))
        case .torus(let ring, let pipe):
            geometry = SCNTorus(ringRadius: CGFloat(ring), pipeRadius: CGFloat(pipe))
        }

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(part.color)
        material.transparency = CGFloat(part.opacity)
        material.isDoubleSided = true
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(part.position.x, part.position.y, part.position.z)
        node.eulerAngles = SCNVector3(part.rotation.x, part.rotation.y, part.rotation.z)

        return node
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var onPartTapped: (String) -> Void

        init(onPartTapped: @escaping (String) -> Void) {
            self.onPartTapped = onPartTapped
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])

            if let hit = hitResults.first,
               let name = hit.node.name,
               name.hasPrefix("part_") {
                let partName = String(name.dropFirst(5))

                // Flash the tapped part
                let material = hit.node.geometry?.firstMaterial
                let originalColor = material?.diffuse.contents
                material?.diffuse.contents = UIColor.white

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    material?.diffuse.contents = originalColor
                }

                onPartTapped(partName)
            }
        }
    }
}
