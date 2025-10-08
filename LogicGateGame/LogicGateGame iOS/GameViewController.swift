//
//  GameViewController.swift
//  LogicGateGame iOS
//
//  Created by Graden on 10/7/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        print("GameViewController.viewDidLoad")
        super.viewDidLoad()
        
        guard let skView = self.view as? SKView else {
            assertionFailure("View is not an SKView")
            return
        }

        // Present StartScene only once at launch
        let scene = StartScene(size: skView.bounds.size, numberOfLevels: 5)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("GameViewController.viewDidAppear")
        // Do not present or re-present any scenes here
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscape
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

