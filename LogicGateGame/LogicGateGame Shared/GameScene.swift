//
//  GameScene.swift
//  LogicGateGame Shared
//
//  Created by Graden on 10/7/25.
//

import SpriteKit
import CoreGraphics

struct GatePaletteItem {
    let type: GateType
    let title: String
}

// MARK: - Visual Nodes

final class InputNode: SKShapeNode {
    let label = SKLabelNode(fontNamed: "Menlo")
    var value: Bool = false { didSet { update() } }

    override init() {
        super.init()
        let size = CGSize(width: 44, height: 44)
        let rect = CGRect(origin: .zero, size: size)
        self.path = CGPath(roundedRect: rect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        self.lineWidth = 2
        self.fillColor = .black
        self.strokeColor = .white
        centerPath()

        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.text = "0"
        addChild(label)
        update()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func toggle() { value.toggle() }

    private func update() {
        label.text = value ? "1" : "0"
        fillColor = value ? .systemGreen : .black
    }
}

final class OutputNode: SKShapeNode {
    let label = SKLabelNode(fontNamed: "Menlo")
    var value: Bool = false { didSet { update() } }

    override init() {
        super.init()
        let size = CGSize(width: 44, height: 44)
        let rect = CGRect(origin: .zero, size: size)
        self.path = CGPath(roundedRect: rect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        self.lineWidth = 2
        self.fillColor = .black
        self.strokeColor = .white
        centerPath()

        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.text = "?"
        addChild(label)
        update()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func update() {
        label.text = value ? "1" : "0"
        fillColor = value ? .systemBlue : .black
    }
}

final class GateNode: SKShapeNode {
    let label = SKLabelNode(fontNamed: "Menlo")
    var gate: LogicGate { didSet { refresh() } }
    // Connection anchors
    let inputAnchorA = SKShapeNode(circleOfRadius: 6)
    let inputAnchorB = SKShapeNode(circleOfRadius: 6)
    let outputAnchor = SKShapeNode(circleOfRadius: 6)

    init(gate: LogicGate) {
        self.gate = gate
        super.init()
        let size = CGSize(width: 90, height: 60)
        let rect = CGRect(origin: .zero, size: size)
        self.path = CGPath(roundedRect: rect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        self.lineWidth = 2
        self.fillColor = .darkGray
        self.strokeColor = .white
        centerPath()

        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
        refresh()
        buildAnchors()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func refresh() {
        label.text = symbol(for: gate.type)
    }

    private func symbol(for type: GateType) -> String {
        switch type {
        case .and: return "AND"
        case .or: return "OR"
        case .not: return "NOT"
        case .xor: return "XOR"
        case .nand: return "NAND"
        case .nor: return "NOR"
        case .xnor: return "XNOR"
        }
    }

    private func buildAnchors() {
        func style(_ n: SKShapeNode, name: String) {
            n.fillColor = .black
            n.strokeColor = .white
            n.lineWidth = 1.5
            n.name = name
            n.zPosition = 50
            addChild(n)
        }
        style(inputAnchorA, name: "anchor_in_A")
        style(outputAnchor, name: "anchor_out")
        inputAnchorA.position = CGPoint(x: -50, y: 15)
        outputAnchor.position = CGPoint(x: 50, y: 0)
        if gate.type != .not {
            style(inputAnchorB, name: "anchor_in_B")
            inputAnchorB.position = CGPoint(x: -50, y: -15)
        }
    }
}

private extension SKShapeNode {
    func centerPath() {
        if let b = self.path?.boundingBox {
            self.position = CGPoint(x: self.position.x - b.midX, y: self.position.y - b.midY)
        }
    }
}

// MARK: - Source / Constant gates (non-recursive)
final class ConstantGate: LogicGate { let constant: Bool; init(_ v: Bool) { self.constant = v; super.init(position: .zero, type: .not, inputA: nil) } }
final class DummyInputGate: LogicGate { var value: Bool; init(initial: Bool = false) { self.value = initial; super.init(position: .zero, type: .not, inputA: nil) } }

// MARK: - Scene

class GameScene: SKScene {

    // UI labels
    private var titleLabel: SKLabelNode!
    private var targetLabel: SKLabelNode!
    private var backButton: SKLabelNode!

    // Level/HUD
    var levelIndex: Int = 1
    private var hudLevelLabel: SKLabelNode!
    private var paletteContainer: SKNode = SKNode()
    private var paletteItems: [GatePaletteItem] = [
        GatePaletteItem(type: .and, title: "AND"),
        GatePaletteItem(type: .or, title: "OR"),
        GatePaletteItem(type: .not, title: "NOT"),
        GatePaletteItem(type: .xor, title: "XOR"),
        GatePaletteItem(type: .nand, title: "NAND"),
        GatePaletteItem(type: .nor, title: "NOR"),
        GatePaletteItem(type: .xnor, title: "XNOR")
    ]

    // Visual IO
    private let inputAView = InputNode()
    private let inputBView = InputNode()
    private let outputView = OutputNode()

    // Logic model
    private let inputAGate = DummyInputGate()
    private let inputBGate = DummyInputGate()
    private var middleGate: LogicGate!
    private var middleGateNode: GateNode!

    // Target output for the current puzzle
    private var targetOutput: Bool = true { didSet { refreshTarget() } }

    // Wiring state
    private var gates: [GateNode] = []
    private var outputSource: LogicGate?
    private var dragLine: SKShapeNode?
    private var dragSourceGate: LogicGate?
    private var dragSourceNode: SKNode?
    private var movingNode: SKNode?
    private var movingOriginalPosition: CGPoint = .zero

    private struct WireConnection {
        weak var fromAnchor: SKNode?
        weak var toAnchor: SKNode?
        let shape: SKShapeNode
    }
    private var connections: [WireConnection] = []
    private var trashNode: SKShapeNode?
    private var lastDragPoint: CGPoint = .zero

    override func didMove(to view: SKView) {
        print("GameScene.didMove(to:) size=\(size) level=\(levelIndex)")
        backgroundColor = .black
        setupLevel()
        setupPaletteAndHUD()
    }

    private func setupLevel() {
        print("GameScene.setupLevel start")
        removeAllChildren()

        // Labels
        titleLabel = SKLabelNode(fontNamed: "Menlo")
        titleLabel.text = "Logic Gate Puzzle"
        titleLabel.fontSize = 22
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        addChild(titleLabel)

        targetLabel = SKLabelNode(fontNamed: "Menlo")
        targetLabel.fontSize = 16
        targetLabel.fontColor = .white
        targetLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 90)
        addChild(targetLabel)
        
        backButton = SKLabelNode(fontNamed: "Menlo")
        backButton.text = "Back"
        backButton.fontSize = 16
        backButton.fontColor = .systemRed
        backButton.position = CGPoint(x: frame.minX + 50, y: frame.maxY - 90)
        backButton.name = "back_button"
        addChild(backButton)

        // Layout
        let leftX = frame.minX + 90
        let rightX = frame.maxX - 90
        let midX = frame.midX
        let centerY = frame.midY

        // Place inputs
        inputAView.position = CGPoint(x: leftX, y: centerY + 70)
        inputBView.position = CGPoint(x: leftX, y: centerY - 70)
        addChild(inputAView)
        addChild(inputBView)

        let aLabel = SKLabelNode(fontNamed: "Menlo")
        aLabel.text = "A"
        aLabel.fontSize = 12
        aLabel.fontColor = .white
        aLabel.position = CGPoint(x: inputAView.position.x, y: inputAView.position.y + 36)
        addChild(aLabel)

        let bLabel = SKLabelNode(fontNamed: "Menlo")
        bLabel.text = "B"
        bLabel.fontSize = 12
        bLabel.fontColor = .white
        bLabel.position = CGPoint(x: inputBView.position.x, y: inputBView.position.y + 36)
        addChild(bLabel)

        let outLabel = SKLabelNode(fontNamed: "Menlo")
        outLabel.text = "Output"
        outLabel.fontSize = 12
        outLabel.fontColor = .white
        outLabel.position = CGPoint(x: rightX, y: centerY + 36)
        addChild(outLabel)

        // Middle gate (user cycles type)
        middleGate = LogicGate(position: CGPoint(x: midX, y: centerY), type: .and, inputA: inputAGate, inputB: inputBGate)
        middleGateNode = GateNode(gate: middleGate)
        middleGateNode.position = CGPoint(x: midX, y: centerY)
        addChild(middleGateNode)
        gates.append(middleGateNode)

        // Output
        outputView.position = CGPoint(x: rightX, y: centerY)
        addChild(outputView)

    // Dynamic wires (connections recorded so they update when nodes move)
    outputSource = middleGate
    createConnection(from: inputAView, to: middleGateNode.inputAnchorA)
    if middleGateNode.inputAnchorB.parent != nil { createConnection(from: inputBView, to: middleGateNode.inputAnchorB) }
    createConnection(from: middleGateNode.outputAnchor, to: outputView)

        // Initial state
        targetOutput = true
        evaluate()
        print("GameScene.setupLevel done. children=\(children.count)")
    }

    private func setupPaletteAndHUD() {
        print("GameScene.setupPaletteAndHUD start")
        // Remove any previous palette
        paletteContainer.removeFromParent()
        paletteContainer = SKNode()
        addChild(paletteContainer)

        // Level label
        hudLevelLabel?.removeFromParent()
        hudLevelLabel = SKLabelNode(fontNamed: "Menlo")
        hudLevelLabel.text = "Level \(levelIndex)"
        hudLevelLabel.fontSize = 16
        hudLevelLabel.fontColor = .lightGray
        hudLevelLabel.position = CGPoint(x: frame.minX + 80, y: frame.maxY - 40)
        addChild(hudLevelLabel)

        // Target label already exists (targetLabel). Ensure it is visible and positioned.
        targetLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 90)

        // Build palette along the bottom center
        let buttonSpacing: CGFloat = 70
        let startX = frame.midX - (CGFloat(paletteItems.count - 1) * buttonSpacing / 2)
        let y = frame.minY + 40
        for (idx, item) in paletteItems.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = item.title
            label.fontSize = 14
            label.fontColor = .systemYellow
            label.position = CGPoint(x: startX + CGFloat(idx) * buttonSpacing, y: y)
            label.name = "palette_\(item.title)"
            paletteContainer.addChild(label)
        }

        // Hint
        let hint = SKLabelNode(fontNamed: "Menlo")
        hint.text = "Tap a gate below to add it"
        hint.fontSize = 12
        hint.fontColor = .gray
        hint.position = CGPoint(x: frame.midX, y: y + 24)
        addChild(hint)
        print("GameScene.setupPaletteAndHUD done. paletteChildren=\(paletteContainer.children.count)")
        buildTrashArea()
    }

    private func makeWire(from: CGPoint, to: CGPoint) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let wire = SKShapeNode(path: path)
        wire.strokeColor = .gray
        wire.lineWidth = 2
        return wire
    }

    private func refreshTarget() {
        targetLabel.text = "Target: " + (targetOutput ? "1" : "0") + "  (Tap output to change)"
    }

    private func evaluate() { evaluateGraph() }

    private func evaluateGraph() {
        inputAGate.value = inputAView.value
        inputBGate.value = inputBView.value

        var visited = Set<ObjectIdentifier>()

        func compute(_ gate: LogicGate?) -> Bool {
            guard let g = gate else { return false }
            let id = ObjectIdentifier(g)
            if visited.contains(id) { return false } // silent cycle guard
            visited.insert(id)
            if let input = g as? DummyInputGate { return input.value }
            if let constant = g as? ConstantGate { return constant.constant }
            switch g.type {
            case .not:
                return !compute(g.inputA)
            case .and, .or, .xor, .nand, .nor, .xnor:
                let a = compute(g.inputA)
                let b = compute(g.inputB)
                switch g.type {
                case .and: return a && b
                case .or: return a || b
                case .xor: return a != b
                case .nand: return !(a && b)
                case .nor: return !(a || b)
                case .xnor: return a == b
                default: return false
                }
            }
        }

        let root = outputSource ?? middleGate
        let result = compute(root)
        outputView.value = result
        if result == targetOutput {
            run(SKAction.sequence([
                SKAction.run { self.backgroundColor = .systemGreen.withAlphaComponent(0.25) },
                SKAction.wait(forDuration: 0.2),
                SKAction.run { self.backgroundColor = .black }
            ]))
        }
    }

    // MARK: - Interaction
    #if os(iOS) || os(tvOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        handle(point: t.location(in: self))
    }
    #else
    override func mouseDown(with event: NSEvent) {
        handle(point: event.location(in: self))
    }
    #endif

    private func handle(point: CGPoint) {
        print("GameScene.handle tap at: \(point)")
        let nodes = nodes(at: point)
        for n in nodes {
            if let name = n.name, name == "back_button" {
                presentStartMenu()
                return
            }
            if let name = n.name, name.hasPrefix("palette_") {
                if let gateType = gateTypeFromPaletteName(name) {
                    spawnGate(of: gateType)
                    return
                }
            }
            if n === outputView || n.parent === outputView { targetOutput.toggle(); return }
            if isOutputAnchor(n) || n === inputAView || n === inputBView { startWireDrag(from: n); return }
            if let gateNode = n as? GateNode { beginMove(node: gateNode); return }
            if let parentGate = n.parent as? GateNode, n !== parentGate.inputAnchorA && n !== parentGate.inputAnchorB && n !== parentGate.outputAnchor { beginMove(node: parentGate); return }
            if n === inputAView || n === inputBView { beginMove(node: n); return }
        }
    }
    // Gates are immutable (no cycling)

    private func gateTypeFromPaletteName(_ name: String) -> GateType? {
        let title = String(name.dropFirst("palette_".count))
        switch title {
        case "AND": return .and
        case "OR": return .or
        case "NOT": return .not
        case "XOR": return .xor
        case "NAND": return .nand
        case "NOR": return .nor
        case "XNOR": return .xnor
        default: return nil
        }
    }

    private func spawnGate(of type: GateType) {
        // Create a free gate (user will wire it)
        let newGate = LogicGate(position: CGPoint(x: frame.midX, y: frame.midY), type: type, inputA: nil, inputB: nil)
        let node = GateNode(gate: newGate)
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(node)
        gates.append(node)
    }

    // MARK: - Drag Wiring
    private func startWireDrag(from node: SKNode) {
        dragSourceNode = node
        dragSourceGate = logicGate(for: node)
        let line = SKShapeNode()
        line.strokeColor = .systemYellow
        line.lineWidth = 3
        line.zPosition = 5
        dragLine = line
        addChild(line)
    }

    private func updateDrag(to point: CGPoint) {
        if let moving = movingNode {
            moving.position = point
            updateConnections()
            lastDragPoint = point
            updateTrashHighlight()
        } else if let src = dragSourceNode, let line = dragLine {
            let path = CGMutablePath()
            path.move(to: convert(CGPoint.zero, from: src))
            path.addLine(to: point)
            line.path = path
        }
    }

    private func endDrag(at point: CGPoint) {
        if movingNode != nil {
            // If over trash area, delete gate (if it's a gate)
            if let trash = trashNode, let gateNode = movingNode as? GateNode, trash.contains(point) {
                removeGateNode(gateNode)
            }
            resetTrashHighlight()
            movingNode = nil
            return
        }
        defer { dragLine?.removeFromParent(); dragLine = nil; dragSourceGate = nil; dragSourceNode = nil }
        guard let source = dragSourceGate, let sourceNode = dragSourceNode else { return }
        let targets = nodes(at: point)
        for t in targets {
            if let parent = t.parent as? GateNode, t.name == "anchor_in_A" {
                parent.gate.inputA = source
                removeConnections(endingAt: parent.inputAnchorA)
                createConnection(from: sourceNode, to: parent.inputAnchorA)
                evaluate(); return
            }
            if let parent = t.parent as? GateNode, t.name == "anchor_in_B" {
                parent.gate.inputB = source
                removeConnections(endingAt: parent.inputAnchorB)
                createConnection(from: sourceNode, to: parent.inputAnchorB)
                evaluate(); return
            }
            if t === outputView || t.parent === outputView {
                outputSource = source
                removeConnections(endingAt: outputView)
                createConnection(from: sourceNode, to: outputView)
                evaluate(); return
            }
        }
    }

    private func isOutputAnchor(_ node: SKNode) -> Bool {
        if node.name == "anchor_out" { return true }
        if let parent = node.parent, parent.name == "anchor_out" { return true }
        if node === inputAView || node === inputBView { return true } // treat inputs as output sources
        return false
    }

    private func logicGate(for node: SKNode) -> LogicGate? {
        if node === inputAView { return inputAGate }
        if node === inputBView { return inputBGate }
        if let gateNode = node as? GateNode { return gateNode.gate }
        if let parent = node.parent as? GateNode { return parent.gate }
        return nil
    }

    // MARK: - Movement
    private func beginMove(node: SKNode) {
        movingNode = node
        movingOriginalPosition = node.position
    }

    // MARK: - Trash / Deletion
    private func buildTrashArea() {
        trashNode?.removeFromParent()
        let size = CGSize(width: 110, height: 60)
        let rect = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        let shape = SKShapeNode(rect: rect, cornerRadius: 12)
        shape.fillColor = .darkGray.withAlphaComponent(0.4)
        shape.strokeColor = .red
        shape.lineWidth = 2
        shape.position = CGPoint(x: frame.maxX - 90, y: frame.minY + 90)
        shape.zPosition = 30
        shape.name = "trash_zone"

        let label = SKLabelNode(fontNamed: "Menlo")
        label.text = "Trash"
        label.fontSize = 16
        label.fontColor = .red
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        shape.addChild(label)

        addChild(shape)
        trashNode = shape
    }

    private func updateTrashHighlight() {
        guard let trash = trashNode else { return }
        if trash.contains(lastDragPoint) {
            trash.fillColor = .red.withAlphaComponent(0.5)
        } else {
            trash.fillColor = .darkGray.withAlphaComponent(0.4)
        }
    }

    private func resetTrashHighlight() {
        guard let trash = trashNode else { return }
        trash.fillColor = .darkGray.withAlphaComponent(0.4)
    }

    private func removeGateNode(_ gateNode: GateNode) {
        // Prevent deleting core input / output placeholders (not GateNodes anyway)
        // Clean connections referencing this gate
        connections.removeAll { conn in
            let shouldRemove = conn.fromAnchor?.parent === gateNode || conn.toAnchor?.parent === gateNode || conn.fromAnchor === gateNode.outputAnchor || conn.toAnchor === gateNode.inputAnchorA || conn.toAnchor === gateNode.inputAnchorB
            if shouldRemove { conn.shape.removeFromParent() }
            return shouldRemove
        }
        // Null inputs in other gates pointing to this gate
        for g in gates.map({ $0.gate }) {
            if g.inputA === gateNode.gate { g.inputA = nil }
            if g.inputB === gateNode.gate { g.inputB = nil }
        }
        if outputSource === gateNode.gate { outputSource = nil }
        // Remove from array & scene
        if let idx = gates.firstIndex(where: { $0 === gateNode }) { gates.remove(at: idx) }
        gateNode.removeFromParent()
        evaluateGraph()
    }

    // MARK: - Connections handling
    private func createConnection(from: SKNode, to: SKNode) {
        let wire = SKShapeNode()
        wire.strokeColor = .gray
        wire.lineWidth = 2
        wire.zPosition = 2
        addChild(wire)
        let conn = WireConnection(fromAnchor: from, toAnchor: to, shape: wire)
        connections.append(conn)
        updateConnection(conn)
    }

    private func updateConnections() { connections.forEach { updateConnection($0) } }

    private func updateConnection(_ conn: WireConnection) {
        guard let from = conn.fromAnchor, let to = conn.toAnchor else { return }
        let path = CGMutablePath()
        let start = convert(CGPoint.zero, from: from)
        let end = convert(CGPoint.zero, from: to)
        path.move(to: start)
        // Slight curve for aesthetics
        let midX = (start.x + end.x)/2
        path.addCurve(to: end,
                      control1: CGPoint(x: midX, y: start.y),
                      control2: CGPoint(x: midX, y: end.y))
        conn.shape.path = path
    }

    private func removeConnections(endingAt target: SKNode) {
        connections.removeAll { conn in
            if conn.toAnchor === target {
                conn.shape.removeFromParent(); return true
            }
            return false
        }
    }

    #if os(iOS) || os(tvOS)
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { if let t = touches.first { updateDrag(to: t.location(in: self)) } }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { if let t = touches.first { endDrag(at: t.location(in: self)) } }
    #else
    override func mouseDragged(with event: NSEvent) { updateDrag(to: event.location(in: self)) }
    override func mouseUp(with event: NSEvent) { endDrag(at: event.location(in: self)) }
    #endif

    override func update(_ currentTime: TimeInterval) {
        // Re-evaluate each frame for now (could optimize with dirty flag)
        evaluateGraph()
    }
    
    private func presentStartMenu() {
        // Return to StartScene directly (improved UX)
        guard let skView = self.view else {
            print("GameScene: ERROR view is nil, cannot present StartScene")
            return
        }
        let present = {
            let start = StartScene(size: skView.bounds.size, numberOfLevels: 5)
            start.scaleMode = .resizeFill
            let transition = SKTransition.fade(withDuration: 0.25)
            skView.presentScene(start, transition: transition)
        }
        if Thread.isMainThread { present() } else { DispatchQueue.main.async { present() } }
    }
}

