import SpriteKit
import CoreGraphics

final class StartScene: SKScene {
    private var titleLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var levelButtons: [SKLabelNode] = []

    // Configure with a number of levels (default 5)
    private let numberOfLevels: Int

    init(size: CGSize, numberOfLevels: Int = 5) {
        self.numberOfLevels = numberOfLevels
        super.init(size: size)
        scaleMode = .aspectFill
        backgroundColor = .black
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        print("StartScene.didMove(to:) size=\(size)")
        buildUI()
    }

    private func buildUI() {
        removeAllChildren()

        titleLabel = SKLabelNode(fontNamed: "Menlo")
        titleLabel.text = "Logic Gate Puzzle"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 80)
        addChild(titleLabel)

        subtitleLabel = SKLabelNode(fontNamed: "Menlo")
        subtitleLabel.text = "Select a Level"
        subtitleLabel.fontSize = 18
        subtitleLabel.fontColor = .lightGray
        subtitleLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 120)
        addChild(subtitleLabel)
        // Build vertical list of level buttons (centered)
        levelButtons.removeAll()
        let spacing: CGFloat = 40
        let totalHeight = CGFloat(numberOfLevels - 1) * spacing
        let startY = frame.midY + totalHeight / 2
        for i in 1...numberOfLevels {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = "Level \(i)"
            label.fontSize = 20
            label.fontColor = .systemYellow
            label.position = CGPoint(x: frame.midX, y: startY - CGFloat(i - 1) * spacing)
            label.name = "level_button_\(i)"
            label.zPosition = 10
            addChild(label)
            levelButtons.append(label)
        }

        // Add a small hint
        let hint = SKLabelNode(fontNamed: "Menlo")
        hint.text = "Tap Play to start"
        hint.fontSize = 14
        hint.fontColor = .gray
        hint.position = CGPoint(x: frame.midX, y: frame.minY + 50)
        addChild(hint)
        hint.zPosition = 5

        // Play button with enlarged invisible hitbox
        let playLabel = SKLabelNode(fontNamed: "Menlo")
        playLabel.text = "Play"
        playLabel.fontSize = 22
        playLabel.fontColor = .systemGreen
        playLabel.verticalAlignmentMode = .center
        playLabel.horizontalAlignmentMode = .center

        // Force layout to compute frame for accurate size
        playLabel.setScale(1.0)
        let paddingX: CGFloat = 30
        let paddingY: CGFloat = 16
        let textSize = CGSize(width: playLabel.frame.width, height: playLabel.frame.height)
        let hitSize = CGSize(width: textSize.width + paddingX * 2, height: textSize.height + paddingY * 2)
        let hitRect = CGRect(origin: CGPoint(x: -hitSize.width/2, y: -hitSize.height/2), size: hitSize)
        let playHitbox = SKShapeNode(rect: hitRect, cornerRadius: 10)
        playHitbox.fillColor = .clear
        playHitbox.strokeColor = .clear
        playHitbox.lineWidth = 0

        let playPosition = CGPoint(x: frame.midX, y: frame.minY + 90)
        playHitbox.position = playPosition
        playLabel.position = .zero

        playHitbox.name = "play_button"
        playLabel.name = "play_button"

        playHitbox.zPosition = 20
        playLabel.zPosition = 21

        playHitbox.addChild(playLabel)
        addChild(playHitbox)
    }

    // MARK: - Interaction
    #if os(iOS) || os(tvOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let t = touches.first { print("StartScene.touchesBegan at \(t.location(in: self))") }
        guard let t = touches.first else { return }
        handle(point: t.location(in: self))
    }
    #else
    override func mouseDown(with event: NSEvent) {
        handle(point: event.location(in: self))
    }
    #endif

    private func handle(point: CGPoint) {
        let tappedNodes = nodes(at: point)
        for n in tappedNodes {
            if let name = n.name {
                if name == "play_button" {
                    print("StartScene: Play tapped -> Level 1")
                    presentLevel(1)
                    return
                }
                if name.hasPrefix("level_button_") {
                    if let idx = Int(name.replacingOccurrences(of: "level_button_", with: "")) {
                        print("StartScene: Level button tapped -> Level \(idx)")
                        animatePress(node: n) { self.presentLevel(idx) }
                        return
                    }
                }
            }
        }
        print("StartScene tap (no actionable node) at: \(point)")
    }

    private func animatePress(node: SKNode, completion: @escaping () -> Void) {
        let seq = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12),
            SKAction.run(completion)
        ])
        node.run(seq)
    }

    private func presentLevel(_ level: Int) {
        // Resolve SKView robustly and present GameScene decisively
        let resolveSKView: () -> SKView? = {
            if let v = self.view { return v }
            // Fallback: walk the responder chain to find an SKView
            var responder: UIResponder? = self
            while let r = responder {
                if let skv = r as? SKView { return skv }
                responder = r.next
            }
            return nil
        }

        let doPresent = {
            guard let skView = resolveSKView() else {
                assertionFailure("StartScene: SKView not found; cannot present GameScene")
                print("StartScene: ERROR could not resolve SKView; aborting presentation")
                return
            }

            let targetSize = skView.bounds.size
            let game = GameScene(size: targetSize)
            game.levelIndex = level
            game.scaleMode = .resizeFill

            let transition = SKTransition.crossFade(withDuration: 0.3)

            let wasPaused = skView.isPaused
            if wasPaused { skView.isPaused = false }

            print("StartScene: presenting GameScene size=\(targetSize) on main=\(Thread.isMainThread)")
            skView.presentScene(game, transition: transition)

            // Confirm after a tick
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let current = skView.scene as? GameScene {
                    print("StartScene: Presentation confirmed. scene=GameScene level=\(current.levelIndex)")
                } else {
                    print("StartScene: WARNING expected GameScene but got \(String(describing: skView.scene))")
                }
            }
        }

        // Defer to next runloop on main to avoid reentrancy with touch handling
        if Thread.isMainThread {
            DispatchQueue.main.async { doPresent() }
        } else {
            DispatchQueue.main.async { doPresent() }
        }
    }
}
