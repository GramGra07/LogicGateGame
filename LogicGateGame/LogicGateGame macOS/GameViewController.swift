//
//  GameViewController.swift
//  LogicGateGame macOS
//
//  Created by Graden on 10/7/25.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = self.view as? SKView else { return }
        let scene = StartScene(size: skView.bounds.size, numberOfLevels: 5)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

}

