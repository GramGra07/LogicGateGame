import SpriteKit
import CoreGraphics

final class LevelScene: SKScene {
    let levelIndex: Int

    init(size: CGSize, levelIndex: Int) {
        self.levelIndex = levelIndex
        super.init(size: size)
        scaleMode = .aspectFill
        backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        // Immediately present the actual gameplay scene for this level
        let game = GameScene(size: size)
        game.levelIndex = levelIndex
        game.scaleMode = scaleMode
        let t = SKTransition.fade(withDuration: 0.25)
        self.view?.presentScene(game, transition: t)
    }
}
